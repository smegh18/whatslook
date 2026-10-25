# Deploy & Verify 2-Session Fix (Still Seeing "Session Expired"?)

If you still see **"Session Expired – Logged in on Another Device"** after editing the files, the server is almost certainly still running the **old** code. Follow these steps.

---

## 1. Confirm you uploaded BOTH files to the correct paths

On the server (cPanel File Manager), the Laravel app root is usually where you see folders like `app`, `config`, `routes`, `public`.

| Local file (in your ftp folder) | Upload to this path on the server |
|---------------------------------|-----------------------------------|
| **UserController.php** | `app/Http/Controllers/UserController.php` |
| **GlobalFunction.php** | `app/Models/GlobalFunction.php` |

- Overwrite the existing files (replace, don’t create a second copy).
- Do **not** put them inside `public` or `public_html` only; they must be under `app/` as above.

---

## 2. Clear PHP cache (opcache) so the new code runs

Many hosts use **PHP opcache**. Until it’s cleared, the server can keep running the old code even after you upload.

**Option A – cPanel**
- Find **Select PHP Version**, **MultiPHP INI Editor**, or **PHP Options**.
- Look for an option to **clear opcache** or **restart PHP**, and use it.

**Option B – Create a small PHP file (temporary)**
- In the **Laravel project root** (same level as `app/`, `routes/`), create a file: `clear_cache.php`.
- Put only this inside:
  ```php
  <?php
  if (function_exists('opcache_reset')) {
      opcache_reset();
      echo 'OPcache cleared.';
  } else {
      echo 'OPcache not enabled.';
  }
  ```
- In the browser open: `https://login.whatslook.com/clear_cache.php` (or your real domain + `/clear_cache.php`).
- After you see the message, **delete** `clear_cache.php` for security.

**Option C – Restart PHP / web server**
- If you have SSH or a “Restart” option for PHP-FPM or the web server, use that.

---

## 3. Verify the LIVE server code (not just your local copy)

You need to confirm the **server’s** files were updated.

**GlobalFunction.php**
- On the server, open: `app/Models/GlobalFunction.php`.
- Search for: **generateUserAuthToken**.
- The method must **not** contain this line:
  ```php
  UserAuthTokens::where('user_id', $user->id)->delete();
  ```
- It should only create and save a new token (with the comment about “Do NOT delete existing tokens”).

**UserController.php**
- On the server, open: `app/Http/Controllers/UserController.php`.
- Search for: **logOutUser**.
- It must look like this (delete only the token from the request):
  ```php
  $authToken = UserAuthTokens::where('auth_token', $token)->first();
  if ($authToken) {
      $authToken->delete();
  }
  ```
- And in **logInUser** (existing-user block), after `generateUserAuthToken($user)` there must be the “trim to 2 sessions” block (maxSessions = 2, skip/take, delete).

If any of this is missing or different on the server, upload the correct file again and clear opcache once more.

---

## 4. Test again

1. **Fully close** the app on both devices (force stop / swipe away).
2. On **device 1**: open app and log in.
3. On **device 2**: open app and log in with the **same account**.
4. Use the app on **device 1** (e.g. refresh feed or open profile).
   - If you still see “Session Expired”, the server is still using old logic or the wrong file path.
5. If it works, try logging in on a **third** device; the first device should then get “Session Expired” on next use (correct behaviour).

---

## 5. If it still fails

- Confirm the API base URL in the app is really the server you’re editing (e.g. `https://login.whatslook.com/api/`).
- If you have multiple servers or a load balancer, update and clear cache on **all** of them.
- In cPanel, check **Error Logs** or **PHP error log** for the moment you hit the app; see if there are 500 or other errors when logging in or calling an API.
