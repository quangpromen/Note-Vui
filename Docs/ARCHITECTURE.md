# 🏛️ Architecture Overview

Dự án áp dụng mô hình **Clean Architecture** pha trộn với **Feature-first** để đảm bảo tính mở rộng và dễ bảo trì.

## 🏗️ Sơ đồ kiến trúc tầng (Layered Architecture)

```mermaid
graph TD
    UI[🖥️ Presentation Layer<br/>(Screens, Widgets, Providers)]
    
    subgraph Domain Layer
        Entities[📦 Entities (Note, User)]
        UseCases[⚙️ Use Cases / Services]
        RepoInterface[📝 Repository Interfaces]
    end

    subgraph Data Layer
        RepoImpl[🛠️ Repository Updates]
        LocalDS[📂 Local Data Source<br/>(Hive, SecureStorage)]
        RemoteDS[☁️ Remote Data Source<br/>(Dio Clients)]
        Models[DTO Models]
    end

    UI --> UseCases
    UseCases --> RepoInterface
    RepoImpl ..|> RepoInterface
    RepoImpl --> LocalDS
    RepoImpl --> RemoteDS
    RemoteDS --> Models
    LocalDS --> Models
```

---

## 📂 Cấu trúc thư mục

```
lib/
├── core/                   # 🧱 Các thành phần cốt lõi dùng chung
│   ├── auth/               #     - Logic xác thực (TokenStorage)
│   ├── theme/              #     - Giao diện (Colors, Fonts)
│   └── constants/          #     - Hằng số
│
├── features/               # 🧩 Các module chức năng (Feature-based)
│   ├── auth/               #     🔐 Module Auth
│   │   ├── presentation/   #         - UI (Login, Register Screens)
│   │   └── data/           #         - Repositories, Models
│   │
│   ├── notes/              #     📝 Module Notes (Chính)
│   │   ├── domain/         #         - NoteService (Business Logic)
│   │   ├── data/           #         - Hive, SyncClient
│   │   └── presentation/   #         - HomeScreen, EditorScreen
│   │
│   └── ai/                 #     🤖 Module AI
│
├── services/               # 📡 Services ngoại vi
│   ├── api_config.dart     #     - Cấu hình Base URL
│   ├── auth_service.dart   #     - Gọi API Auth
│   └── auth_interceptor.dart #   - Xử lý Token tự động
│
└── main.dart               # 🚀 Entry Point & Provider Setup
```

## 🔄 State Management

Sử dụng **Provider** (`ChangeNotifier`) để quản lý trạng thái:

1.  **`AuthProvider`**: Quản lý trạng thái đăng nhập (`isLoggedIn`), thông tin user (`currentUser`), loading (`isLoading`).
2.  **`NoteService`**: Quản lý danh sách ghi chú, logic CRUD, và đồng bộ dữ liệu (`syncPendingNotes`).

Các Service được khởi tạo Singleton hoặc cung cấp qua `ChangeNotifierProvider` tại Root (`main.dart`).
