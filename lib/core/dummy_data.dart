import '../features/notes/data/models/note_model.dart';
import 'theme/app_colors.dart';

/// Mock/dummy data for development and testing.
/// This data will be replaced with actual database queries in production.
class DummyData {
  DummyData._(); // Private constructor to prevent instantiation

  /// Sample notes with Vietnamese content for UI testing.
  /// These notes demonstrate various use cases:
  /// - Shopping lists
  /// - Work ideas
  /// - Learning goals
  /// - Recipes
  /// - Personal goals
  /// - Event planning
  static final List<NoteModel> notes = [
    NoteModel(
      id: '1',
      title: 'Đi chợ mua rau',
      content:
          'Cà chua, rau muống, thịt heo, đậu phụ, hành lá, tỏi, ớt tươi. Nhớ mua thêm nước mắm ngon nhé!',
      createdAt: DateTime(2026, 1, 4),
      backgroundColor: AppColors.pastelColors[0],
    ),
    NoteModel(
      id: '2',
      title: 'Ý tưởng Marketing',
      content:
          'Tạo chiến dịch quảng cáo trên TikTok, hợp tác với KOL, tổ chức sự kiện offline cho khách hàng thân thiết.',
      createdAt: DateTime(2026, 1, 3),
      backgroundColor: AppColors.pastelColors[1],
    ),
    NoteModel(
      id: '3',
      title: 'Học tiếng Anh',
      content:
          'Ôn tập vocabulary về chủ đề Business. Luyện speaking 15 phút mỗi ngày. Xem phim có phụ đề tiếng Anh.',
      createdAt: DateTime(2026, 1, 2),
      backgroundColor: AppColors.pastelColors[2],
    ),
    NoteModel(
      id: '4',
      title: 'Công thức Phở Bò',
      content:
          'Xương bò 2kg, hành tây nướng, gừng nướng, quế, hồi, thảo quả. Ninh trong 6 tiếng với lửa nhỏ liu riu.',
      createdAt: DateTime(2026, 1, 1),
      backgroundColor: AppColors.pastelColors[3],
    ),
    NoteModel(
      id: '5',
      title: 'Mục tiêu năm 2026',
      content:
          '1. Đọc 12 cuốn sách\n2. Tập thể dục 3 lần/tuần\n3. Tiết kiệm 20% lương\n4. Học một kỹ năng mới',
      createdAt: DateTime(2025, 12, 28),
      backgroundColor: AppColors.pastelColors[4],
    ),
    NoteModel(
      id: '6',
      title: 'Sinh nhật Mẹ',
      content:
          'Nhớ đặt bánh kem trước 2 ngày. Mua hoa hồng phấn và quà là khăn lụa. Tổ chức tại nhà hàng Ngọc Lan.',
      createdAt: DateTime(2025, 12, 25),
      backgroundColor: AppColors.pastelColors[5],
    ),
  ];
}
