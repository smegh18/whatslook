<?php

namespace App\Http\Middleware;

use App\Models\UserAuthTokens;
use App\Models\Users;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class AuthorizeUser
{
    /**
     * Handle an incoming request.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \Closure(\Illuminate\Http\Request): (\Illuminate\Http\Response|\Illuminate\Http\RedirectResponse)  $next
     * @return \Illuminate\Http\Response|\Illuminate\Http\RedirectResponse
     */
    public function handle(Request $request, Closure $next)
    {
        // Accept token from header (PHP: HTTP_AUTHTOKEN, or Laravel normalized)
        $auth_token = $request->header('AUTHTOKEN') ?? $request->header('authtoken') ?? $_SERVER['HTTP_AUTHTOKEN'] ?? null;

        if (!empty($auth_token)) {
            $token = UserAuthTokens::where('auth_token', $auth_token)->first();

            if ($token != null) {
                return $next($request);
            } else {
                $data['status']    = false;
                $data['meassage'] = "Unauthorized Access";
                $data['reason'] = "Invalid Token!";
                return new JsonResponse($data, 401);
            }
        } else {
            $data['status']    = false;
            $data['meassage'] = "Unauthorized Access";
            $data['reason'] = "Token Not Provided";
            return new JsonResponse($data, 401);
        }
    }
}
