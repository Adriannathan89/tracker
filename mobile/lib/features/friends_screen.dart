import '../ui/web_icon.dart';
import 'dart:collection';
import 'package:flutter/material.dart';
import '../core/app_controller.dart';
import '../core/models.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'add_debt_sheet.dart';
import '../ui/motion.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key, required this.controller});
  final AppController controller;
  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _search = TextEditingController();
  List<Friend>? _results;
  String? _error;
  bool _searching = false, _busy = false;
  int _searchRevision = 0;
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _find() async {
    if (_search.text.trim().isEmpty) {
      setState(() => _results = null);
      return;
    }
    final revision = ++_searchRevision;
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final result = await widget.controller.api.request(
        'POST',
        'user/friend/search',
        body: {'name': _search.text.trim()},
      );
      if (mounted && revision == _searchRevision) {
        setState(
          () => _results = objects(result).map(Friend.fromJson).toList(),
        );
      }
    } catch (e) {
      if (mounted && revision == _searchRevision) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted && revision == _searchRevision) {
        setState(() => _searching = false);
      }
    }
  }

  Future<void> _action(
    String method,
    String path,
    Object body,
    String message,
  ) async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.controller.mutate(method, path, body: body);
      if (mounted) {
        toast(context, message);
        if (_results != null) {
          await _find();
        }
      }
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

  Future<void> _pay(Debt d) async {
    if (!await confirm(
      context,
      'Konfirmasi pembayaran',
      'Tandai utang ${rupiah(d.amount)} kepada ${d.owner} sebagai lunas? Saldo kedua akun akan diperbarui.',
    )) {
      return;
    }
    if (!mounted) {
      return;
    }
    await _action('PUT', 'debt/finish', {
      'debtId': d.id,
    }, 'Utang berhasil dilunasi.');
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final incoming = c.requests
        .where((r) => r.receiverId == c.profile?.id)
        .toList();
    final p = WebPalette.of(context);
    final owned = c.owned
        .where((d) => d.pending)
        .fold(0.0, (sum, d) => sum + d.amount);
    final owed = c.owed
        .where((d) => d.pending)
        .fold(0.0, (sum, d) => sum + d.amount);
    final friends = c.friends
        .where(
          (f) => f.username.toLowerCase().contains(
            _search.text.trim().toLowerCase(),
          ),
        )
        .toList();
    return PageBody(
      controller: c,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        const Text(
          'Teman',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          maxLength: 50,
          decoration: InputDecoration(
            hintText: 'Cari teman...',
            counterText: '',
            suffixIcon: IconButton(
              tooltip: 'Bersihkan pencarian',
              onPressed: () {
                _searchRevision++;
                _search.clear();
                setState(() {
                  _results = null;
                  _searching = false;
                  _error = null;
                });
              },
              icon: const WebIcon(Icons.close, size: 18),
            ),
          ),
          onSubmitted: (_) => _find(),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _searching ? null : _find,
            child: Text(_searching ? 'Mencari...' : 'Cari pengguna'),
          ),
        ),
        if (_error != null) Text(_error!, style: TextStyle(color: p.red)),
        if (_busy) const LinearProgressIndicator(),
        if (_results != null) ...[
          const SectionTitle('Hasil pencarian'),
          if (_results!.isEmpty) const Text('Pengguna tidak ditemukan'),
          ..._results!.map((f) {
            final incomingRequest = incoming
                .where((r) => r.senderId == f.id)
                .firstOrNull;
            final accepted =
                c.friends.any((friend) => friend.id == f.id) ||
                f.status == 'accepted';
            return Card(
              child: ListTile(
                leading: _avatar(f.username),
                title: Text(f.username),
                subtitle: Text(
                  accepted
                      ? 'Sudah berteman'
                      : incomingRequest != null
                      ? 'Permintaan masuk'
                      : f.status == 'pending'
                      ? 'Permintaan terkirim'
                      : 'Belum berteman',
                ),
                trailing:
                    !accepted &&
                        incomingRequest == null &&
                        f.status != 'pending'
                    ? IconButton(
                        tooltip: 'Tambah ${f.username}',
                        onPressed: _busy
                            ? null
                            : () => _action('POST', 'user/friend/add', {
                                'friendId': f.id,
                              }, 'Permintaan pertemanan terkirim.'),
                        icon: const WebIcon(Icons.person_add_outlined),
                      )
                    : null,
              ),
            );
          }),
          const SizedBox(height: 16),
        ],
        if (incoming.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: p.limeSoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${incoming.length} Permintaan Pertemanan',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: p.limeInk,
                  ),
                ),
                for (final r in incoming)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        _avatar(r.sender),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            r.sender,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: p.limeInk,
                            ),
                          ),
                        ),
                        FilledButton(
                          onPressed: _busy
                              ? null
                              : () => _action(
                                  'PUT',
                                  'user/friend/request/response',
                                  {'friendRequestId': r.id, 'action': 'accept'},
                                  'Permintaan diterima.',
                                ),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(48, 40),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            textStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: const Text('Terima'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () => _action(
                                  'PUT',
                                  'user/friend/request/response',
                                  {'friendRequestId': r.id, 'action': 'reject'},
                                  'Permintaan ditolak.',
                                ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(48, 40),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            textStyle: const TextStyle(fontSize: 11),
                          ),
                          child: const Text('Tolak'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Tooltip(
          message: 'Rincian saldo teman',
          child: InkWell(
            onTap: () => _showDebts(),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: p.foreground,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saldo Bersih',
                    style: TextStyle(
                      fontSize: 12,
                      color: p.onInk.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${owned - owed >= 0 ? '+' : '−'}${rupiah((owned - owed).abs())}',
                    style: monoStyle(
                      size: 22,
                      color: owned - owed >= 0 ? p.green : p.red,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _summary('Piutang', owned, p.green, p),
                      const SizedBox(width: 24),
                      _summary('Hutang', owed, p.red, p),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (friends.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Text(
                'Belum ada teman',
                style: TextStyle(fontSize: 14, color: p.muted),
              ),
            ),
          )
        else
          ...friends.map((f) => _friend(context, f)),
      ],
    );
  }

  Widget _summary(String label, double value, Color color, WebPalette p) =>
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: p.onInk.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(rupiah(value), style: monoStyle(color: color)),
            ),
          ],
        ),
      );
  Widget _friend(BuildContext context, Friend f) {
    final c = widget.controller, p = WebPalette.of(context);
    final balance = c.friendReceivable(f.id) - c.friendDebt(f.id);
    final debt = c.owed
        .where(
          (d) => d.pending && d.ownerId == f.id && d.debtorId == c.profile?.id,
        )
        .firstOrNull;
    final actions = Wrap(
      spacing: 8,
      children: [
        if (debt != null)
          OutlinedButton(
            onPressed: _busy
                ? null
                : () {
                    final pending = c.owed
                        .where(
                          (d) =>
                              d.pending &&
                              d.ownerId == f.id &&
                              d.debtorId == c.profile?.id,
                        )
                        .toList();
                    if (pending.length == 1) {
                      _pay(pending.single);
                    } else {
                      _showDebts(friend: f);
                    }
                  },
            style: OutlinedButton.styleFrom(
              foregroundColor: p.red,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(48, 40),
            ),
            child: const Text('Bayar'),
          ),
        Tooltip(
          message: 'Tambah piutang',
          child: OutlinedButton(
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
                    builder: (_) => AddDebtSheet(controller: c, friend: f),
                  ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(48, 40),
            ),
            child: const Text('+ Hutang'),
          ),
        ),
      ],
    );
    final identity = Tooltip(
      message: 'Rincian ${f.username}',
      child: InkWell(
        onTap: () => _showDebts(friend: f),
        child: Row(
          children: [
            _avatar(f.username),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    f.username,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${balance >= 0 ? '+' : '−'}${rupiah(balance.abs())}',
                    style: monoStyle(
                      size: 12,
                      color: balance >= 0 ? p.green : p.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: p.surface,
          border: Border.all(color: p.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) =>
              constraints.maxWidth < 340 ||
                  MediaQuery.textScalerOf(context).scale(13) > 18
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [identity, const SizedBox(height: 8), actions],
                )
              : Row(
                  children: [
                    Expanded(child: identity),
                    const SizedBox(width: 8),
                    actions,
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _showDebts({Friend? friend}) async {
    if (_busy) {
      return;
    }
    final c = widget.controller;
    final owed = c.owed
        .where((d) => d.pending && (friend == null || d.ownerId == friend.id))
        .toList();
    final owned = c.owned
        .where((d) => d.pending && (friend == null || d.debtorId == friend.id))
        .toList();
    final selected = await showModalBottomSheet<Debt>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      sheetAnimationStyle: AnimationStyle(
        duration: TrackerMotion.duration(context, TrackerMotion.entrance),
        reverseDuration: TrackerMotion.duration(context, TrackerMotion.quick),
      ),
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * 0.75,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(
              friend == null
                  ? 'Rincian hutang & piutang'
                  : 'Rincian ${friend.username}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SectionTitle('Hutangmu'),
            if (owed.isEmpty)
              const Text('Tidak ada hutang yang menunggu pembayaran.'),
            for (final d in owed)
              _detailDebt(
                sheetContext,
                d,
                d.owner,
                c.profile?.id == d.debtorId,
              ),
            const SectionTitle('Piutangmu'),
            if (owned.isEmpty)
              const Text('Tidak ada piutang yang menunggu pembayaran.'),
            for (final d in owned)
              _detailDebt(sheetContext, d, d.debtor, false),
          ],
        ),
      ),
    );
    if (selected != null && mounted) {
      await _pay(selected);
    }
  }

  Widget _detailDebt(
    BuildContext sheetContext,
    Debt d,
    String name,
    bool canPay,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(d.description),
            const SizedBox(height: 8),
            Text(rupiah(d.amount), style: monoStyle(size: 18)),
            if (canPay) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.pop(sheetContext, d),
                child: const Text('Tandai lunas'),
              ),
            ],
          ],
        ),
      ),
    ),
  );
  Widget _avatar(String name) => CircleAvatar(
    radius: 18,
    backgroundColor: WebPalette.of(context).sunken,
    foregroundColor: WebPalette.of(context).foreground,
    child: Text(
      name.characters.firstOrNull?.toUpperCase() ?? '?',
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
    ),
  );
}
