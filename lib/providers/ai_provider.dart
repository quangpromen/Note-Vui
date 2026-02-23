import 'package:flutter/foundation.dart';
import '../models/ai_request.dart';
import '../models/ai_response.dart';
import '../services/ai_service.dart';

/// Enum đại diện cho các trạng thái trong khi giao tiếp với AI
enum AiProviderState {
  initial,
  loading,
  success,
  error,
  showPremiumDialog, // Yêu cầu người dùng nâng cấp VIP
}

/// Provider (ChangeNotifier) dùng để quản lý trạng thái màn hình AI Summarize,
class AiProvider extends ChangeNotifier {
  final AiService _aiService;

  AiProvider({AiService? aiService}) : _aiService = aiService ?? AiService();

  AiProviderState _state = AiProviderState.initial;
  AiProviderState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  AiResponse? _lastResponse;
  AiResponse? get lastResponse => _lastResponse;

  /// Gọi AI tóm tắt
  Future<void> summarizeContent(
    String content, {
    String? targetLanguage,
  }) async {
    // Validate cơ bản
    if (content.trim().isEmpty) {
      _setErrorMessage('Nội dung cần tóm tắt không được để trống.');
      return;
    }

    _setState(AiProviderState.loading);
    _errorMessage = null;

    try {
      final request = AiRequest(
        content: content,
        targetLanguage: targetLanguage,
      );

      final response = await _aiService.summarize(request);

      _lastResponse = response;
      _setState(AiProviderState.success);
    } on AiPremiumRequiredException catch (e) {
      _errorMessage = e.message;
      // Kích hoạt trạng thái mở Popup/Dialog nâng cấp Premium
      _setState(AiProviderState.showPremiumDialog);
    } on AiException catch (e) {
      _errorMessage = e.message;
      _setState(AiProviderState.error);
    } catch (e) {
      _errorMessage = 'Đã có lỗi xảy ra: $e';
      _setState(AiProviderState.error);
    }
  }

  /// Xóa trạng thái / reset lại
  void resetState() {
    _state = AiProviderState.initial;
    _errorMessage = null;
    _lastResponse = null;
    notifyListeners();
  }

  // --- Helpers ---
  void _setState(AiProviderState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setErrorMessage(String message) {
    _errorMessage = message;
    _state = AiProviderState.error;
    notifyListeners();
  }

  /// Gọi AI dịch
  Future<void> translateContent(
    String content,
    String targetLanguage, {
    String? noteId,
  }) async {
    // Validate cơ bản
    if (content.trim().isEmpty) {
      _setErrorMessage('Nội dung cần dịch không được để trống.');
      return;
    }

    if (targetLanguage.trim().isEmpty) {
      _setErrorMessage('Vui lòng chọn ngôn ngữ đích.');
      return;
    }

    _setState(AiProviderState.loading);
    _errorMessage = null;

    try {
      final request = AiRequest(
        content: content,
        targetLanguage: targetLanguage,
        noteId: noteId,
      );

      final response = await _aiService.translate(request);

      _lastResponse = response;
      _setState(AiProviderState.success);
    } on AiPremiumRequiredException catch (e) {
      _errorMessage = e.message;
      // Kích hoạt trạng thái mở Popup/Dialog nâng cấp Premium
      _setState(AiProviderState.showPremiumDialog);
    } on AiException catch (e) {
      _errorMessage = e.message;
      _setState(AiProviderState.error);
    } catch (e) {
      _errorMessage = 'Đã có lỗi xảy ra: $e';
      _setState(AiProviderState.error);
    }
  }
}
