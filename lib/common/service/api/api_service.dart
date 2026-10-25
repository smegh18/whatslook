import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shortzz/common/functions/debounce_action.dart';
import 'package:shortzz/common/manager/logger.dart';
import 'package:shortzz/common/manager/session_manager.dart';
import 'package:shortzz/common/service/utils/params.dart';
import 'package:shortzz/screen/session_expired_screen/session_expired_screen.dart';
import 'package:shortzz/screen/auth_screen/login_screen.dart';
import 'package:shortzz/utilities/const_res.dart';

class CancelToken {
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }

  void dispose() {
    _isCancelled = false;
  }
}

class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();

  final Map<CancelToken, http.Client> _activeClients = {};

  final Map<String, String> _baseHeaders = {Params.apikey: apiKey};

  Future<T> call<T>({
    required String url,
    Map<String, dynamic>? param,
    CancelToken? cancelToken,
    bool cancelAuthToken = false,
    T Function(Map<String, dynamic> json)? fromJson,
    Function()? onError,
  }) async {
    final client = http.Client();
    if (cancelToken != null && cancelToken.isCancelled) {
      _activeClients[cancelToken] = client;
    }

    Map<String, String> params = {};
    param?.removeWhere(
        (key, value) => value == null || value == 'null' || value == '');
    param?.forEach((key, value) {
      params[key] = "$value";
    });

    final requestHeaders = Map<String, String>.from(_baseHeaders);
    if (!cancelAuthToken) {
      final token = SessionManager.instance.getAuthToken();
      if (token.isNotEmpty) {
        requestHeaders[Params.authToken] = token;
      }
    }
    if (kDebugMode) {
      Loggers.info("URL: $url");
      Loggers.info("header: $requestHeaders");
      Loggers.info("Parameters: ${params.isEmpty ? "Empty" : params}");
    }
    try {
      final response =
          await client.post(Uri.parse(url), headers: requestHeaders, body: params);
      if (kDebugMode) {
        Loggers.success(response.statusCode);
      }
      if (cancelToken?.isCancelled ?? false) {
        if (kDebugMode) {
          print("Request cancelled: $url");
        }
        throw Exception('Request was cancelled');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decodedResponse =
            jsonDecode(response.body) as Map<String, dynamic>;

        if (decodedResponse['message'] == 'this user is freezed!') {
          DebounceAction.shared.call(() {
            Get.offAll(
                () => const SessionExpiredScreen(type: SessionType.freeze));
          });
          return decodedResponse as T;
        }

        if (decodedResponse['status'] == false) {
          Loggers.error('API RESPONSE : ${decodedResponse['message']}');
          onError?.call();
        }

        if (kDebugMode) {
          final prettyString =
              const JsonEncoder.withIndent('  ').convert(decodedResponse);
          Loggers.info(prettyString);
        }

        // Use the provided `fromJson` function to parse the response
        if (fromJson != null) {
          return fromJson(decodedResponse);
        }

        // If no `fromJson` is provided, return the raw response
        return decodedResponse as T;
      } else if (response.statusCode == 401) {
        // Session limit is enforced by backend. To allow 2 concurrent sessions
        // per account, backend must store up to 2 valid tokens per user and
        // return 401 only when token is invalid/evicted. See docs/BACKEND_TWO_CONCURRENT_SESSIONS.md
        Loggers.error('Unauthorized Error 401: ${response.statusCode}');

        final hasActiveSession = SessionManager.instance.isLogin() &&
            SessionManager.instance.getAuthToken().isNotEmpty;

        DebounceAction.shared.call(() {
          if (hasActiveSession) {
            Get.offAll(() =>
                const SessionExpiredScreen(type: SessionType.unauthorized));
          } else {
            Get.offAll(() => const LoginScreen());
          }
        });
        throw Exception("Unauthorized Error: ${response.statusCode}");
      } else if (response.statusCode == 404) {
        Loggers.error('Please check baseURL in const.dart file');
        throw Exception("URL Error: ${response.statusCode} - $url");
      } else {
        final errorBody = response.body;
        Loggers.error('RAW HTTP ERROR BODY: $errorBody');
        final errorMessage = _extractErrorMessage(errorBody);
        Loggers.error('HTTP Error: $errorMessage');
        // Handle HTTP errors
        throw Exception(
            "HTTP Error: ${response.statusCode} - ${response.reasonPhrase}");
      }
    } on HttpException {
      throw Exception('Could not connect to the server');
    } on FormatException catch (e) {
      // Handle JSON decoding errors
      Loggers.error("Invalid JSON format: ${e.message}");
      throw Exception("Invalid JSON format: ${e.message}");
    } on Exception catch (e) {
      Loggers.error("Unexpected error : $e");
      rethrow;
    } finally {
      _cleanupClient(cancelToken);
    }
  }

  String _extractErrorMessage(String responseBody) {
    final regex = RegExp(
      r'<!--\s*(.*?)\s*#0 ', // Matches everything between <!-- and #0
      dotAll: true,
    );
    final match = regex.firstMatch(responseBody);
    return match?.group(1)?.trim() ??
        "Unknown error occurred: ${_shorten(responseBody)}";
  }

  /// Shortens the response body if no specific error is found
  String _shorten(String responseBody) {
    const maxLength = 100;
    return responseBody.length > maxLength
        ? "${responseBody.substring(0, maxLength)}..."
        : responseBody;
  }

  Future<T> callGet<T>({required String url}) async {
    http.Response response = await http.get(Uri.parse(url));
    return jsonDecode(response.body);
  }

  Future<T> multiPartCallApi<T>({
    required String url,
    Map<String, dynamic>? param,
    required Map<String, List<XFile?>> filesMap,
    Function(double percentage)? onProgress,
    CancelToken? cancelToken,
    T Function(Map<String, dynamic> json)? fromJson,
  }) async {
    final client = http.Client();
    if (cancelToken != null) {
      _activeClients[cancelToken] = client;
    }

    final request = MultipartRequest(
      'POST',
      Uri.parse(url),
      onProgress: (bytes, totalBytes) {
        if (onProgress != null) {
          onProgress(bytes / totalBytes);
        }
      },
    );

    Map<String, String> params = {};
    param?.removeWhere((key, value) => value == null || value == 'null');
    param?.forEach((key, value) {
      params[key] = "$value";
    });

    request.fields.addAll(params);

    // Add auth token to headers for authenticated requests
    final Map<String, String> requestHeaders = Map<String, String>.from(_baseHeaders);
    final token = SessionManager.instance.getAuthToken();
    if (token.isNotEmpty) {
      requestHeaders[Params.authToken] = token;
    }

    request.headers.addAll(requestHeaders);

    filesMap.forEach((keyName, files) {
      for (var xFile in files) {
        if (xFile != null && xFile.path.isNotEmpty) {
          final file = File(xFile.path);
          final multipartFile = http.MultipartFile(
              keyName, file.readAsBytes().asStream(), file.lengthSync(),
              filename: xFile.name);
          request.files.add(multipartFile);
        }
      }
    });
    if (kDebugMode) {
      Loggers.info("URL : $url");
      Loggers.info("HEADERS : ${request.headers}");
      Loggers.info("FIELDS : ${request.fields}");
      Loggers.info("FILES : ${request.files.map((e) => e)}");
    }

    try {
      final responseStream = await client.send(request);

      if (cancelToken?.isCancelled ?? false) {
        if (kDebugMode) {
          Loggers.error("Request cancelled: $url");
        }
        throw Exception('Request was cancelled');
      }

      if (responseStream.statusCode == 401) {
        final hasActiveSession = SessionManager.instance.isLogin() &&
            SessionManager.instance.getAuthToken().isNotEmpty;
        DebounceAction.shared.call(() {
          if (hasActiveSession) {
            Get.offAll(() =>
                const SessionExpiredScreen(type: SessionType.unauthorized));
          } else {
            Get.offAll(() => const LoginScreen());
          }
        });
        throw Exception("Unauthorized Error: ${responseStream.statusCode}");
      }

      final responseStr = await responseStream.stream.bytesToString();
      final decodedResponse = jsonDecode(responseStr) as Map<String, dynamic>;

      if (kDebugMode) {
        // Loggers.info(responseStr);
      }
      if (decodedResponse['status'] == false) {
        Loggers.error(decodedResponse['message']);
      }
      // Use the provided `fromJson` function to parse the response
      if (fromJson != null) {
        return fromJson(decodedResponse);
      }

      // If no `fromJson` is provided, return the raw response
      return decodedResponse as T;
    } finally {
      _cleanupClient(cancelToken);
    }
  }

  void _cleanupClient(CancelToken? cancelToken) {
    if (cancelToken != null) {
      _activeClients[cancelToken]?.close();
      _activeClients.remove(cancelToken);
    }
  }

  Future<void> useAndDeleteFile(File file) async {
    try {
      // Use the file as needed
      Loggers.warning('File path: ${file.path}');

      // Delete the file after use
      if (await file.exists()) {
        await file.delete();
        Loggers.success('File deleted from: ${file.path}');
      }
    } catch (e) {
      Loggers.error('Error: $e');
    }
  }
}

class MultipartRequest extends http.MultipartRequest {
  MultipartRequest(
    super.method,
    super.url, {
    this.onProgress,
  });

  final void Function(int bytes, int totalBytes)? onProgress;

  @override
  http.ByteStream finalize() {
    final byteStream = super.finalize();
    final total = contentLength;
    int bytes = 0;

    final transformer = StreamTransformer<List<int>, List<int>>.fromHandlers(
      handleData: (data, sink) {
        bytes += data.length;
        if (onProgress != null) {
          onProgress!(bytes, total);
        }
        sink.add(data);
      },
    );

    return http.ByteStream(byteStream.transform(transformer));
  }
}
