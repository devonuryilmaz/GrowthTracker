import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:growth_tracker/models/daily_task.dart';
import 'package:growth_tracker/providers/stats_provider.dart';
import 'package:growth_tracker/providers/user_provider.dart';
import 'package:growth_tracker/theme/app_theme.dart';

class JourneyScreen extends StatefulWidget {
  const JourneyScreen({super.key});

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  bool _showCalendar = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;
    final provider = context.read<StatsProvider>();
    await Future.wait([
      provider.loadHistory(user.id),
      provider.loadStats(user.id),
    ]);
  }

  int _streak(List<DailyTask> history) {
    final completed = history
        .where((t) => t.isCompleted && t.completedAt != null)
        .toList()
      ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
    if (completed.isEmpty) return 0;

    int streak = 0;
    DateTime cursor = DateTime.now();
    final seen = <String>{};
    for (final t in completed) {
      final key = DateFormat('yyyy-MM-dd').format(t.completedAt!);
      final diff = cursor
          .difference(DateTime.parse(key))
          .inDays;
      if (diff > 1) break;
      if (seen.add(key)) {
        streak++;
        cursor = DateTime.parse(key);
      }
    }
    return streak;
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
            SliverToBoxAdapter(
              child: Consumer<StatsProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) return const _JourneySkeleton();
                  return _buildContent(provider);
                },
              ),
            ),
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
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Growth History',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'Tracking your cognitive evolution',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _toggleTab('Holistic', !_showCalendar),
              _toggleTab('Overview', _showCalendar),
            ],
          ),
        ),
      ],
    );
  }

  Widget _toggleTab(String label, bool active) {
    return GestureDetector(
      onTap: () => setState(() => _showCalendar = label == 'Overview'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: active ? AppColors.gradientPrimary : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(StatsProvider provider) {
    final history = provider.history;
    final stats = provider.stats;
    final total = provider.totalCompleted;
    final streak = _streak(history);
    final thisWeek = history
        .where((t) =>
            t.isCompleted &&
            t.completedAt != null &&
            DateTime.now().difference(t.completedAt!).inDays < 7)
        .length;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(
            children: [
              _summaryCard('Total', total.toString(), Icons.check_circle_rounded, AppColors.success),
              const SizedBox(width: 10),
              _summaryCard('Streak', '$streak days', Icons.local_fire_department_rounded, AppColors.warning),
              const SizedBox(width: 10),
              _summaryCard('This Week', thisWeek.toString(), Icons.calendar_today_rounded, AppColors.primary),
            ],
          ),
          const SizedBox(height: 20),
          if (!_showCalendar) ...[
            _buildProgressSection(stats, history),
          ] else ...[
            _buildCalendarView(history),
          ],
          const SizedBox(height: 20),
          _buildActivityJournal(history),
          const SizedBox(height: 20),
          if (!_showCalendar) _buildAttributeBalance(stats),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection(Map<String, dynamic>? stats, List<DailyTask> history) {
    final total = stats?['totalCompleted'] as int? ?? 1;
    final pct = total > 0 ? math.min((total / math.max(total * 1.2, 1)), 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bar chart
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.gradientCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Holistic Progress',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Last 30 days reflection',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
              const SizedBox(height: 16),
              _WeeklyBarChart(history: history),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Formula card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3D2F8F), Color(0xFF1A1830)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'YOUR FORMULA IS:',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(pct * 100).round()}%',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      letterSpacing: -2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'You are between 9AM and 11PM. AI estimates you will stay with flow.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 38,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientPrimary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Optimize Schedule',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarView(List<DailyTask> history) {
    final completedDates = history
        .where((t) => t.isCompleted && t.completedAt != null)
        .map((t) => DateFormat('yyyy-MM-dd').format(t.completedAt!))
        .toSet();
    final today = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(today);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activity Calendar',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map((d) => Text(d,
                    style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)))
                .toList(),
          ),
          const SizedBox(height: 8),
          ...List.generate(5, (week) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (day) {
                  final date =
                      today.subtract(Duration(days: (4 - week) * 7 + (6 - day)));
                  final key = DateFormat('yyyy-MM-dd').format(date);
                  final isToday = key == todayKey;
                  final isCompleted = completedDates.contains(key);
                  final isFuture = date.isAfter(today);

                  return Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isFuture
                          ? Colors.transparent
                          : isCompleted
                              ? AppColors.primary.withOpacity(0.7)
                              : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(7),
                      border: isToday
                          ? Border.all(color: AppColors.primary, width: 2)
                          : null,
                    ),
                    child: isCompleted && !isFuture
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 12)
                        : null,
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActivityJournal(List<DailyTask> history) {
    final recent = history
        .where((t) => t.isCompleted && t.completedAt != null)
        .toList()
      ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
    final shown = recent.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Activity Journal',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 20),
          ],
        ),
        const SizedBox(height: 12),
        if (shown.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No completed sessions yet',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          )
        else
          ...shown.map((task) => _journalEntry(task)),
      ],
    );
  }

  Widget _journalEntry(DailyTask task) {
    final color = AppTheme.categoryColor(task.category);
    final timeAgo = _timeAgo(task.completedAt!);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(AppTheme.categoryIcon(task.category),
                color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  task.category,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            timeAgo,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributeBalance(Map<String, dynamic>? stats) {
    final byCategory = stats?['byCategory'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attribute Balance',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              // Pentagon radar chart
              SizedBox(
                width: double.infinity,
                height: 180,
                child: _RadarChart(
                  categories: byCategory.isEmpty
                      ? [
                          {'name': 'Kariyer', 'count': 0},
                          {'name': 'Zihinsel', 'count': 0},
                          {'name': 'Sağlık', 'count': 0},
                          {'name': 'Finansal', 'count': 0},
                          {'name': 'Mindfulness', 'count': 0},
                        ]
                      : byCategory,
                ),
              ),
              const SizedBox(height: 16),
              // Category legend bars
              ...( byCategory.isEmpty
                  ? [
                      {'name': 'Kariyer', 'count': 0},
                      {'name': 'Sağlık', 'count': 0},
                      {'name': 'Zihinsel', 'count': 0},
                    ]
                  : byCategory.take(4).toList()
              ).map((cat) {
                final name = cat['name']?.toString() ?? '';
                final count = (cat['count'] as num?)?.toInt() ?? 0;
                final maxCount = byCategory.isEmpty
                    ? 1
                    : (byCategory
                            .map((c) => (c['count'] as num?)?.toInt() ?? 0)
                            .reduce((a, b) => a > b ? a : b))
                        .clamp(1, 99999);
                final pct = count / maxCount;
                final color = AppTheme.categoryColor(name);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 6,
                            backgroundColor: AppColors.surfaceElevated,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$count',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }
}

// ── Weekly Bar Chart ──────────────────────────────────────────────────────────

class _WeeklyBarChart extends StatelessWidget {
  final List<DailyTask> history;
  const _WeeklyBarChart({required this.history});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      final key = DateFormat('yyyy-MM-dd').format(d);
      final count = history
          .where((t) =>
              t.isCompleted &&
              t.completedAt != null &&
              DateFormat('yyyy-MM-dd').format(t.completedAt!) == key)
          .length;
      return MapEntry(DateFormat('EEE').format(d), count);
    });
    final maxCount = days.map((e) => e.value).reduce(math.max).clamp(1, 99999);

    return SizedBox(
      height: 100,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: days.map((e) {
          final ratio = e.value / maxCount;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: FractionallySizedBox(
                      heightFactor: ratio.clamp(0.05, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.gradientPrimary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    e.key,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Radar/Pentagon Chart ──────────────────────────────────────────────────────

class _RadarChart extends StatelessWidget {
  final List<dynamic> categories;
  const _RadarChart({required this.categories});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RadarPainter(categories: categories),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final List<dynamic> categories;
  _RadarPainter({required this.categories});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 20;
    final sides = math.max(categories.length, 5);
    final maxVal = categories.isEmpty
        ? 1
        : (categories.map((c) => (c['count'] as num?)?.toDouble() ?? 0.0).reduce(math.max)).clamp(1.0, double.infinity);

    // Background grid
    final gridPaint = Paint()
      ..color = AppColors.cardBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int level = 1; level <= 4; level++) {
      final r = radius * level / 4;
      final path = Path();
      for (int i = 0; i < sides; i++) {
        final angle = (2 * math.pi * i / sides) - math.pi / 2;
        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Spoke lines
    for (int i = 0; i < sides; i++) {
      final angle = (2 * math.pi * i / sides) - math.pi / 2;
      canvas.drawLine(
        center,
        Offset(center.dx + radius * math.cos(angle),
            center.dy + radius * math.sin(angle)),
        gridPaint,
      );
    }

    if (categories.isEmpty) return;

    // Data polygon
    final fillPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.25)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final dataPath = Path();
    for (int i = 0; i < sides; i++) {
      final catIndex = i % categories.length;
      final val = (categories[catIndex]['count'] as num?)?.toDouble() ?? 0.0;
      final ratio = (val / maxVal).clamp(0.05, 1.0);
      final angle = (2 * math.pi * i / sides) - math.pi / 2;
      final x = center.dx + radius * ratio * math.cos(angle);
      final y = center.dy + radius * ratio * math.sin(angle);
      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }
    dataPath.close();
    canvas.drawPath(dataPath, fillPaint);
    canvas.drawPath(dataPath, strokePaint);

    // Labels
    final tp = TextPainter(textDirection: ui.TextDirection.ltr);
    for (int i = 0; i < math.min(categories.length, sides); i++) {
      final angle = (2 * math.pi * i / sides) - math.pi / 2;
      final labelRadius = radius + 16;
      final x = center.dx + labelRadius * math.cos(angle);
      final y = center.dy + labelRadius * math.sin(angle);
      final name = categories[i]['name']?.toString() ?? '';
      tp.text = TextSpan(
        text: name.length > 8 ? '${name.substring(0, 7)}…' : name,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
      );
      tp.layout();
      tp.paint(canvas,
          Offset(x - tp.width / 2, y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _JourneySkeleton extends StatelessWidget {
  const _JourneySkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: List.generate(
              3,
              (i) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < 2 ? 10 : 0),
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(
            3,
            (i) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: i == 0 ? 160 : 100,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
