import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:growth_tracker/models/daily_task.dart';
import 'package:growth_tracker/providers/task_provider.dart';
import 'package:growth_tracker/providers/user_provider.dart';
import 'package:growth_tracker/screens/main_shell.dart';
import 'package:growth_tracker/theme/app_theme.dart';

class TaskDiscoveryScreen extends StatefulWidget {
  const TaskDiscoveryScreen({super.key});

  @override
  State<TaskDiscoveryScreen> createState() => _TaskDiscoveryScreenState();
}

class _TaskDiscoveryScreenState extends State<TaskDiscoveryScreen> {
  bool _isLoading = false;
  String? _error;
  List<DailyTask> _dailyTasks = [];
  List<TaskSuggestion> _suggestions = [];
  int? _selectingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final user = context.read<UserProvider>().user;
      if (user == null) return;
      final provider = context.read<TaskProvider>();
      await provider.loadTodayTasks(user.id);
      final tasks = provider.todayTasks;
      if (tasks.isEmpty) {
        final suggestions = await provider.loadSuggestions(user.id);
        setState(() {
          _dailyTasks = [];
          _suggestions = suggestions;
        });
      } else {
        setState(() {
          _dailyTasks = tasks;
          _suggestions = [];
        });
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectTask(int taskId) async {
    setState(() => _selectingId = taskId);
    final user = context.read<UserProvider>().user;
    if (user == null) return;
    final ok = await context.read<TaskProvider>().selectTask(taskId, user.id);
    if (!mounted) return;
    setState(() => _selectingId = null);
    if (ok) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (_) => false,
      );
    }
  }

  String _intensityLabel(String category) {
    switch (category.toLowerCase()) {
      case 'kariyer':
      case 'zihinsel':
        return 'HIGH FLOW STATE';
      case 'mindfulness':
        return 'DECLUTTERING';
      default:
        return 'GROWTH';
    }
  }

  Color _intensityColor(String category) {
    switch (category.toLowerCase()) {
      case 'kariyer':
      case 'zihinsel':
        return AppColors.primary;
      case 'mindfulness':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            if (_isLoading)
              const SliverToBoxAdapter(child: _DiscoverySkeleton())
            else if (_error != null)
              SliverToBoxAdapter(child: _buildError())
            else ...[
              SliverToBoxAdapter(child: _buildAiBadge()),
              if (_dailyTasks.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _buildDailyTaskCard(_dailyTasks[i]),
                    childCount: _dailyTasks.length,
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _buildSuggestionCard(_suggestions[i]),
                    childCount: _suggestions.length,
                  ),
                ),
              SliverToBoxAdapter(child: _buildFocusPotentialBar()),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      backgroundColor: AppColors.background,
      pinned: true,
      elevation: 0,
      title: const Text(
        'Discovery Awaits',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppColors.textMuted),
          onPressed: _load,
        ),
      ],
    );
  }

  Widget _buildAiBadge() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome_rounded,
                color: AppColors.primary, size: 14),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                "YOUR AI HAS IDENTIFIED TODAY'S PEAK COGNITIVE PATHS",
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyTaskCard(DailyTask task) {
    final isSelected = task.isSelected;
    final categoryColor = AppTheme.categoryColor(task.category);
    final intensityColor = _intensityColor(task.category);
    final isSelecting = _selectingId == task.id;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: intensityColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: intensityColor.withOpacity(0.35)),
                  ),
                  child: Text(
                    _intensityLabel(task.category),
                    style: TextStyle(
                      color: intensityColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    AppTheme.categoryIcon(task.category),
                    color: categoryColor,
                    size: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              task.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              task.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    color: AppColors.textMuted, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${task.estimatedMinutes} min',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.success.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: AppColors.success, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Selected',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  _selectButton(
                    onPressed: () => _selectTask(task.id),
                    isLoading: isSelecting,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(TaskSuggestion suggestion) {
    final categoryColor = AppTheme.categoryColor(suggestion.category);
    final intensityColor = _intensityColor(suggestion.category);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: intensityColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: intensityColor.withOpacity(0.35)),
                  ),
                  child: Text(
                    _intensityLabel(suggestion.category),
                    style: TextStyle(
                      color: intensityColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    AppTheme.categoryIcon(suggestion.category),
                    color: categoryColor,
                    size: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              suggestion.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              suggestion.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    color: AppColors.textMuted, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${suggestion.estimatedMinutes} min',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                _selectButton(onPressed: null, isLoading: false),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectButton({required VoidCallback? onPressed, required bool isLoading}) {
    return SizedBox(
      height: 36,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.gradientPrimary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text(
                  'Select and Start →',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildFocusPotentialBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FOCUS POTENTIAL',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '64%',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Optimal window starts in 45m',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  '3.2k',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text(
                  'cognitive pts',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded, color: AppColors.textMuted, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Connection lost',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            label: const Text('Try again',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

class _DiscoverySkeleton extends StatelessWidget {
  const _DiscoverySkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: List.generate(
          3,
          (i) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }
}
