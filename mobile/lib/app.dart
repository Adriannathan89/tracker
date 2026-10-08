import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/app_controller.dart';
import 'features/add_record_screen.dart';
import 'features/auth_screen.dart';
import 'features/dashboard_screen.dart';
import 'features/friends_screen.dart';
import 'features/profile_screen.dart';
import 'features/records_screen.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

class TrackerApp extends StatelessWidget {
  const TrackerApp({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: controller,
    builder: (context, _) => MaterialApp(
      // A session transition also closes any protected form/sheet route.
      key: ValueKey(controller.state), title: 'Tracker', debugShowCheckedModeBanner: false,
      locale: const Locale('id', 'ID'), supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: trackerTheme(false), darkTheme: trackerTheme(true),
      themeMode: controller.dark ? ThemeMode.dark : ThemeMode.light,
      home: switch (controller.state) {
        SessionState.signedOut => AuthScreen(controller: controller),
        SessionState.signedIn => TrackerShell(controller: controller),
        SessionState.starting => const Scaffold(body: Center(child: CircularProgressIndicator())),
        SessionState.unavailable => Scaffold(body: SafeArea(child: Center(child: Padding(
          padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.wifi_off_outlined, size: 44), const SizedBox(height: 20),
            const Text('Belum dapat terhubung', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12), Text(controller.error ?? 'Periksa koneksi internet.', textAlign: TextAlign.center),
            const SizedBox(height: 24), FilledButton(onPressed: controller.start, child: const Text('Coba lagi')),
          ]))))),
      },
    ));
}
class TrackerShell extends StatefulWidget {
  const TrackerShell({super.key, required this.controller});
  final AppController controller;
  @override
  State<TrackerShell> createState() => _TrackerShellState();
}
class _TrackerShellState extends State<TrackerShell> {
  int _tab = 0;
  static const _labels = ['Beranda', 'Catatan', 'Teman', 'Saya'];
  void _select(int value) => setState(() => _tab = value);
  Future<void> _add() async {
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => AddRecordScreen(controller: widget.controller)));
    if (saved == true && mounted) {
      _select(1); toast(context, 'Catatan tersimpan. Periksa kategori AI dan konfirmasi draft.');
    }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_labels[_tab]), actions: [
      IconButton(tooltip: widget.controller.dark ? 'Mode terang' : 'Mode gelap',
        onPressed: () async {
          try { await widget.controller.toggleTheme(); }
          catch (e) { if (context.mounted) toast(context, e.toString()); }
        }, icon: Icon(widget.controller.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined)),
    ]),
    body: SafeArea(top: false, child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760),
      child: IndexedStack(index: _tab, children: [
        DashboardScreen(controller: widget.controller, onAdd: _add, onRecords: () => _select(1), onFriends: () => _select(2)),
        RecordsScreen(controller: widget.controller), FriendsScreen(controller: widget.controller), ProfileScreen(controller: widget.controller),
      ])))),
    floatingActionButton: FloatingActionButton(tooltip: 'Tambah catatan', onPressed: _add, child: const Icon(Icons.add, size: 28)),
    floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    bottomNavigationBar: BottomAppBar(shape: const CircularNotchedRectangle(), notchMargin: 8,
      padding: const EdgeInsets.symmetric(horizontal: 6), height: 72,
      child: Row(children: [
        _nav(0, Icons.grid_view_outlined), _nav(1, Icons.receipt_long_outlined),
        const SizedBox(width: 64), _nav(2, Icons.people_outline), _nav(3, Icons.person_outline),
      ])),
  );
  Widget _nav(int index, IconData icon) => Expanded(child: Tooltip(message: _labels[index],
    child: InkWell(onTap: () => _select(index), borderRadius: BorderRadius.circular(16),
      child: Semantics(selected: _tab == index, button: true, child: Padding(padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: _tab == index ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 4), Text(_labels[index], maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, fontWeight: _tab == index ? FontWeight.w800 : FontWeight.w500)),
        ]))))));
}
