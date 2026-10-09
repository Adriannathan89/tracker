import '../ui/theme.dart';
import '../ui/web_icon.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_controller.dart';
import '../core/models.dart';
import '../ui/widgets.dart';

class DiscordSheet extends StatefulWidget {
  const DiscordSheet({super.key, required this.controller});
  final AppController controller;
  @override
  State<DiscordSheet> createState() => _DiscordSheetState();
}

class _DiscordSheetState extends State<DiscordSheet>
    with WidgetsBindingObserver {
  Map<String, dynamic>? _code;
  String? _error;
  bool _busy = false, _checking = false;
  Timer? _timer;
  int get _seconds => _code == null
      ? 0
      : DateTime.parse(
          _code!['expiresAt'] as String,
        ).difference(DateTime.now()).inSeconds.clamp(0, 99999).toInt();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _generate();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _code != null && _seconds > 0) {
      _check();
    }
  }

  Future<void> _generate() async {
    _timer?.cancel();
    setState(() {
      _busy = true;
      _error = null;
      _code = null;
    });
    try {
      final result = await widget.controller.api.request(
        'POST',
        'user/discord/verify',
      );
      if (!mounted) {
        return;
      }
      setState(() => _code = object(result));
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {});
        if (_seconds == 0) {
          timer.cancel();
          return;
        }
        if (timer.tick % 5 == 0 &&
            WidgetsBinding.instance.lifecycleState ==
                AppLifecycleState.resumed) {
          _check();
        }
      });
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

  Future<void> _check() async {
    if (_checking || _code == null || _seconds == 0) {
      return;
    }
    setState(() => _checking = true);
    try {
      final result = object(
        await widget.controller.api.request('GET', 'user/discord/status'),
      );
      if (!mounted) {
        return;
      }
      if (result['verified'] == true) {
        _timer?.cancel();
        await widget.controller.reload();
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        setState(() => _error = null);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _checking = false);
      }
    }
  }

  Future<void> _install() async {
    try {
      final uri = Uri.parse(_code!['installUrl'] as String);
      if (uri.scheme != 'https' || uri.host != 'discord.com') {
        throw const FormatException('URL bot tidak valid.');
      }
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw const FormatException('Tidak dapat membuka Discord.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Hubungkan Discord',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              tooltip: 'Tutup',
              onPressed: () => Navigator.pop(context),
              icon: const WebIcon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_busy) const Center(child: CircularProgressIndicator()),
        if (_code != null) ...[
          Text(
            'Install @${_code!['botUsername']}, lalu DM bot dengan perintah ini:',
          ),
          const SizedBox(height: 12),
          SelectableText(
            '/verify ${_code!['code']}',
            style: monoStyle(size: 23, weight: FontWeight.w800),
          ),
          TextButton.icon(
            onPressed: _seconds == 0
                ? null
                : () async {
                    await Clipboard.setData(
                      ClipboardData(text: '/verify ${_code!['code']}'),
                    );
                    if (context.mounted) {
                      toast(context, 'Perintah disalin.');
                    }
                  },
            icon: const WebIcon(Icons.copy),
            label: const Text('Salin perintah'),
          ),
          const SizedBox(height: 8),
          Text(
            _seconds == 0
                ? 'Kode kedaluwarsa. Buat kode baru.'
                : 'Berlaku ${_seconds ~/ 60}:${(_seconds % 60).toString().padLeft(2, '0')} · menunggu verifikasi',
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _install,
            icon: const WebIcon(Icons.open_in_new),
            label: const Text('Install bot Discord'),
          ),
          if (_seconds > 0)
            TextButton(
              onPressed: _checking ? null : _check,
              child: Text(_checking ? 'Memeriksa…' : 'Periksa verifikasi'),
            ),
        ],
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (!_busy && (_code == null || _seconds == 0)) ...[
          const SizedBox(height: 20),
          BusyButton(
            busy: false,
            label: 'Buat kode baru',
            onPressed: _generate,
          ),
        ],
        const SizedBox(height: 24),
      ],
    ),
  );
}
