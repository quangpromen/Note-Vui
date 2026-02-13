# 📡 API Specifications

Đây là tài liệu chi tiết về các Endpoints của Backend NoteVui.

## 🛠 Cấu hình Chung

| Tham số | Giá trị |
| :--- | :--- |
| **Base URL (Local)** | `http://10.0.2.2:5000/api` |
| **Base URL (Prod)** | `https://api.notevui.com/api` |
| **Header Auth** | `Authorization: Bearer <token>` |

---

## 🔐 Auth (`/auth`)

### 1. Register
`POST /auth/register`

Tạo tài khoản người dùng mới.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "Password123!",
  "fullName": "Nguyen Van A"
}
```

### 2. Login
`POST /auth/login`

Đăng nhập xác thực người dùng.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "Password123!"
}
```

**Response (Success - 200 OK):**
```json
{
  "accessToken": "eyJhbGciOiJIUz...",
  "refreshToken": "d8e8fca2-...",
  "userId": "guid-...",
  "fullName": "Nguyen Van A"
}
```

### 3. Refresh Token
`POST /auth/refresh-token`

Lấy Access Token mới khi token cũ hết hạn.

**Request:**
```json
{
  "accessToken": "current-access-token",
  "refreshToken": "current-refresh-token"
}
```

---

## 📝 Sync (`/sync`)

Endpoint quan trọng nhất để đồng bộ dữ liệu hai chiều.

### `POST /sync`

Gửi dữ liệu thay đổi từ Client lên Server và nhận về các thay đổi từ Server.

**Request Body (`SyncRequest`):**
```json
{
  "lastSyncTime": "2024-02-13T10:00:00Z", 
  "changes": [
    {
      "clientId": "uuid-note-1",
      "title": "My Note",
      "fullContent": "Content...",
      "isPinned": true,
      "updatedAt": "2024-02-13T10:05:00Z"
    }
  ]
}
```

**Response (`SyncResponse`):**
```json
{
  "upserts": [
    {
      "clientId": "uuid-note-2",
      "title": "Server Note",
      "fullContent": "New content from others...",
      "updatedAt": "2024-02-13T10:10:00Z"
    }
  ],
  "serverTime": "2024-02-13T10:15:00Z"
}
```

---

## 🤖 AI Features (`/ai`) (VIP Only)

### `POST /ai/summarize`
Tóm tắt nội dung văn bản.

**Request:**
```json
{
  "content": "Long text needed summary...",
  "noteId": "uuid-note-1"
}
```

### `POST /ai/translate`
Dịch thuật văn bản.

**Request:**
```json
{
  "content": "Hello",
  "targetLanguage": "vi",
  "noteId": "uuid-note-1"
}
```

**Common Response:**
```json
{
  "result": "Kết quả AI xử lý...",
  "isSuccess": true
}
```
