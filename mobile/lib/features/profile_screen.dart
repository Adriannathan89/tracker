import 'dart:collection';
import 'package:flutter/material.dart';
import '../core/app_controller.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'discord_sheet.dart';
import 'rename_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.controller});
  final AppController controller;
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}
class _ProfileScreenState extends State<ProfileScreen> {
  bool _busy = false;
  String? _error;
  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() { _busy = true; _error = null; });
    try { await action(); }
    catch (e) { if (mounted) setState(() => _error = e.toString()); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _rename() async {
    final username = await showDialog<String>(context: context,
      builder: (_) => RenameDialog(username: widget.controller.profile?.username ?? ''));
    if (username != null && mounted) await _run(() => widget.controller.mutate('PUT', 'user/profile', body: {'username': username}));
  }
  @override
  Widget build(BuildContext context) {
    final c = widget.controller, p = c.profile;
    return PageBody(controller: c, children: [
      Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
        CircleAvatar(radius: 34, backgroundColor: lime, foregroundColor: ink,
          child: Text(p?.username.characters.firstOrNull?.toUpperCase() ?? '?', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800))),
        const SizedBox(height: 14), Text(p?.username ?? 'Memuat profil', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10), OutlinedButton.icon(onPressed: _busy || p == null ? null : _rename,
          icon: const Icon(Icons.edit_outlined), label: const Text('Ubah username')),
      ]))),
      const SectionTitle('Tampilan'), Card(child: SwitchListTile(title: const Text('Mode gelap'),
        subtitle: const Text('Warna hangat, nyaman di malam hari'), value: c.dark,
        onChanged: _busy ? null : (_) => _run(c.toggleTheme))),
      const SectionTitle('Discord'), Card(child: Padding(padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const Icon(Icons.chat_bubble_outline), const SizedBox(width: 12), Expanded(child: Text(
            p?.connected == true ? '@${p!.discord['username']}' : 'Hubungkan akun Discord', style: const TextStyle(fontWeight: FontWeight.w700)))]),
          const SizedBox(height: 12), const Text('Terima pemberitahuan transaksi dan laporan mingguan melalui bot Tracker.'),
          if (p?.connected == true) ...[
            const SizedBox(height: 12), SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Notifikasi catatan'),
              value: p!.discord['commitNotifEnabled'] == true,
              onChanged: _busy ? null : (v) => _run(() => c.mutate('PUT', 'user/discord/notification', body: {'type': 'commit', 'enabled': v}))),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Laporan mingguan'),
              value: p.discord['weeklyNotifEnabled'] == true,
              onChanged: _busy ? null : (v) => _run(() => c.mutate('PUT', 'user/discord/notification', body: {'type': 'weekly', 'enabled': v}))),
            TextButton(onPressed: _busy ? null : () async {
              if (await confirm(context, 'Putuskan Discord?', 'Notifikasi ke akun Discord ini akan dihentikan.') && mounted) {
                await _run(() => c.mutate('DELETE', 'user/discord'));
              }
            }, child: const Text('Putuskan koneksi')),
          ] else ...[const SizedBox(height: 20), FilledButton.icon(onPressed: _busy ? null : () => showModalBottomSheet<void>(
            context: context, useSafeArea: true, isScrollControlled: true, builder: (_) => DiscordSheet(controller: c)),
            icon: const Icon(Icons.link), label: const Text('Hubungkan Discord'))],
        ]))),
      if (_busy) const Padding(padding: EdgeInsets.only(top: 16), child: LinearProgressIndicator()),
      if (_error != null) Padding(padding: const EdgeInsets.only(top: 16),
        child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
      const SectionTitle('Akun'), OutlinedButton.icon(onPressed: _busy ? null : () async {
        if (await confirm(context, 'Keluar dari Tracker?', 'Session pada perangkat ini akan dihapus.') && mounted) {
          await _run(c.logout);
        }
      }, icon: const Icon(Icons.logout), label: const Text('Keluar')),
      const SizedBox(height: 24), const Center(child: Text('Tracker · 1.0.0', style: TextStyle(fontSize: 12))),
    ]);
  }
}
