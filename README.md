# CipherTask – Secure Encrypted To-Do System (Flutter, Strict MVVM)

**Repo:** (https://github.com/iloysalvador948-coder/Cipher_Task1)

**APK:** [PASTE_APK_LINK_OR_LOCATION_HERE]

CipherTask is a local-first secure To-Do app demonstrating:
- **Encrypted database at rest** (Hive + `HiveAesCipher`)
- **AES-256-GCM field encryption** (sensitive note/details)
- **Hardware-backed key storage** (`flutter_secure_storage` → Android Keystore / iOS Keychain)
- **Biometric unlock** after first password login (`local_auth`)
- **Session auto-lock after 120 seconds** of inactivity using a root `Listener`
- Optional: **Screenshot prevention** (`screen_protector`)
- Optional: **OTP screen simulation** during registration (no real email; for lab demo)

---

## Team Roles 
- Angelo Padullon – Lead Architect & DB Engineer, Security & Cryptography Lead
- Jhonn Lee Maning – Auth & Biometrics Specialist, Backend & Network (SSL)
- Rolly Boy Ryan Pionilla – UI/UX & Integration
---

## Strict MVVM Folder Structure (MANDATORY)

lib/
├── main.dart
├── models/
│ ├── todo_model.dart
│ └── user_model.dart
├── views/
│ ├── login_view.dart
│ ├── register_view.dart
│ ├── todo_list_view.dart
│ └── widgets/
├── viewmodels/
│ ├── auth_viewmodel.dart
│ └── todo_viewmodel.dart
├── services/
│ ├── encryption_service.dart
│ ├── database_service.dart
│ ├── key_storage_service.dart
│ └── session_service.dart
└── utils/
└── constants.dart


---

## Features Checklist
### Security
- [x] Encrypted database at rest (Hive + HiveAesCipher, key stored in secure storage)
- [x] AES-256-GCM encryption for sensitive note field (random nonce per encrypt)
- [x] No hardcoded encryption keys
- [x] Session auto-lock after **120 seconds** inactivity (resets on every touch)
- [x] Biometric unlock available only after at least one successful password login
- [x] Optional screenshot prevention enabled

### App
- [x] Register (email + password) stored locally
- [x] OTP screen simulation during registration (lab demonstration)
- [x] Login (password)
- [x] Add / View / Edit / Delete To-Dos
- [x] Toggle completed status
- [x] Created/updated timestamps

---

## Tech Stack
- Flutter
- Provider (state management)
- Hive + hive_flutter (local database)
- flutter_secure_storage (hardware-backed key storage)
- encrypt (AES-GCM)
- pointycastle (PBKDF2 password hashing)
- local_auth (biometrics)
- screen_protector (screenshot prevention)

---

## Setup & Run
### 1) Install dependencies
```bash
flutter pub get

2) Run
flutter run

On first run, the app generates a 32-byte DB encryption key and stores it in secure storage.

Build APK (Release)
flutter build apk --release

APK output:

build/app/outputs/flutter-apk/app-release.apk

Notes
AES payload format

Sensitive note is stored as:
v1:<iv_base64>:<cipher_base64>

How to swap to SQLCipher later (high level)

Replace Hive storage with sqflite_sqlcipher.

Keep key storage the same (KeyStorageService).

Keep AES-GCM field encryption unchanged (EncryptionService).

Move CRUD logic from Hive to SQLCipher tables.

Security Disclaimer

This is a laboratory exercise. It demonstrates correct separation of concerns (Strict MVVM) and baseline secure patterns for local storage. For production, add:

device integrity checks,

secure wipe on logout (optional),

rate limiting / lockout on repeated failed logins,

stronger password policy + UI feedback,

backup/restore strategy with key rotation.


---

## 8) Testing Checklist (functional + security)

### Functional Tests
- [ ] Register new user with valid email/password → OTP simulation appears → account created
- [ ] Register same email again → blocked with error
- [ ] Login with correct password → navigates to To-Do list
- [ ] Login with wrong password → error shown
- [ ] Add a to-do with title + note → appears in list
- [ ] Edit a to-do → changes persist after restart
- [ ] Toggle completed checkbox → state persists after restart
- [ ] Delete to-do → confirmation dialog → removed
- [ ] Logout → returns to Login, to-do list not accessible

### Security Tests
- [ ] Verify **no encryption keys** appear in source code (keys only in secure storage)
- [ ] Verify Hive boxes are opened with `HiveAesCipher` (encrypted at rest)
- [ ] Verify sensitive note is stored as `v1:<iv>:<cipher>` (not plaintext)
- [ ] Verify different encryptions of same note produce different ciphertext (random nonce)
- [ ] Verify biometric unlock:
  - first-time user cannot unlock biometrically until password login occurs
  - biometric must be enabled by toggle (after password login)
- [ ] Verify inactivity timeout:
  - leave app untouched for **120s** → auto-logout → Login shown
  - interacting (taps/scroll) keeps session alive
- [ ] Screenshot prevention (bonus):
  - attempt screenshot → blocked (device-dependent)
- [ ] Data separation:
  - Views contain no DB/encryption calls (only ViewModel calls)
  - Services contain no UI code

---

## 9) One-Page Infographic Content (text layout only)

**TITLE:** CipherTask – Secure Encrypted To-Do (Flutter • Strict MVVM)

**SUBTITLE:** Demon Slayer Theme • Local-First Security Lab

---

### 1) Problem
- Local notes and to-dos are often stored in plaintext.
- Lost phone = exposed private notes.
- Need secure at-rest storage + secure unlock + session protection.

---

### 2) Solution (What CipherTask Built)
- Encrypted database storage (Hive + HiveAesCipher)
- AES-256-GCM encrypts sensitive note field per record
- Hardware-backed key storage (Keystore/Keychain via flutter_secure_storage)
- Biometric unlock (after first password login)
- Auto-lock after **120 seconds** inactivity (root Listener resets timer)

---

### 3) Security Flow (Simple)
1. First run → generate 32-byte DB key → store in secure storage  
2. Open encrypted Hive boxes using DB key  
3. Before saving note → AES-GCM encrypt with random nonce  
4. On inactivity (120s) → lock session → return to Login  
5. Biometrics allowed only after password login + user toggle enabled

---

### 4) Strict MVVM Responsibilities
- **Views:** UI only (screens, dialogs, snackbars)
- **ViewModels:** state + orchestration (calls services)
- **Services:** encryption, secure keys, database, sessions
- **Models:** plain data classes

---

### 5) Tools / Packages
- Provider, Hive, hive_flutter  
- flutter_secure_storage  
- encrypt (AES-GCM), pointycastle (PBKDF2)  
- local_auth (biometrics)  
- screen_protector (screenshot prevention)  

---

### 6) Team
- Angelo Padullon – Lead Architect & DB Engineer, Security & Cryptography Lead
- Jhonn Lee Maning – Auth & Biometrics Specialist, Backend & Network (SSL)
- Rolly Boy Ryan Pionilla – UI/UX & Integration  
---

### 7) Links
- GitHub: [PASTE_PUBLIC_GITHUB_URL_HERE]  
- APK: [PASTE_APK_LINK_OR_LOCATION_HERE]    

--- 

If you paste these files into the exact folder structure and run `flutter pub get`, this project is **compile-ready** and follows **Strict MVVM** with the required security controls.
