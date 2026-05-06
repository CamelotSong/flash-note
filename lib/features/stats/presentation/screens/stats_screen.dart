import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_theme.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  List<Note> _allNotes = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = ref.read(appDatabaseProvider);
    final notes = await db.searchNotes('');
    setState(() {
      _allNotes = notes;
      _loaded = true;
    });
  }

  int get _thisWeekCount {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    return _allNotes.where((n) => n.createdAt.isAfter(monday)).length;
  }

  Map<String, int> get _typeCounts {
    final counts = <String, int>{};
    for (final n in _allNotes) {
      counts[n.type] = (counts[n.type] ?? 0) + 1;
    }
    return counts;
  }

  int get _analyzedCount => _allNotes.where((n) => n.analyzed).length;

  List<MapEntry<String, int>> get _topTags {
    final counts = <String, int>{};
    for (final n in _allNotes) {
      if (n.tags?.isNotEmpty == true) {
        for (final t in n.tags!.split(',')) {
          final tag = t.trim();
          if (tag.isNotEmpty) counts[tag] = (counts[tag] ?? 0) + 1;
        }
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/');
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => context.go('/')),
          title: const Text('统计'),
        ),
        body: _loaded
            ? _buildBody()
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildBody() {
    final total = _allNotes.length;
    final analyzed = _analyzedCount;
    final types = _typeCounts;
    final analyzeRatio = total == 0 ? 0.0 : analyzed / total;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── 本周 + 总计 ──────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: '本周新增',
                value: _thisWeekCount,
                icon: Icons.trending_up_outlined,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: '全部笔记',
                value: total,
                icon: Icons.notes_outlined,
                color: AppTheme.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ── 类型分布 ─────────────────────────────────────────
        _SectionTitle(title: '📊 类型分布'),
        const SizedBox(height: 12),
        _TypeDistribution(types: types, total: total),
        const SizedBox(height: 20),

        // ── AI 分析覆盖率 ─────────────────────────────────────
        _SectionTitle(title: '🤖 AI 分析覆盖率'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '已分析 $analyzed / 全部 $total',
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  Text(
                    '${(analyzeRatio * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accent),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: analyzeRatio,
                backgroundColor: AppTheme.textSecondary.withValues(alpha: 0.2),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppTheme.accent),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── 热门标签 TOP5 ─────────────────────────────────────
        _SectionTitle(title: '🏷️ 热门标签 TOP5'),
        const SizedBox(height: 12),
        _topTags.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: Text('暂无标签数据',
                    style: TextStyle(color: AppTheme.textSecondary)),
              )
            : Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: _topTags.asMap().entries.map((entry) {
                    final i = entry.key;
                    final tag = entry.value;
                    final maxCount =
                        _topTags.isNotEmpty ? _topTags.first.value : 1;
                    final ratio = maxCount == 0 ? 0.0 : tag.value / maxCount;
                    return _TagRankItem(
                      rank: i + 1,
                      tag: tag.key,
                      count: tag.value,
                      ratio: ratio,
                      isLast: i == _topTags.length - 1,
                    );
                  }).toList(),
                ),
              ),
      ],
    );
  }
}

// ── 统计卡片 ──────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          top: BorderSide(color: color, width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: TextStyle(
                fontSize: 36, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

// ── 类型分布 ──────────────────────────────────────────────────

class _TypeDistribution extends StatelessWidget {
  final Map<String, int> types;
  final int total;

  const _TypeDistribution({required this.types, required this.total});

  static const _typeOrder = ['voice', 'text', 'meeting', 'conversation'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: _typeOrder.map((type) {
          final count = types[type] ?? 0;
          final ratio = total == 0 ? 0.0 : count / total;
          final color = AppTheme.typeColor(type);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Row(
                    children: [
                      Icon(AppTheme.typeIcon(type), size: 14, color: color),
                      const SizedBox(width: 4),
                      Text(AppTheme.typeLabel(type),
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 16,
                        decoration: BoxDecoration(
                          color:
                              AppTheme.textSecondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: ratio.clamp(0.0, 1.0),
                        child: Container(
                          height: 16,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 40,
                  child: Text(
                    '$count (${(ratio * 100).toStringAsFixed(0)}%)',
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── 标签排名条目 ──────────────────────────────────────────────

class _TagRankItem extends StatelessWidget {
  final int rank;
  final String tag;
  final int count;
  final double ratio;
  final bool isLast;

  const _TagRankItem({
    required this.rank,
    required this.tag,
    required this.count,
    required this.ratio,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: rank <= 3
                      ? AppTheme.accent.withValues(alpha: 0.2)
                      : AppTheme.textSecondary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$rank',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: rank <= 3
                          ? AppTheme.accent
                          : AppTheme.textSecondary),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text('#$tag',
                    style: const TextStyle(fontSize: 14, color: Colors.white)),
              ),
              const SizedBox(width: 8),
              // Mini bar
              SizedBox(
                width: 80,
                height: 6,
                child: Stack(
                  children: [
                    Container(
                        decoration: BoxDecoration(
                            color: AppTheme.textSecondary
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(3))),
                    FractionallySizedBox(
                      widthFactor: ratio,
                      child: Container(
                          decoration: BoxDecoration(
                              color: AppTheme.accent,
                              borderRadius: BorderRadius.circular(3))),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('$count 次',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
        ),
        if (!isLast)
          Divider(
              height: 1,
              color: AppTheme.textSecondary.withValues(alpha: 0.1),
              indent: 16,
              endIndent: 16),
      ],
    );
  }
}

// ── Section Title ─────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white));
  }
}
