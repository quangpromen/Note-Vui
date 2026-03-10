import 'package:flutter/foundation.dart';

import '../../../../core/auth/token_storage.dart';
import '../../data/models/subscription_request_entity.dart';
import '../../data/repositories/subscription_repository_impl.dart';
import '../../domain/repositories/subscription_repository.dart';

enum SubscriptionResult { success, error, unauthorized }

enum FetchStatus { initial, loading, success, error, unauthorized }

class SubscriptionController extends ChangeNotifier {
  SubscriptionController({SubscriptionRepository? repository})
    : _repository = repository ?? SubscriptionRepositoryImpl();

  final SubscriptionRepository _repository;
  final TokenStorage _tokenStorage = TokenStorage();

  // ─── State ──────────────────────────────────────────────────────────
  FetchStatus _fetchStatus = FetchStatus.initial;
  List<SubscriptionRequestEntity> _requests = [];
  bool _isLoadingForm = false;
  String? _errorMessage;
  String? _successMessage;

  // ─── Getters ────────────────────────────────────────────────────────
  FetchStatus get fetchStatus => _fetchStatus;
  List<SubscriptionRequestEntity> get requests => _requests;
  bool get isLoadingForm => _isLoadingForm;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  bool get isListLoading =>
      _fetchStatus == FetchStatus.loading ||
      _fetchStatus == FetchStatus.initial;
  bool get hasError => _fetchStatus == FetchStatus.error;

  // ═══════════════════════════════════════════════════════════════════════
  // GET MY REQUESTS
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> fetchMyRequests() async {
    _fetchStatus = FetchStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _repository.getMyRequests();
      _requests = data;
      _fetchStatus = FetchStatus.success;
    } on SubscriptionUnauthorizedException {
      await _tokenStorage.clearAll();
      _errorMessage = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      _fetchStatus = FetchStatus.unauthorized;
    } on SubscriptionException catch (e) {
      _errorMessage = e.message;
      _fetchStatus = FetchStatus.error;
    } catch (_) {
      _errorMessage = 'Đã xảy ra lỗi. Vui lòng thử lại.';
      _fetchStatus = FetchStatus.error;
    }

    notifyListeners();
  }

  Future<void> refreshRequests() async {
    try {
      final data = await _repository.getMyRequests();
      _requests = data;
      _fetchStatus = FetchStatus.success;
      _errorMessage = null;
    } on SubscriptionUnauthorizedException {
      await _tokenStorage.clearAll();
      _errorMessage = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      _fetchStatus = FetchStatus.unauthorized;
    } on SubscriptionException catch (e) {
      _errorMessage = e.message;
      if (_requests.isEmpty) _fetchStatus = FetchStatus.error;
    } catch (_) {
      _errorMessage = 'Đã xảy ra lỗi. Vui lòng thử lại.';
      if (_requests.isEmpty) _fetchStatus = FetchStatus.error;
    }

    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CREATE UPGRADE REQUEST
  // ═══════════════════════════════════════════════════════════════════════

  Future<SubscriptionResult> createUpgradeRequest({
    required int planType,
    required String note,
  }) async {
    _isLoadingForm = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final request = await _repository.createUpgradeRequest(planType, note);

      _successMessage =
          'Yêu cầu nâng cấp đã được gửi thành công. Vui lòng chờ Admin phê duyệt.';

      // Update local state by prepending the new request
      _requests = [request, ..._requests];

      return SubscriptionResult.success;
    } on SubscriptionUnauthorizedException {
      await _tokenStorage.clearAll();
      _errorMessage = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      return SubscriptionResult.unauthorized;
    } on SubscriptionException catch (e) {
      _errorMessage = e.message;
      return SubscriptionResult.error;
    } catch (_) {
      _errorMessage = 'Đã xảy ra lỗi. Vui lòng thử lại.';
      return SubscriptionResult.error;
    } finally {
      _isLoadingForm = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CANCEL REQUEST
  // ═══════════════════════════════════════════════════════════════════════

  Future<bool> cancelRequest(int id) async {
    try {
      final success = await _repository.cancelRequest(id);
      if (success) {
        // Update local list state instead of calling API again
        final index = _requests.indexWhere((r) => r.id == id);
        if (index != -1) {
          final old = _requests[index];
          _requests[index] = SubscriptionRequestEntity(
            id: old.id,
            planType: old.planType,
            planName: old.planName,
            status: 'Cancelled',
            note: old.note,
            adminNote: old.adminNote,
            createdAt: old.createdAt,
            processedAt: null,
          );
          notifyListeners();
        }
        return true;
      }
      return false;
    } on SubscriptionUnauthorizedException {
      await _tokenStorage.clearAll();
      _errorMessage = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      notifyListeners();
      return false;
    } on SubscriptionException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Đã xảy ra lỗi. Vui lòng thử lại.';
      notifyListeners();
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }
}
