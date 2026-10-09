import 'web_icon.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/models.dart';
import 'motion.dart';
import 'theme.dart';
import 'widgets.dart';

String shortAmount(num n) {
  final v = n.abs();
  if (v >= 1000000) {
    return '${(v / 1000000).toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '')}jt';
  }
  if (v >= 1000) {
    return '${(v / 1000).round()}rb';
  }
  return NumberFormat('#,##0.##', 'id_ID').format(v);
}

class WebThemeToggle extends StatelessWidget {
  const WebThemeToggle({
    super.key,
    required this.dark,
    required this.onPressed,
  });
  final bool dark;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    final p = WebPalette.of(context);
    return Tooltip(
      message: dark ? 'Mode terang' : 'Mode gelap',
      child: Semantics(
        button: true,
        toggled: dark,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 50,
            height: 28,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: p.elevated,
              border: Border.all(color: p.border, width: 1.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: AnimatedAlign(
              alignment: dark ? Alignment.centerRight : Alignment.centerLeft,
              duration: TrackerMotion.duration(
                context,
                const Duration(milliseconds: 350),
              ),
              curve: Curves.easeOutBack,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: dark ? p.foreground : p.surface,
                  border: Border.all(color: p.border),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: WebIcon(
                  dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  size: 14,
                  color: dark ? p.onInk : p.foreground,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WebPageHeader extends StatelessWidget implements PreferredSizeWidget {
  const WebPageHeader({
    super.key,
    required this.title,
    this.actions = const [],
    this.leading,
    this.textScale = 1,
  });
  final String title;
  final List<Widget> actions;
  final Widget? leading;
  final double textScale;
  @override
  Size get preferredSize => Size.fromHeight(28 + 52 * textScale);
  @override
  Widget build(BuildContext context) {
    final p = WebPalette.of(context);
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        decoration: BoxDecoration(
          color: p.background,
          border: Border(bottom: BorderSide(color: p.border)),
        ),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 8)],
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, d MMMM', 'id_ID').format(DateTime.now()),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: p.muted,
                      letterSpacing: 0.48,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedSwitcher(
                    duration: TrackerMotion.duration(
                      context,
                      TrackerMotion.quick,
                    ),
                    child: Text(
                      title,
                      key: ValueKey(title),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.66,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...actions,
          ],
        ),
      ),
    );
  }
}

class WebStatStrip extends StatelessWidget {
  const WebStatStrip({super.key, required this.items});
  final List<({String label, double amount, Color? color})> items;
  @override
  Widget build(BuildContext context) {
    final p = WebPalette.of(context);
    final cards = items
        .map(
          (item) => Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: p.surface,
              border: Border.all(color: p.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: p.muted,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: AnimatedAmount(
                    value: item.amount,
                    format: rupiah,
                    style: monoStyle(
                      size: items.length == 3 ? 13 : 17,
                      color: item.color ?? p.foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
    if (MediaQuery.textScalerOf(context).scale(13) > 20) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            cards[i],
          ],
        ],
      );
    }
    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: cards[i]),
        ],
      ],
    );
  }
}

({Color background, Color foreground}) webCategoryColors(
  WebPalette p,
  String category,
) => switch (category) {
  'makanan' || 'hadiah' => (background: p.amberSoft, foreground: p.amber),
  'minuman' => (background: p.emeraldSoft, foreground: p.emerald),
  'transport' => (
    background: p.accent.withValues(alpha: 0.14),
    foreground: p.accent,
  ),
  'belanja' => (background: p.redSoft, foreground: p.red),
  'hiburan' => (
    background: const Color(0x1FA855F7),
    foreground: p.dark ? const Color(0xFFC084FC) : const Color(0xFFA855F7),
  ),
  'gaji' || 'kesehatan' => (background: p.greenSoft, foreground: p.green),
  _ => (background: p.sunken, foreground: p.muted),
};

class WebRecordRow extends StatelessWidget {
  const WebRecordRow({
    super.key,
    required this.record,
    required this.onTap,
    this.recent = false,
  });
  final TrackerRecord record;
  final VoidCallback onTap;
  final bool recent;
  @override
  Widget build(BuildContext context) {
    final p = WebPalette.of(context), income = record.type == 'income';
    final color = income ? p.green : p.red;
    final category = webCategoryColors(p, record.primary);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: recent ? 0 : 16,
          vertical: recent ? 8 : 12,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: p.sunken,
                borderRadius: BorderRadius.circular(8),
              ),
              child: WebIcon(
                income ? Icons.arrow_downward : Icons.arrow_upward,
                size: 16,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          record.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (!record.isCommitted) ...[
                        const SizedBox(width: 6),
                        _badge('Draft', p.amberSoft, p.amber),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  if (recent)
                    Text(
                      _recentDate(record.date),
                      style: TextStyle(fontSize: 11, color: p.muted),
                    )
                  else
                    Wrap(
                      spacing: 5,
                      runSpacing: 3,
                      children: [
                        _badge(
                          record.primary,
                          category.background,
                          category.foreground,
                        ),
                        if (record.secondary.isNotEmpty &&
                            record.secondary != record.primary)
                          _badge(
                            '· ${record.secondary}',
                            category.background,
                            category.foreground,
                          ),
                        Text(
                          DateFormat('HH.mm').format(record.date),
                          style: TextStyle(fontSize: 11, color: p.muted),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${income ? '+' : '−'}${shortAmount(record.amount)}',
              style: monoStyle(color: color),
            ),
          ],
        ),
      ),
    );
  }

  String _recentDate(DateTime date) {
    final now = DateTime.now(),
        today = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        );
    final day = DateTime(date.year, date.month, date.day);
    if (day == today) {
      return 'Hari ini · ${DateFormat('HH.mm').format(date)}';
    }
    if (day == DateTime(now.year, now.month, now.day - 1)) {
      return 'Kemarin · ${DateFormat('HH.mm').format(date)}';
    }
    return DateFormat('d MMM', 'id_ID').format(date);
  }

  Widget _badge(String text, Color bg, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color),
    ),
  );
}
