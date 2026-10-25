# Backend Files Needed for 2 Concurrent Sessions

## What `api.php` is

`ftp/api.php` is the **Laravel API routes file**. It only defines which URL calls which controller method. It does **not** contain login, logout, or token-checking logic. You do **not** need to change this file for 2 sessions.

---

## Where the session limit is actually enforced

From `api.php` we know:

| Route | Controller | Method | What it does |
|-------|------------|--------|---------------|
| `user/logInUser` | **UserController** | `logInUser` | Creates token on login — **edit here** |
| `user/logOutUser` | **UserController** | `logOutUser` | Clears token on logout — **edit here** |
| All other `user/*` and `post/*` etc. | (various) | — | Protected by **`authorizeUser`** middleware — **edit middleware** |

So the session limit is enforced in:

1. **UserController** → `logInUser` (store new token; allow 2 per user)
2. **UserController** → `logOutUser` (remove only this token)
3. **authorizeUser middleware** → validate that the request token is one of the user’s valid tokens (not a single token)

---

## Files you need to download from cPanel (Laravel paths)

On the server, the Laravel app is usually in the **document root** of `login.whatslook.com` (e.g. `public_html` or the subdomain folder). Inside it you’ll have an `app` folder. Download these files:

### 1. UserController (login + logout logic)

**Path on server:**  
`app/Http/Controllers/UserController.php`

- **logInUser:** where the new auth token is generated and saved. Today it likely overwrites the previous token (single session). Change to: add new session, keep max 2 per user, remove oldest if needed.
- **logOutUser:** change to delete only the token from the request, not all sessions for the user.

### 2. authorizeUser middleware (token validation)

**Path on server:**  
`app/Http/Middleware/AuthorizeUser.php`  
or  
`app/Http/Middleware/authorizeUser.php`  
(or similar name — Laravel often uses PascalCase for class names)

- This runs on every protected API request and checks the `AUTHTOKEN` header.
- Today it likely loads the user by a **single** token. Change to: accept the request if the token is **one of** the user’s 2 stored sessions.

If you can’t find it by name, search inside `app/Http/Middleware/` for the file that uses `AUTHTOKEN` or that returns 401 Unauthorized.

### 3. Where the token is stored (User model / DB)

The token might be stored:

- On the **users** table (e.g. `users.auth_token` or `users.token`) — one column per user = single session.
- Or in a separate **sessions** or **user_sessions** table.

**Paths to check:**

- `app/Models/User.php` — see if it has `token` / `auth_token` and how it’s set.
- `database/migrations/` — look for migrations that create `users` or `sessions` tables to see the schema.

For 2 sessions you typically need either:

- A **new table** (e.g. `user_sessions`: `user_id`, `auth_token`, `device_token`, `created_at`) and keep at most 2 rows per user, **or**
- Change the existing token storage to support multiple tokens per user (e.g. JSON column or a separate table). The UserController and middleware will read/write that.

### 4. Optional: checkHeader middleware

**Path on server:**  
`app/Http/Middleware/CheckHeader.php` (or similar)

- Referenced in `api.php` as `checkHeader`. Usually only checks API key or basic headers; token validation is usually in `authorizeUser`. You only need to edit this if it’s the place that validates the auth token (unlikely).

---

## Summary checklist

| # | File (relative to Laravel root) | Purpose |
|---|---------------------------------|--------|
| 1 | `app/Http/Controllers/UserController.php` | **Required.** Edit `logInUser` and `logOutUser`. |
| 2 | `app/Http/Middleware/AuthorizeUser.php` (or similar) | **Required.** Edit token validation to allow 2 sessions. |
| 3 | `app/Models/User.php` | **Required.** See how token is stored; may need a new model for sessions. |
| 4 | `database/migrations/` (users or sessions table) | **Required.** To add `user_sessions` table or change schema. |
| 5 | `routes/api.php` | No change needed (this is your current `ftp/api.php`). |

---

## Next steps

1. In cPanel File Manager, go to the folder that contains the Laravel app (where `app/`, `routes/`, `database/` live).
2. Download the files above (UserController, authorizeUser middleware, User model, and relevant migrations).
3. Share the contents of **UserController.php** (at least `logInUser` and `logOutUser`) and the **authorizeUser** middleware file — then we can give exact code changes for 2 sessions.
4. If you have a `user_sessions` (or similar) table already, share the migration or schema; otherwise we can add a new migration and wire it into login/logout/middleware.
