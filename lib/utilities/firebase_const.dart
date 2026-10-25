class FirebaseConst {
  FirebaseConst._();

  // Collections
  static const String appUsers = 'app_users';
  static const String users = 'users';
  static const String usersList = 'users_list';
  static const String chats = 'chats';
  static const String messages = 'messages';
  static const String liveStreams = 'live_streams';
  static const String userState = 'user_state';
  static const String comments = 'comments';

  // Common chat fields
  static const String id = 'id';
  static const String isDeleted = 'is_deleted';
  static const String requestType = 'request_type';
  static const String chatType = 'chat_type';
  static const String deletedId = 'deleted_id';
  static const String lastMsg = 'last_msg';
  static const String msgCount = 'msg_count';
  static const String noDeleteIds = 'no_delete_ids';
  static const String storyReplyMessage = 'story_reply_message';
  static const String iBlocked = 'i_blocked';
  static const String iAmBlocked = 'i_am_blocked';

  // Live stream fields
  static const String type = 'type';
  static const String battleType = 'battle_type';
  static const String battleCreatedAt = 'battle_created_at';
  static const String battleDuration = 'battle_duration';
  static const String watchingCount = 'watching_count';
  static const String likeCount = 'like_count';
  static const String coHostIds = 'co-host_ids';
  static const String audioStatus = 'audio_status';
  static const String videoStatus = 'video_status';
  static const String currentBattleCoin = 'current_battle_coin';
  static const String totalBattleCoin = 'total_battle_coin';
  static const String liveCoin = 'live_coin';
  static const String followersGained = 'followers_gained';
  static const String joinStreamTime = 'join_stream_time';

  // Extra keys used in several read/write paths
  static const String userId = 'user_id';
  static const String conversationId = 'conversation_id';
  static const String createdAt = 'created_at';
  static const String hostId = 'host_id';
  static const String roomId = 'room_id';
}
