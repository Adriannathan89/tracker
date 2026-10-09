import '../ui/web_icon.dart';
import 'package:flutter/material.dart';
import '../core/app_controller.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'record_detail.dart';
import '../ui/motion.dart';
import '../ui/frontend_widgets.dart';
import 'package:flutter/foundation.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.controller,
    required this.onAdd,
    required this.onRecords,
    required this.onFriends,
  });
  final AppController controller;
  final VoidCallback onAdd, onRecords, onFriends;
  @override
  Widget build(BuildContext context) {
    final data = controller.overview, p = WebPalette.of(context);
    final now = DateTime.now();
    final recent =
        data?.records.where((r) => r.isCommitted).take(5).toList() ?? [];
    final spark = List.generate(7, (i) {
      final month = DateTime(now.year, now.month - (6 - i));
      final net =
          (data?.total('income', month: month) ?? 0) -
          (data?.total('expense', month: month) ?? 0);
      return net > 0 ? net / 1000000 : 0.0;
    });
    final previous = spark[5], current = spark[6];
    final pct = previous == 0
        ? (current > 0 ? 100.0 : 0.0)
        : (current - previous) / previous * 100;
    final trend =
        '${pct > 0 ? '+' : ''}${pct.toStringAsFixed(previous == 0 ? 0 : 1)}%${previous == 0 ? '' : ' bulan ini'}';
    return PageBody(
      controller: controller,
      children: [
        MotionEntrance(
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: p.hero,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Saldo Bersih',
                    style: TextStyle(
                      color: Color(0x7AF0EFE9),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Rp ',
                          style: monoStyle(
                            size: 42,
                            color: const Color(0xFFF0EFE9),
                          ),
                        ),
                        AnimatedAmount(
                          value: data?.balance ?? 0,
                          format: (n) => rupiah(n).substring(3),
                          style: monoStyle(size: 42, color: p.accent),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: p.accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        WebIcon(Icons.arrow_upward, size: 12, color: p.accent),
                        const SizedBox(width: 5),
                        Text(
                          trend,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: p.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 60,
                    width: double.infinity,
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _TrendPainter(spark, p.accent),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        WebStatStrip(
          items: [
            (label: 'Tunai', amount: data?.cash ?? 0.0, color: null),
            (label: 'Piutang', amount: data?.receivable ?? 0.0, color: null),
            (label: 'Hutang', amount: data?.debt ?? 0.0, color: null),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _quick(context, 'Tambah', Icons.add, onAdd)),
            const SizedBox(width: 8),
            Expanded(
              child: _quick(context, 'Tagih', Icons.people_outline, onFriends),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _quick(
                context,
                'Split',
                Icons.receipt_long_outlined,
                onFriends,
                accent: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Transaksi terakhir',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: onRecords,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Semua'),
                          SizedBox(width: 4),
                          WebIcon(Icons.arrow_forward, size: 12),
                        ],
                      ),
                    ),
                  ],
                ),
                if (recent.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Belum ada transaksi',
                      style: TextStyle(fontSize: 13, color: p.muted),
                    ),
                  )
                else
                  for (var i = 0; i < recent.length; i++) ...[
                    if (i > 0) const Divider(),
                    WebRecordRow(
                      record: recent[i],
                      recent: true,
                      onTap: () => openRecord(context, controller, recent[i]),
                    ),
                  ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _quick(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback action, {
    bool accent = true,
  }) {
    final p = WebPalette.of(context);
    return Material(
      color: p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: p.border),
      ),
      child: InkWell(
        onTap: action,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent ? p.limeSoft : p.sunken,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: WebIcon(
                  icon,
                  size: 16,
                  color: accent ? p.limeInk : p.secondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: p.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.changes, this.color);
  final Color color;
  final List<double> changes;
  @override
  void paint(Canvas canvas, Size size) {
    if (changes.length < 2) {
      return;
    }
    final values = changes;
    final min = values.reduce((a, b) => a < b ? a : b),
        max = values.reduce((a, b) => a > b ? a : b);
    final span = max == min ? 1.0 : max - min;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = i / (values.length - 1) * size.width;
      final y = size.height - 6 - (values[i] - min) / span * (size.height - 12);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final area = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      !listEquals(changes, oldDelegate.changes) || color != oldDelegate.color;
}
