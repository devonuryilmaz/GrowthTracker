import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
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
  bool _useTableCalendar = true;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

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

  List<DailyTask> _eventsForDay(DateTime day, List<DailyTask> history) {
    final key = DateFormat('yyyy-MM-dd').format(day);
    return history
        .where((t) =>
            t.isCompleted &&
            t.completedAt != null &&
            DateFormat('yyyy-MM-dd').format(t.completedAt!) == key)
        .toList();
  }

  void _showDayTasksSheet(List<DailyTask> tasks, DateTime day) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              DateFormat('d MMMM EEEE').format(day),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (tasks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Bu gün tamamlanan görev yok.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              )
            else
              ...tasks.map((t) => _journalEntry(t)),
          ],
        ),
      ),
    );
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
            'Büyüme Geçmişi',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'Bilişsel gelişimini takip ediyoruz',
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
              _toggleTab('Holistik', !_showCalendar),
              _toggleTab('Genel Bakış', _showCalendar),
            ],
          ),
        ),
      ],
    );
  }

  Widget _toggleTab(String label, bool active) {
    return GestureDetector(
      onTap: () => setState(() => _showCalendar = label == 'Genel Bakış'),
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

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          _buildEmptyStatsRow(provider),
          const SizedBox(height: 20),
          if (!_showCalendar) ...[
            _buildProgressSection(stats, history),
          ] else ...[
            _buildCalendarView(history),
          ],
          if (!_showCalendar) ...[
            const SizedBox(height: 20),
            _buildAttributeBalance(stats),
          ],
          const SizedBox(height: 20),
          _buildActivityJournal(history),
        ],
      ),
    );
  }

  Widget _buildEmptyStatsRow(StatsProvider stats) {
    return Row(
      children: [
        _buildStatCard('🔥', '${stats.currentStreak}', 'Gün Serisi', AppColors.warning),
        const SizedBox(width: 10),
        _buildStatCard('📅', '${stats.weeklyCompleted}', 'Bu Hafta', AppColors.primary),
        const SizedBox(width: 10),
        _buildStatCard('✅', '${stats.totalCompleted}', 'Toplam', AppColors.success),
      ],
    );
  }

  Widget _buildStatCard(String icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
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

  Widget _buildProgressSection(
      Map<String, dynamic>? stats, List<DailyTask> history) {
    return Container(
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
            'Holistik İlerleme',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Son 7 günlük tamamlanan görevler',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 16),
          _WeeklyBarChart(history: history),
        ],
      ),
    );
  }

  Widget _buildCalendarView(List<DailyTask> history) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle between grid and table calendar
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _calendarToggleTab('Takvim', _useTableCalendar),
              _calendarToggleTab('Izgara', !_useTableCalendar),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_useTableCalendar)
          _buildTableCalendar(history)
        else
          _buildGridCalendarView(history),
      ],
    );
  }

  Widget _calendarToggleTab(String label, bool active) {
    return GestureDetector(
      onTap: () => setState(() => _useTableCalendar = label == 'Takvim'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          gradient: active ? AppColors.gradientPrimary : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTableCalendar(List<DailyTask> history) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: TableCalendar<DailyTask>(
            firstDay: DateTime.now().subtract(const Duration(days: 90)),
            lastDay: DateTime.now(),
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.month,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: (day) => _eventsForDay(day, history),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              final tasks = _eventsForDay(selectedDay, history);
              _showDayTasksSheet(tasks, selectedDay);
            },
            onPageChanged: (focusedDay) {
              setState(() => _focusedDay = focusedDay);
            },
            availableCalendarFormats: const {
              CalendarFormat.month: 'Ay',
            },
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              todayDecoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              todayTextStyle: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              defaultTextStyle: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
              weekendTextStyle: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
              disabledTextStyle: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
              markerSize: 6,
              markersMaxCount: 3,
              markersAlignment: Alignment.bottomCenter,
              markerMargin: const EdgeInsets.symmetric(horizontal: 0.5),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              leftChevronIcon: Icon(
                Icons.chevron_left_rounded,
                color: AppColors.textSecondary,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              weekendStyle: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isEmpty) return const SizedBox.shrink();
                final shown = events.take(3).toList();
                return Positioned(
                  bottom: 2,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: shown.map((task) {
                      final color = AppTheme.categoryColor(task.category);
                      return Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 0.5),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildCategoryLegend(),
      ],
    );
  }

  Widget _buildGridCalendarView(List<DailyTask> history) {
    final completedDates = history
        .where((t) => t.isCompleted && t.completedAt != null)
        .map((t) => DateFormat('yyyy-MM-dd').format(t.completedAt!))
        .toSet();

    // Build category lookup: date key → list of tasks
    final Map<String, List<DailyTask>> dateTaskMap = {};
    for (final t in history) {
      if (t.isCompleted && t.completedAt != null) {
        final key = DateFormat('yyyy-MM-dd').format(t.completedAt!);
        dateTaskMap.putIfAbsent(key, () => []).add(t);
      }
    }

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz']
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
                  final date = today
                      .subtract(Duration(days: (4 - week) * 7 + (6 - day)));
                  final key = DateFormat('yyyy-MM-dd').format(date);
                  final isToday = key == todayKey;
                  final isFuture = date.isAfter(today);
                  final tasks = dateTaskMap[key] ?? [];
                  final isCompleted = completedDates.contains(key);

                  // Pick the dominant color (first task's category)
                  Color? dotColor;
                  if (!isFuture && tasks.isNotEmpty) {
                    dotColor = AppTheme.categoryColor(tasks.first.category);
                  }

                  return GestureDetector(
                    onTap: isFuture || tasks.isEmpty
                        ? null
                        : () => _showDayTasksSheet(tasks, date),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isFuture
                            ? Colors.transparent
                            : isCompleted
                                ? (dotColor ?? AppColors.primary)
                                    .withOpacity(0.75)
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
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryLegend() {
    const categories = [
      ('Sağlık', AppColors.categoryHealth),
      ('Kariyer', AppColors.categoryCareer),
      ('Zihinsel', AppColors.categoryMind),
      ('Öğrenme', AppColors.categoryLearning),
      ('Yaratıcı', AppColors.categoryMindfulness),
      ('Finansal', AppColors.categoryFinancial),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: categories.map((cat) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: cat.$2,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                cat.$1,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );
        }).toList(),
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
              'Aktivite Günlüğü',
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
                'Henüz tamamlanan oturum yok',
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
          'Kategori Dengesi',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        _CategoryDonutChart(byCategory: byCategory),
      ],
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 1) return '${diff.inDays}g önce';
    if (diff.inHours >= 1) return '${diff.inHours}s önce';
    return '${diff.inMinutes}dk önce';
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
    final maxY = (days.map((e) => e.value).fold(0, (a, b) => a > b ? a : b) + 1).toDouble();

    return SizedBox(
      height: 120,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.surface,
              getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                  BarTooltipItem(
                '${rod.toY.toInt()}',
                const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 18,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= days.length) return const SizedBox();
                  return Text(
                    days[i].key,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            drawHorizontalLine: true,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: Color(0xFF2A2640),
              strokeWidth: 0.5,
            ),
            drawVerticalLine: false,
          ),
          barGroups: days.asMap().entries.map((entry) {
            final i = entry.key;
            final count = entry.value.value;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: count.toDouble(),
                  width: 18,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  gradient: count > 0
                      ? AppColors.gradientPrimary
                      : const LinearGradient(
                          colors: [Color(0xFF2A2640), Color(0xFF2A2640)],
                        ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Category Donut Chart ──────────────────────────────────────────────────────

class _CategoryDonutChart extends StatelessWidget {
  final List<dynamic> byCategory;
  const _CategoryDonutChart({required this.byCategory});

  @override
  Widget build(BuildContext context) {
    const allCategories = [
      ('Sağlık', 'sağlık'),
      ('Kariyer', 'kariyer'),
      ('Zihinsel', 'zihinsel'),
      ('Öğrenme', 'öğrenme'),
      ('Mindfulness', 'mindfulness'),
      ('Finansal', 'finansal'),
    ];

    final countLookup = <String, int>{};
    final minutesLookup = <String, int>{};
    for (final item in byCategory) {
      final key = (item['category'] as String? ?? '').toLowerCase();
      countLookup[key] = (item['completedCount'] as num?)?.toInt() ?? 0;
      minutesLookup[key] = (item['totalMinutes'] as num?)?.toInt() ?? 0;
    }

    final sections = <PieChartSectionData>[];
    int total = 0;
    for (final cat in allCategories) {
      final count = countLookup[cat.$2] ?? 0;
      if (count > 0) {
        total += count;
        sections.add(PieChartSectionData(
          value: count.toDouble(),
          color: AppTheme.categoryColor(cat.$2),
          radius: 36,
          showTitle: false,
        ));
      }
    }
    if (sections.isEmpty) {
      sections.add(PieChartSectionData(
        value: 1,
        color: const Color(0xFF2A2640),
        radius: 36,
        showTitle: false,
      ));
    }

    return SizedBox(
      height: 140,
      child: Row(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 44,
                    sectionsSpace: 2,
                    startDegreeOffset: -90,
                    pieTouchData: PieTouchData(enabled: false),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$total',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Text(
                      'toplam',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: allCategories.map((cat) {
              final count = countLookup[cat.$2] ?? 0;
              final minutes = minutesLookup[cat.$2] ?? 0;
              final color = AppTheme.categoryColor(cat.$2);
              final timeLabel = minutes == 0
                  ? ''
                  : minutes < 60
                      ? ' · ${minutes}dk'
                      : ' · ${minutes ~/ 60}sa${minutes % 60 > 0 ? ' ${minutes % 60}dk' : ''}';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: count > 0 ? color : color.withOpacity(0.25),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cat.$1,
                      style: TextStyle(
                        color: count > 0 ? AppColors.textSecondary : AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      count > 0 ? '$count$timeLabel' : '—',
                      style: TextStyle(
                        color: count > 0 ? color : AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
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
