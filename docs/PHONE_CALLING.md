# Phone calling feature — documentation

This document describes how in-app calling works in **doctor_app**, which dependencies are involved, platform configuration, and each public/helper function.

---

## 1. High-level flow

1. User taps **Call** (e.g. on **Patient details** or **Appointments**).
2. UI calls **`launchCallWithLoader(context, phoneNumber)`** (`lib/common/utils/phone_launcher.dart`).
3. A **modal loader** is shown (“Connecting call…”) until the call/dialer step finishes.
4. **`launchPhoneCall(phoneNumber)`** runs the actual Android/iOS logic.
5. Loader is dismissed; on failure, a **SnackBar** explains the error (often permission-related).

**Call sites (current code):**

- `lib/feature/doctorPages/view/patient_details_view.dart` — bottom **Call** button.
- `lib/feature/doctorPages/view/appointments_view.dart` — call icon on appointment cards.

Phone numbers are currently **hardcoded constants** in those files (e.g. `_hardcodedPhoneNumber`); replace with patient/contact data when the backend is ready.

---

## 2. Dependencies (pubspec) and why they exist

| Package | Role in calling |
|--------|------------------|
| **`flutter_phone_direct_caller`** | On **Android**, attempts to place an outgoing call via `FlutterPhoneDirectCaller.callNumber`. Requires runtime permission + `CALL_PHONE` in manifest. |
| **`permission_handler`** | Requests **`Permission.phone`** on Android before placing a call (maps to the phone/call permission group including `CALL_PHONE` on many devices). |
| **`android_intent_plus`** | Fallback: launches **`Intent.ACTION_DIAL`** with `tel:` if native channel / plugin paths fail. |
| **`url_launcher`** | Fallback on Android; **primary on iOS** — opens the system handler for `tel:` URIs (`LaunchMode.externalApplication`). |
| **`flutter/services.dart`** (`MethodChannel`) | Talks to **custom Kotlin code** in `MainActivity` for `placeCall` / `openDialer` without relying on some third-party plugin channels. |

**Not calling-specific but used by the same file:** `flutter/material.dart` (dialog, `Navigator`, `SnackBar`).

**Flutter SDK:** `foundation` (`kIsWeb`, `TargetPlatform`), `widgets` (`WidgetsBinding` for frame sync after showing the loader).

---

## 3. Native Android (`MainActivity.kt`)

**Method channel name:** `com.example.doctor_app/phone`  
Must match **`_kAndroidPhoneChannel`** in `phone_launcher.dart`.

| Method | Arguments | Behavior |
|--------|-----------|----------|
| **`openDialer`** | `number` (String) | Strips spaces, starts **`Intent.ACTION_DIAL`** with `tel:<number>`. Opens dialer UI with number prefilled (user still taps call). |
| **`placeCall`** | `number` (String) | Strips spaces, starts **`Intent.ACTION_CALL`** with `tel:<number>`. Places an outgoing call; requires **`CALL_PHONE`** granted at runtime (requested from Dart). Can throw `SecurityException` if permission missing. |

Errors are returned to Dart as `PlatformException` with codes like `ARG`, `NO_DIALER`, `PERM`, `NO_APP`, `CALL`, `DIAL`.

---

## 4. Android manifest

- **`android.permission.CALL_PHONE`** — required for `ACTION_CALL` and for `flutter_phone_direct_caller` direct dial.
- **`<queries>`** (Android 11+ package visibility) — declares intents so the system can resolve dialer / Phone apps for `tel:` / `DIAL` / `VIEW` / `CALL`.

---

## 5. iOS

- No native MethodChannel for calls in this project.
- **`url_launcher`** opens `tel:`; **`Info.plist`** includes **`LSApplicationQueriesSchemes`** → `tel` so `canLaunchUrl` / `launchUrl` work for phone URLs.
- iOS does not allow fully automatic outgoing calls like Android; the user confirms in the Phone app.

---

## 6. Functions in `phone_launcher.dart`

### `normalizePhoneDigits(String phoneNumber) → String`

- Removes all whitespace from the string.
- Used so `tel:` URIs and intents get a consistent number (e.g. `+91 7900464524` → `+91790464524`).

### `_openAndroidDialerIntentPlus(String tel) → Future<void>` (private)

- Uses **`android_intent_plus`** to fire **`ACTION_DIAL`** with `tel:$tel`.
- Internal fallback only.

### `launchPhoneCall(String phoneNumber) → Future<bool>`

**Returns `true` if any step succeeds, `false` if everything fails.**

**Android:**

1. Normalize number; empty → `false`. Web → `false`.
2. **`Permission.phone.request()`** — if not granted → `false` (no call without permission in this flow).
3. **`FlutterPhoneDirectCaller.callNumber(tel)`** — if returns `true` → success.
4. **`MethodChannel.invokeMethod('placeCall', {'number': tel})`** — native `ACTION_CALL`.
5. **`MethodChannel.invokeMethod('openDialer', {'number': tel})`** — native `ACTION_DIAL`.
6. **`android_intent_plus`** `ACTION_DIAL`.
7. **`url_launcher`** `launchUrl(tel:..., externalApplication)`.

**iOS / other non-Android:**

- Single attempt: **`url_launcher`** with `tel:` and `LaunchMode.externalApplication`.

### `launchCallWithLoader(BuildContext context, String phoneNumber) → Future<void>`

**Public API for UI.** Does not return success to the caller; shows SnackBar on failure.

1. **`context.mounted`** check.
2. **`showDialog`** with root navigator, non-dismissible, `PopScope(canPop: false)` — blocks back.
3. **Frame delays** (`Duration.zero`, `endOfFrame`, 16 ms, `endOfFrame`) so the loader **paints every tap** (avoids invisible flash on fast paths).
4. **`Stopwatch`** + **`launchPhoneCall`**.
5. **`finally`:** minimum visible time **`_kMinLoaderVisible` (450 ms)** so the spinner is never a zero-length flash.
6. **`Navigator.pop`** if `canPop`.
7. If `!ok`, show **SnackBar** about allowing Phone permission.

### `launchPhoneDialer(String phoneNumber) → Future<bool>`

- **Deprecated** alias for **`launchPhoneCall`** — kept for backward compatibility.

---

## 7. Constants

| Name | Value | Purpose |
|------|--------|---------|
| `_kAndroidPhoneChannel` | `'com.example.doctor_app/phone'` | Kotlin method channel name. |
| `_kMinLoaderVisible` | `450 ms` | Minimum loader duration after `launchPhoneCall` returns. |

---

## 8. Troubleshooting

| Symptom | Likely cause |
|--------|----------------|
| SnackBar: allow Phone permission | User denied **`Permission.phone`** / **`CALL_PHONE`**. Open Settings → App → Permissions → Phone. |
| Works on first install only | Run **`flutter clean`** and full reinstall; native channel or plugins must register. |
| Loader only once / flashes | Addressed by frame waits + `450 ms` minimum; if still wrong, check for duplicate `Navigator` or wrong `context`. |
| `PlatformException` from native | See `MainActivity` error codes (`PERM`, `NO_DIALER`, etc.). |

---

## 9. Version note

Dependency versions are defined in **`pubspec.yaml`** (e.g. `url_launcher: ^6.3.0`, `permission_handler: ^11.3.1`). Upgrade only after checking changelogs for breaking changes to permissions or `tel:` behavior.
