<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Session;

class CheckLogin
{
    public function handle(Request $request, Closure $next)
    {
        if (Session::has('username')) {
            $response = $next($request);

            // Prevent caching
            $response->headers->set('Cache-Control', 'nocache, no-store, max-age=0, must-revalidate');
            $response->headers->set('Pragma', 'no-cache');
            $response->headers->set('Expires', 'Sun, 02 Jan 2021 00:00:00 GMT');

            return $response;
        }

        // Redirect to login if not logged in
        return redirect()->route('login');
    }
}
