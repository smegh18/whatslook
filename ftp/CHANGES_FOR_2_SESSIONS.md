# Changes for 2 Concurrent Sessions

## Summary

- **UserController.php** – updated (see below).
- **AuthorizeUser.php** – **no change** (already accepts any token in `user_auth_tokens`).
- **GlobalFunction** – **you must change** `generateUserAuthToken` (see “Required: GlobalFunction” below).
- **user_auth_tokens** table – ensure it has `user_id`, `auth_token`, and `id` (for ordering). `created_at` is optional.

---

## 1. UserController.php – DONE (in your ftp folder)

### logOutUser (changed)

- **Before:** Fetched the user, then deleted the **first** token for that user and set `user->device_token = null`. That logged out one device arbitrarily and affected the shared user record.
- **After:** Deletes **only** the token sent in the request (`auth_token` from header). No change to `user->device_token`, so the other session is unaffected.

### logInUser – existing user block (changed)

- **After** calling `GlobalFunction::generateUserAuthToken($user)`, added logic to keep at most **2** sessions per user:
  - Select all tokens for this `user_id` ordered by `id` **desc** (newest first).
  - Skip the newest 2 (keep them), delete the rest (up to 100) → this evicts the **oldest** session when a 3rd device logs in.

This only works if `generateUserAuthToken` **adds** a new token without deleting existing ones (see below).

---

## 2. AuthorizeUser.php – NO CHANGE

It already does:

```php
$token = UserAuthTokens::where('auth_token', $auth_token)->first();
if ($token != null) return $next($request);
```

So any token that exists in `user_auth_tokens` is accepted. With multiple rows per user, both sessions remain valid.

---

## 3. GlobalFunction.php – DONE (in your ftp folder)

**generateUserAuthToken($user)** has been updated:

- **Removed:** `UserAuthTokens::where('user_id', $user->id)->delete();` (that enforced single session).
- **Now:** Only creates and saves a **new** token row; existing tokens are left in place. UserController trims to max 2 sessions after login.

---

## 4. user_auth_tokens table

- Must have at least: **id**, **user_id**, **auth_token**.
- Optional but useful: **created_at**, **device_token** (for “same device” re-login later).

If the table does not exist or has different column names, create/alter it so that:

- One row = one session.
- Multiple rows per `user_id` are allowed (we cap at 2 in code).

Example structure:

```sql
-- If you need to add created_at (for “oldest” ordering):
ALTER TABLE user_auth_tokens ADD COLUMN created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP;
```

If you already order by `id` only (as in the current UserController trim logic), `created_at` is not required.

---

## 5. Files you have vs files you need

| File | Status |
|------|--------|
| ftp/api.php | No change needed (routes only). |
| ftp/UserController.php | **Updated** – upload this to replace the server file. |
| ftp/AuthorizeUser.php | No change needed. |
| ftp/UserAuthTokens.php | No change needed. |
| ftp/Users.php | No change needed. |
| ftp/CheckHeader.php, CheckLogin.php, Authenticate.php | No change needed. |
| **GlobalFunction.php** | **Updated** – upload this to replace the server file (generateUserAuthToken no longer deletes existing tokens). |

---

## 6. logInFakeUser (phone/email login)

If your server has a **logInFakeUser** method (used for phone/email registration), add the same trim-to-2-sessions logic after `generateUserAuthToken($user)`:

```php
// Keep max 2 sessions per user
$maxSessions = 2;
$toDelete = UserAuthTokens::where('user_id', $user->id)
    ->orderBy('id', 'desc')
    ->skip($maxSessions)
    ->take(100)
    ->get();
foreach ($toDelete as $t) {
    $t->delete();
}
```

---

## 7. Upload and test

1. Upload the modified **UserController.php** to the server (same path as before, e.g. `app/Http/Controllers/UserController.php`).
2. Edit **GlobalFunction** on the server (or edit locally and upload) so that `generateUserAuthToken` only inserts a new token and does not delete existing ones.
3. Test:
   - Log in on device 1 → then log in on device 2 → both should stay logged in.
   - Log in on device 3 → device 1 should get 401 on next request (session expired); devices 2 and 3 stay logged in.
   - Log out on device 2 → only device 2 is logged out; device 3 remains logged in.
