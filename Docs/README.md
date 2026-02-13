# 📘 NoteVui Mobile App Documentation

Chào mừng đến với bộ tài liệu kỹ thuật của dự án **NoteVui Mobile**.

## 📑 Mục lục

1.  **[Kiến trúc hệ thống (Architecture)](ARCHITECTURE.md)** 🏛️
    *   Mô hình Clean Architecture.
    *   Cấu trúc thư mục.
    *   Quản lý State (Provider).
    *   Lưu trữ Local (Hive).

2.  **[Quy trình xác thực (Authentication Flow)](AUTH_FLOW.md)** 🔐
    *   Đăng nhập / Đăng ký.
    *   Cơ chế JWT (Access & Refresh Token).
    *   Auto-retry với Dio Interceptor.

3.  **[Cơ chế đồng bộ dữ liệu (Offline-first Sync)](SYNC_FLOW.md)** 🔄
    *   Chiến lược "Local First".
    *   Conflict Resolution (Last Write Wins).
    *   API Sync Endpoint.

4.  **[API Specifications](API_SPECS.md)** 📡
    *   Danh sách Endpoints chi tiết.
    *   Request/Response Models.

---

## 🛠️ Công nghệ sử dụng

| Lĩnh vực | Công nghệ / Thư viện |
| :--- | :--- |
| **Framework** | ![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white) 3.x |
| **Language** | ![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat&logo=dart&logoColor=white) 3.x |
| **State Management** | `Provider` (ChangeNotifier) |
| **Network** | `Dio` + `Retrofit` (concept) |
| **Local Database** | `Hive` (NoSQL) |
| **Secure Storage** | `flutter_secure_storage` |
| **UI Design** | Glassmorphism, Custom Animations |

## 🚀 Tính năng nổi bật

-   ✅ **Offline-first**: Hoạt động hoàn toàn không cần mạng. Tự động đồng bộ khi có kết nối.
-   🔒 **Bảo mật cao**: Access Token ngắn hạn, Refresh Token dài hạn, lưu trữ an toàn.
-   ✨ **Giao diện Premium**: Thiết kế kính mờ (Glassmorphism), hiệu ứng mượt mà.
-   🤖 **AI Integration**: Tóm tắt, dịch thuật, kiểm tra ngữ pháp (VIP).
