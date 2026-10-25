# Backend: Allow 2 Concurrent Sessions per Account

## Current behavior (single session)

- When a user logs in, the backend appears to keep **one** valid auth token per user.
- Logging in on a **new device** invalidates the previous token, so the **old device** gets **401 Unauthorized** on its next API call.
- The app then shows: *"Session Expired – Logged in on Another Device"* and the user is effectively logged out on the first device.

So the **session limit is enforced entirely on the backend** (e.g. at `login.whatslook.com`). The app only reacts to 401 by clearing local session and showing the session-expired screen.

## Desired behavior (2 concurrent sessions)

- Allow **up to 2 active sessions** per user (e.g. phone + tablet, or two phones).
- When the user logs in on a **3rd device**, invalidate the **oldest** of the existing sessions (FIFO), not both.
- **Logout** from one device should invalidate only that device’s token, not the other.

No change is required in the Flutter app for this; once the backend accepts 2 tokens per user and returns 401 only when the token is not in that set (or when the user has 3+ sessions and this token is the one evicted), both devices will work.

---

## Backend implementation outline

### 1. Session storage per user

- **Current (assumed):** One token per user (e.g. `user_id → token` or `user_id → single session`).
- **Target:** Store **up to 2 sessions** per user, e.g.:
  - `user_id → [ { auth_token, device_token, created_at } ]` (or similar)
  - Keep the list ordered (e.g. by `created_at`) and cap its length at **2**.

### 2. Login (`logInUser` / `logInFakeUser`)

- Request already sends: `identity`, `device_token`, `device` (0 Android / 1 iOS), `login_method`.
- On successful auth:
  - Create a new session (new auth token, current `device_token`, current timestamp).
  - Append this session to the user’s session list.
  - If the user **already has 2 sessions**:
    - Remove the **oldest** session (by `created_at`).
    - Optionally: if the same `device_token` already exists (same device re-login), replace that session instead of adding a third.
  - Return the **new** auth token in the login response (as today).

### 3. Authenticating API requests

- For each request, read the auth token from the header (e.g. `AUTHTOKEN`).
- Resolve `user_id` from that token (same as today).
- Consider the token **valid** if it is **one of** the 2 stored tokens for that `user_id`.
- If the token is **not** in the list (e.g. it was evicted when a 3rd device logged in, or user logged out from this device):
  - Return **401 Unauthorized** so the app shows the session-expired screen and clears local session.

### 4. Logout (`logOutUser`)

- Request carries the auth token in the header (as today).
- Find the session that matches this auth token and **remove only that session** from the user’s list.
- Do **not** invalidate the other device’s session.

### 5. Optional: same-device re-login

- If the incoming login has a `device_token` that **already** has a session in the user’s list, you can **replace** that session with the new one (so the same device only ever has one session, but the other device’s session remains).

---

## App-side (no change required for 2 sessions)

- The app already:
  - Sends `device_token` and `device` on login.
  - Sends `AUTHTOKEN` on every request.
  - Calls `logOutUser` (with auth token in header) when the user taps Log out.
- On **401**, the app clears local session and shows the session-expired screen; no code change needed for 2-session support.
- Optional: you can change the **copy** of the session-expired message (e.g. to say “two active sessions” or keep it generic like “Your session has expired. Please log in again.”) in `languages_keys.dart` and any translations.

---

## Summary

| Item | Action |
|------|--------|
| **Where** | Backend (e.g. `login.whatslook.com`): user login, token storage, auth middleware, logout. |
| **Change** | Store up to **2** sessions per user; on login with 2 existing sessions, evict the oldest; on logout, remove only the current token. |
| **App** | No backend-facing change required; optional copy update for session-expired message. |
