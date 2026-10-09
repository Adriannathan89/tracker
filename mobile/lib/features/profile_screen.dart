import '../ui/web_icon.dart';
import 'dart:collection';
import 'package:flutter/material.dart';
import '../core/app_controller.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'discord_sheet.dart';
import 'rename_dialog.dart';
import '../ui/motion.dart';

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
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _rename() async {
    final username = await showDialog<String>(
      context: context,
      builder: (_) =>
          RenameDialog(username: widget.controller.profile?.username ?? ''),
    );
    if (username != null && mounted) {
      await _run(
        () => widget.controller.mutate(
          'PUT',
          'user/profile',
          body: {'username': username},
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller, p = c.profile;
    return PageBody(
      controller: c,
      children: [
        const Text(
          'Profile',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.88,
          ),
        ),
        const SizedBox(height: 18),
        Card(
          color: WebPalette.of(context).elevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: WebPalette.of(context).border),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: WebPalette.of(context).foreground,
                      foregroundColor: WebPalette.of(context).onInk,
                      child: Text(
                        p?.username.characters.firstOrNull?.toUpperCase() ??
                            '?',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p?.username ?? 'Memuat profil',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.36,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Anggota tracker',
                            style: TextStyle(
                              fontSize: 12,
                              color: WebPalette.of(context).muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _busy || p == null ? null : _rename,
                  icon: const WebIcon(Icons.edit_outlined, size: 14),
                  label: const Text('Ubah username'),
                ),
              ],
            ),
          ),
        ),
        const SectionTitle('Tampilan'),
        Card(
          child: SwitchListTile(
            title: const Text('Mode gelap'),
            subtitle: const Text('Warna hangat, nyaman di malam hari'),
            value: c.dark,
            onChanged: _busy ? null : (_) => _run(c.toggleTheme),
          ),
        ),
        const SectionTitle('Discord'),
        Card(
          color: WebPalette.of(context).elevated,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    WebIcon(
                      Icons.chat_bubble_outline,
                      color: WebPalette.of(context).emerald,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        p?.connected == true
                            ? '@${p!.discord['username']}'
                            : 'Hubungkan akun Discord',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Terima pemberitahuan transaksi dan laporan mingguan melalui bot Tracker.',
                ),
                if (p?.connected == true) ...[
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Notifikasi catatan'),
                    value: p!.discord['commitNotifEnabled'] == true,
                    onChanged: _busy
                        ? null
                        : (v) => _run(
                            () => c.mutate(
                              'PUT',
                              'user/discord/notification',
                              body: {'type': 'commit', 'enabled': v},
                            ),
                          ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Laporan mingguan'),
                    value: p.discord['weeklyNotifEnabled'] == true,
                    onChanged: _busy
                        ? null
                        : (v) => _run(
                            () => c.mutate(
                              'PUT',
                              'user/discord/notification',
                              body: {'type': 'weekly', 'enabled': v},
                            ),
                          ),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () async {
                            if (await confirm(
                                  context,
                                  'Putuskan Discord?',
                                  'Notifikasi ke akun Discord ini akan dihentikan.',
                                ) &&
                                mounted) {
                              await _run(
                                () => c.mutate('DELETE', 'user/discord'),
                              );
                            }
                          },
                    child: const Text('Putuskan koneksi'),
                  ),
                ] else ...[
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () => showModalBottomSheet<void>(
                            context: context,
                            useSafeArea: true,
                            isScrollControlled: true,
                            sheetAnimationStyle: AnimationStyle(
                              duration: TrackerMotion.duration(
                                context,
                                TrackerMotion.entrance,
                              ),
                              reverseDuration: TrackerMotion.duration(
                                context,
                                TrackerMotion.quick,
                              ),
                            ),
                            builder: (_) => DiscordSheet(controller: c),
                          ),
                    icon: const WebIcon(Icons.link),
                    label: const Text('Hubungkan Discord'),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_busy)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: LinearProgressIndicator(),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SectionTitle('Akun'),
        OutlinedButton.icon(
          onPressed: _busy
              ? null
              : () async {
                  if (await confirm(
                        context,
                        'Keluar dari Tracker?',
                        'Session pada perangkat ini akan dihapus.',
                      ) &&
                      mounted) {
                    await _run(c.logout);
                  }
                },
          icon: const WebIcon(Icons.logout),
          label: const Text('Keluar'),
        ),
        const SizedBox(height: 24),
        const Center(
          child: Text('Tracker · 1.0.0', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}
