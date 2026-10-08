import 'package:flutter/material.dart';
import '../core/app_controller.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'record_detail.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.controller, required this.onAdd, required this.onRecords, required this.onFriends});
  final AppController controller;
  final VoidCallback onAdd, onRecords, onFriends;
  @override
  Widget build(BuildContext context) {
    final data = controller.overview;
    final month = DateTime.now();
    final recent = data?.records.where((r) => r.isCommitted).take(5).toList() ?? [];
    return PageBody(controller: controller, children: [
      Text('Halo, ${controller.profile?.username ?? 'kamu'} 👋', style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 6), const Text('Keuanganmu, dalam kendali.', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
      const SizedBox(height: 20), Container(padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: ink, borderRadius: BorderRadius.circular(24)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Saldo Bersih', style: TextStyle(color: Colors.white60, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12), Text(data == null ? '—' : rupiah(data.balance),
            style: const TextStyle(color: lime, fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1)),
          const SizedBox(height: 18), Text(monthLabel(month), style: const TextStyle(color: Colors.white60)),
          const SizedBox(height: 12), SizedBox(height: 58, width: double.infinity,
            child: CustomPaint(painter: _TrendPainter(data?.records.where((r) => r.isCommitted)
              .take(14).toList().reversed.map((r) => r.type == 'income' ? r.amount : -r.amount).toList() ?? []))),
        ])),
      const SizedBox(height: 12), StatCard('Uang tunai', data?.cash ?? 0),
      const SizedBox(height: 12), LayoutBuilder(builder: (context, constraints) {
        final stats = [StatCard('Piutang', data?.receivable ?? 0, color: incomeColor),
          StatCard('Utang', data?.debt ?? 0, color: expenseColor)];
        if (MediaQuery.textScalerOf(context).scale(16) > 23) {
          return Column(children: [stats[0], const SizedBox(height: 12), stats[1]]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: stats[0]),
          const SizedBox(width: 12), Expanded(child: stats[1])]);
      }),
      const SectionTitle('Bulan ini'),
      StatCard('Pemasukan', data?.total('income', month: month) ?? 0, color: incomeColor),
      const SizedBox(height: 12), StatCard('Pengeluaran', data?.total('expense', month: month) ?? 0, color: expenseColor),
      const SectionTitle('Aksi cepat'), Wrap(spacing: 10, runSpacing: 10, children: [
        FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Catat transaksi')),
        OutlinedButton.icon(onPressed: onFriends, icon: const Icon(Icons.people_outline), label: const Text('Utang teman')),
      ]),
      SectionTitle('Catatan terbaru', action: TextButton(onPressed: onRecords, child: const Text('Lihat semua'))),
      if (recent.isEmpty) const EmptyCard(title: 'Belum ada transaksi', message: 'Tambahkan catatan, lalu konfirmasi kategorinya.')
      else ...recent.map((r) => RecordTile(r, onTap: () => openRecord(context, controller, r))),
      const SectionTitle('Sedikit pengingat'), const Card(child: Padding(padding: EdgeInsets.all(20),
        child: Text('Catat setiap transaksi dan konfirmasi kategori AI agar saldo dan ringkasanmu selalu akurat.'))),
    ]);
  }
}
class _TrendPainter extends CustomPainter {
  _TrendPainter(this.changes);
  final List<double> changes;
  @override
  void paint(Canvas canvas, Size size) {
    if (changes.length < 2) return;
    var value = 0.0;
    final values = changes.map((d) => value += d).toList();
    final min = values.reduce((a, b) => a < b ? a : b), max = values.reduce((a, b) => a > b ? a : b);
    final span = max == min ? 1.0 : max - min;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = i / (values.length - 1) * size.width;
      final y = size.height - 5 - (values[i] - min) / span * (size.height - 10);
      if (i == 0) { path.moveTo(x, y); } else { path.lineTo(x, y); }
    }
    canvas.drawPath(path, Paint()..color = lime..strokeWidth = 2.5..style = PaintingStyle.stroke);
  }
  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) => true;
}
