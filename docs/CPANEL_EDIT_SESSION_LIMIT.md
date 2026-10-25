# Editing Backend in cPanel File Manager — 2 Sessions per User

You’re logged into **cPanel → File Manager**. The backend that serves `https://login.whatslook.com/api/` is usually under the **document root** for that domain. Use this to find and edit the right files.

---

## 1. Where the backend files usually are

In File Manager, open the folder for **login.whatslook.com** (or the main account folder).

Common locations:

| Scenario | Path to check |
|----------|----------------|
| Subdomain `login.whatslook.com` | `public_html/login/` or `login.whatslook.com/` or `domains/login.whatslook.com/public_html/` |
| Same server as main site | `public_html/api/` or `public_html/login/` |
| Addon/subdomain | In **cPanel → Domains → Subdomains** see “Document Root”, then open that folder in File Manager |

You need the folder that contains the **API code** (where `user/logInUser`, `user/logOutUser`, and token checks live). It often has:

- `api/` or `app/` or `src/`
- Files like `index.php`, `user.php`, `UserController.php`, `auth.php`, or a framework structure (e.g. `app/Http/Controllers/` for Laravel).

---

## 2. Files to search for (what to edit)

The **session limit** is enforced where the backend:

1. **Stores the auth token** when the user logs in
2. **Checks the token** on each API request
3. **Removes the token** on logout

So you need to find those places. Use **File Manager → Search** (or open files and use Ctrl+F) for:

### A) Login / token creation

Search for:

- **Text:** `logInUser`, `loginInUser`, `log_in`, `device_token`, `deviceToken`, `auth_token`, `AUTHTOKEN`
- **Filenames:** `user.php`, `User.php`, `login.php`, `auth.php`, `UserController.php`, `AuthController.php`

The **login** script is where a new token is saved. Right now it likely **overwrites** the previous token (one per user). You will change it to **keep a list of up to 2 tokens** per user and remove the oldest when adding a new one.

### B) Where the token is validated (middleware / every request)

Search for:

- **Text:** `AUTHTOKEN`, `authToken`, `auth_token`, `401`, `Unauthorized`, `getAuthToken`, `verifyToken`, `validateToken`
- **Filenames:** `api.php`, `middleware`, `Auth.php`, `auth.php`, `index.php` (main API entry)

The **validation** script currently checks “is this the user’s token?”. You will change it to “is this token **one of** this user’s 2 stored tokens?”.

### C) Logout

Search for:

- **Text:** `logOutUser`, `log_out`, `logout`, `logOut`
- **Filenames:** same as login, often `user.php` or `UserController.php`

**Logout** should remove **only the token sent in that request**, not all sessions for the user.

---

## 3. What to change (logic in plain language)

### Database / storage

- **Now:** One row or one value per user for the auth token (e.g. `users.token` or `sessions.token`).
- **Goal:** Store **multiple sessions** per user (e.g. a `user_sessions` table or a list in a column).

Example **table** idea:

- `user_sessions`: `id`, `user_id`, `auth_token`, `device_token`, `created_at`

Rule: keep at most **2** rows per `user_id` (delete oldest when adding a 3rd).

### On login (e.g. `logInUser`)

1. Authenticate user (email/Google/Apple/etc.) — same as now.
2. Generate a **new** auth token — same as now.
3. **New logic:**
   - Insert new row: `user_id`, new `auth_token`, `device_token` from request, `created_at` = now.
   - Count sessions for this `user_id`. If count **> 2**, delete the **oldest** row (smallest `created_at`).
4. Return the new token in the response — same as now.

### On every API request (auth check)

- **Now:** Load user by token; if not found or token doesn’t match the single stored token → 401.
- **Goal:** Load user by token from `user_sessions`; if this token is **in** that user’s sessions (one of the up-to-2 rows) → allow; else → 401.

### On logout (`logOutUser`)

- **Now:** Often clears the user’s token (so all devices are logged out).
- **Goal:** Find the row where `auth_token` = token from the request and **delete only that row**. Do not touch the other session(s).

---

## 4. If you use a **database** (MySQL in cPanel)

- **phpMyAdmin** is in cPanel. Open it and find the database used by the API (check config files for DB name).
- You may need to **add a new table** for sessions, for example:

```sql
CREATE TABLE user_sessions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  auth_token VARCHAR(255) NOT NULL,
  device_token VARCHAR(255),
  created_at DATETIME NOT NULL,
  INDEX (user_id),
  INDEX (auth_token)
);
```

Then in PHP you:

- **Login:** `INSERT` into `user_sessions`, then `DELETE` oldest rows for that `user_id` until only 2 remain.
- **Auth check:** `SELECT user_id FROM user_sessions WHERE auth_token = ?` (and optionally check `user_id`).
- **Logout:** `DELETE FROM user_sessions WHERE auth_token = ?`.

(Exact column names and token format should match your current code.)

---

## 5. Quick checklist in File Manager

1. Open the **document root** for `login.whatslook.com` (or the folder that contains the API).
2. **Search** for `logInUser` or `loginInUser` → open that file (and any file that handles login).
3. **Search** for `AUTHTOKEN` or `auth_token` (where the request is validated) → open that file.
4. **Search** for `logOutUser` or `logout` → open that file.
5. Check if tokens are stored in **database** (then use phpMyAdmin + the table above) or in **files** (then you’ll need to change how you read/write those files to keep 2 per user).
6. Apply the **login / auth / logout** logic described in section 3.

---

## 6. If you’re not a developer

- **Backup:** In File Manager, select the folder that contains the API (e.g. `public_html` or the login subdomain folder) → **Compress** → download the `.zip`. Keep it safe.
- **Don’t edit** until you know which file does what. You can open files in **Edit** and use **Search** to find `logInUser`, `AUTHTOKEN`, `logOutUser` and send the **file paths + a few lines of code** to a developer so they can tell you exactly what to change.
- Alternatively, send them this doc and ask them to implement “2 concurrent sessions” as described; they can do it via cPanel File Manager + phpMyAdmin or via SSH if they have access.

---

## 7. After you edit

- Save the files in File Manager.
- Test: log in on **device 1**, then log in on **device 2**. Both should stay logged in. Then log in on **device 3** → device 1 should get “Session expired” on next request, devices 2 and 3 should stay logged in.
- If something breaks, restore from the backup zip and try again (or get a dev to help).
