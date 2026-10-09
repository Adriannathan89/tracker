import 'ui/web_icon.dart';
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
import 'ui/motion.dart';
import 'ui/frontend_widgets.dart';

class TrackerApp extends StatelessWidget {
  const TrackerApp({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => MaterialApp(
      // A session transition also closes any protected form/sheet route.
      key: ValueKey(controller.state),
      title: 'Tracker',
      debugShowCheckedModeBanner: false,
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: trackerTheme(false),
      darkTheme: trackerTheme(true),
      themeAnimationDuration: TrackerMotion.duration(
        context,
        TrackerMotion.entrance,
      ),
      themeAnimationCurve: Curves.easeOutCubic,
      themeMode: controller.dark ? ThemeMode.dark : ThemeMode.light,
      home: switch (controller.state) {
        SessionState.signedOut => AuthScreen(controller: controller),
        SessionState.signedIn => TrackerShell(controller: controller),
        SessionState.starting => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        SessionState.unavailable => Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const WebIcon(Icons.wifi_off_outlined, size: 44),
                    const SizedBox(height: 20),
                    const Text(
                      'Belum dapat terhubung',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      controller.error ?? 'Periksa koneksi internet.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: controller.start,
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      },
    ),
  );
}

class TrackerShell extends StatefulWidget {
  const TrackerShell({super.key, required this.controller});
  final AppController controller;
  @override
  State<TrackerShell> createState() => _TrackerShellState();
}

class _TrackerShellState extends State<TrackerShell> {
  int _tab = 0, _returnTab = 0;
  bool _addingBusy = false;
  static const _labels = ['Beranda', 'Catatan', 'Teman', 'Saya'];
  void _select(int value) {
    if (_addingBusy) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _tab = value);
  }

  void _add() {
    if (_addingBusy || _tab == 4) {
      return;
    }
    _returnTab = _tab;
    _select(4);
  }

  void _finishAdd(Object? result) {
    if (!mounted) {
      return;
    }
    _addingBusy = false;
    _select(
      result == true
          ? 1
          : result == 'friends'
          ? 2
          : _returnTab,
    );
    if (result == true) {
      toast(
        context,
        'Catatan tersimpan. Periksa kategori AI dan konfirmasi draft.',
      );
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _tab != 4,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && _tab == 4 && !_addingBusy) {
        _finishAdd(null);
      }
    },
    child: Scaffold(
      appBar: WebPageHeader(
        textScale: MediaQuery.textScalerOf(context).scale(12) / 12,
        title: const [
          'Home',
          'Transaksi',
          'Teman',
          'tracker',
          'Catat Transaksi',
        ][_tab],
        actions: [
          WebThemeToggle(
            dark: widget.controller.dark,
            onPressed: () async {
              try {
                await widget.controller.toggleTheme();
              } catch (e) {
                if (context.mounted) {
                  toast(context, e.toString());
                }
              }
            },
          ),
          const SizedBox(width: 8),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: WebPalette.of(context).surface,
              border: Border.all(color: WebPalette.of(context).border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              tooltip: 'Notifikasi',
              iconSize: 20,
              onPressed: () => _select(3),
              icon: const WebIcon(Icons.notifications_outlined),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: WebPalette.of(context).accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () => _select(3),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                foregroundColor: ink,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  (widget.controller.profile?.username ?? '?').characters
                      .take(2)
                      .toString()
                      .toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: MotionTabs(
              index: _tab,
              children: [
                DashboardScreen(
                  controller: widget.controller,
                  onAdd: _add,
                  onRecords: () => _select(1),
                  onFriends: () => _select(2),
                ),
                RecordsScreen(controller: widget.controller),
                FriendsScreen(controller: widget.controller),
                ProfileScreen(controller: widget.controller),
                if (_tab == 4)
                  AddRecordScreen(
                    controller: widget.controller,
                    onFinish: _finishAdd,
                    onBusyChanged: (busy) {
                      if (mounted && _tab == 4) {
                        setState(() => _addingBusy = busy);
                      }
                    },
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: WebPalette.of(context).border)),
        ),
        child: BottomAppBar(
          color: WebPalette.of(context).surface,
          surfaceTintColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          height: 72,
          child: Row(
            children: [
              _nav(0, Icons.home_outlined),
              _nav(1, Icons.receipt_long_outlined),
              Expanded(
                child: Center(
                  child: SizedBox.square(
                    dimension: 56,
                    child: Tooltip(
                      message: 'Tambah catatan',
                      child: FilledButton(
                        onPressed: _addingBusy ? null : _add,
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: WebPalette.of(context).foreground,
                          foregroundColor: WebPalette.of(context).accent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const WebIcon(
                          Icons.add,
                          size: 28,
                          strokeWidth: 2.4,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _nav(2, Icons.people_outline),
              _nav(3, Icons.account_balance_wallet_outlined),
            ],
          ),
        ),
      ),
    ),
  );
  Widget _nav(int index, IconData icon) => Expanded(
    child: Tooltip(
      message: _labels[index],
      child: InkWell(
        onTap: _addingBusy ? null : () => _select(index),
        borderRadius: BorderRadius.circular(16),
        child: Semantics(
          selected: _tab == index,
          button: true,
          child: AnimatedContainer(
            duration: TrackerMotion.duration(context, TrackerMotion.quick),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.transparent,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                WebIcon(
                  icon,
                  size: 22,
                  color: _tab == index
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 4),
                Text(
                  index == 0 ? 'Home' : _labels[index],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: _tab == index
                        ? FontWeight.w800
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
