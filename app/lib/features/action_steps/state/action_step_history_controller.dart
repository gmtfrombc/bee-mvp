import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/action_step_repository.dart';
import '../models/action_step_history_entry.dart';

/// StateNotifier that lazily paginates the user’s Action Step history.
class ActionStepHistoryController
    extends StateNotifier<AsyncValue<List<ActionStepHistoryEntry>>> {
  ActionStepHistoryController(this._repo) : super(const AsyncLoading()) {
    _loadInitial();
  }

  final ActionStepRepository _repo;

  static const _pageSize = 10;
  var _offset = 0;
  var _hasMore = true;

  Future<void> _loadInitial() async {
    try {
      final items = await _repo.fetchHistory(offset: 0, limit: _pageSize);
      _offset = items.length;
      _hasMore = items.length == _pageSize;
      state = AsyncData(items);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> loadMore() async {
    // Don’t fetch again if already all data loaded or currently loading.
    if (!_hasMore || state is AsyncLoading) return;
    state = const AsyncLoading();
    try {
      final items = await _repo.fetchHistory(offset: _offset, limit: _pageSize);
      _offset += items.length;
      _hasMore = items.length == _pageSize;
      final current = <ActionStepHistoryEntry>[];
      final prev = state is AsyncData<List<ActionStepHistoryEntry>>
          ? (state as AsyncData<List<ActionStepHistoryEntry>>).value
          : <ActionStepHistoryEntry>[];
      current.addAll(prev);
      current.addAll(items);
      state = AsyncData(current);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> refresh() async {
    _offset = 0;
    _hasMore = true;
    state = const AsyncLoading();
    await _loadInitial();
  }
}

final actionStepHistoryControllerProvider =
    StateNotifierProvider<ActionStepHistoryController, AsyncValue<List<ActionStepHistoryEntry>>>(
  (ref) {
    final repo = ref.watch(actionStepRepositoryProvider);
    return ActionStepHistoryController(repo);
  },
); 