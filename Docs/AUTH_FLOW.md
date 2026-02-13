# 🔐 Authentication Flow

Hệ thống sử dụng cơ chế **JWT (JSON Web Token)** với `accessToken` (ngắn hạn) và `refreshToken` (dài hạn).

## 📊 Quy trình Đăng nhập (Login Flow)

```mermaid
sequenceDiagram
    actor U as Người dùng
    participant UI as Login Screen
    participant P as AuthProvider
    participant S as AuthService
    participant API as Backend API
    participant LS as Secure Storage

    U->>UI: Nhập Email/Password
    UI->>P: login(email, pass)
    P->>S: api.login(email, pass)
    S->>API: POST /auth/login
    API-->>S: 200 OK { access, refresh }
    S->>LS: Lưu Tokens
    S-->>P: AuthResponse (User Info)
    P->>P: isLoggedIn = true
    P-->>UI: Success
    UI->>UI: Navigate -> Home
```

---

## 🔄 Cơ chế Tự động Refresh Token (Interceptor)

Khi Access Token hết hạn, hệ thống tự động làm mới mà không cần người dùng đăng nhập lại.

```mermaid
sequenceDiagram
    participant APP as Mobile App
    participant INT as AuthInterceptor
    participant API as Backend API
    participant LS as Secure Storage

    APP->>INT: Request (GET /notes)
    INT->>LS: Lấy Access Token
    LS-->>INT: Token A (Expired)
    INT->>API: GET /notes (Bearer Token A)
    API-->>INT: 401 Unauthorized ❌

    Note over INT: Bắt lỗi 401 & Pause Queue

    INT->>LS: Lấy Refresh Token
    LS-->>INT: Token R
    INT->>API: POST /auth/refresh-token (Token R)
    API-->>INT: 200 OK { New Token A', New Token R' } ✅
    INT->>LS: Lưu Tokens Mới

    Note over INT: Retry Request Gốc

    INT->>API: GET /notes (Bearer Token A')
    API-->>APP: 200 OK (Data) ✅
```

## 🛡️ Secure Storage

Token được lưu trữ bằng `flutter_secure_storage`:
-   **Android**: EncryptedSharedPreferences (Keystore)
-   **iOS**: Keychain

Tuyệt đối không lưu token vào `SharedPreferences` thông thường.
