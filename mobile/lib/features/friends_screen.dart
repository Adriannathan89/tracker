import 'dart:collection';
import 'package:flutter/material.dart';
import '../core/app_controller.dart';
import '../core/models.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'add_debt_sheet.dart';

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
  void dispose() { _search.dispose(); super.dispose(); }
  Future<void> _find() async {
    if (_search.text.trim().isEmpty) { setState(() => _results = null); return; }
    final revision = ++_searchRevision;
    setState(() { _searching = true; _error = null; });
    try {
      final result = await widget.controller.api.request('POST', 'user/friend/search', body: {'name': _search.text.trim()});
      if (mounted && revision == _searchRevision) setState(() => _results = objects(result).map(Friend.fromJson).toList());
    } catch (e) { if (mounted && revision == _searchRevision) setState(() => _error = e.toString()); }
    finally { if (mounted && revision == _searchRevision) setState(() => _searching = false); }
  }
  Future<void> _action(String method, String path, Object body, String message) async {
    if (_busy) return;
    setState(() { _busy = true; _error = null; });
    try {
      await widget.controller.mutate(method, path, body: body);
      if (mounted) { toast(context, message); if (_results != null) await _find(); }
    } catch (e) { if (mounted) setState(() => _error = e.toString()); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _pay(Debt d) async {
    if (!await confirm(context, 'Konfirmasi pembayaran', 'Tandai utang ${rupiah(d.amount)} kepada ${d.owner} sebagai lunas? Saldo kedua akun akan diperbarui.')) return;
    if (!mounted) return;
    await _action('PUT', 'debt/finish', {'debtId': d.id}, 'Utang berhasil dilunasi.');
  }
  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final incoming = c.requests.where((r) => r.receiverId == c.profile?.id).toList();
    return PageBody(controller: c, children: [
      const Text('Urus utang, tetap berteman.', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
      const SizedBox(height: 16), StatCard('Piutang kepada teman', c.owned.where((d) => d.pending).fold(0.0, (s, d) => s + d.amount), color: incomeColor),
      const SizedBox(height: 12), StatCard('Utangmu kepada teman', c.owed.where((d) => d.pending).fold(0.0, (s, d) => s + d.amount), color: expenseColor),
      const SectionTitle('Cari & tambah teman'), TextField(controller: _search, maxLength: 50,
        decoration: InputDecoration(labelText: 'Username teman', prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(tooltip: 'Bersihkan pencarian', onPressed: () {
            _searchRevision++; _search.clear(); setState(() { _results = null; _searching = false; _error = null; });
          }, icon: const Icon(Icons.close))), onSubmitted: (_) => _find()),
      BusyButton(busy: _searching, label: 'Cari pengguna', onPressed: _find),
      if (_error != null) Padding(padding: const EdgeInsets.only(top: 12),
        child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
      if (_busy) const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: LinearProgressIndicator()),
      if (_results != null) ...[
        const SectionTitle('Hasil pencarian'),
        if (_results!.isEmpty) const EmptyCard(title: 'Pengguna tidak ditemukan', message: 'Coba awalan username yang lain.', icon: Icons.person_search_outlined),
        ..._results!.map((f) {
          final incomingRequest = incoming.where((r) => r.senderId == f.id).firstOrNull;
          final accepted = c.friends.any((friend) => friend.id == f.id) || f.status == 'accepted';
          return Padding(padding: const EdgeInsets.only(bottom: 8), child: Card(child: ListTile(
            leading: _avatar(f.username), title: Text(f.username),
            subtitle: Text(accepted ? 'Sudah berteman' : incomingRequest != null ? 'Permintaan masuk' : f.status == 'pending' ? 'Permintaan terkirim' : 'Belum berteman'),
            trailing: !accepted && incomingRequest == null && f.status != 'pending' ? IconButton(
              tooltip: 'Tambah ${f.username}', onPressed: _busy ? null : () => _action('POST', 'user/friend/add', {'friendId': f.id}, 'Permintaan pertemanan terkirim.'),
              icon: const Icon(Icons.person_add_outlined)) : null)));
        }),
      ],
      SectionTitle('Permintaan masuk (${incoming.length})'),
      if (incoming.isEmpty) const Text('Belum ada permintaan pertemanan.'),
      ...incoming.map((r) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Card(child: Padding(
        padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(r.sender, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton(onPressed: _busy ? null : () => _action('PUT', 'user/friend/request/response',
              {'friendRequestId': r.id, 'action': 'accept'}, 'Permintaan diterima.'), child: const Text('Terima')),
            OutlinedButton(onPressed: _busy ? null : () => _action('PUT', 'user/friend/request/response',
              {'friendRequestId': r.id, 'action': 'reject'}, 'Permintaan ditolak.'), child: const Text('Tolak')),
          ]),
        ]))))),
      SectionTitle('Teman (${c.friends.length})'),
      if (c.friends.isEmpty) const EmptyCard(title: 'Belum ada teman', message: 'Cari username teman lalu kirim permintaan.', icon: Icons.people_outline),
      ...c.friends.map((f) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Card(child: Padding(
        padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [_avatar(f.username), const SizedBox(width: 12), Expanded(child: Text(f.username,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)))]),
          const SizedBox(height: 12), Text('Piutang: ${rupiah(c.friendReceivable(f.id))}', style: const TextStyle(color: incomeColor)),
          const SizedBox(height: 4), Text('Utangmu: ${rupiah(c.friendDebt(f.id))}', style: const TextStyle(color: expenseColor)),
          const SizedBox(height: 12), OutlinedButton.icon(onPressed: _busy ? null : () => showModalBottomSheet<void>(
            context: context, useSafeArea: true, isScrollControlled: true,
            builder: (_) => AddDebtSheet(controller: c, friend: f)), icon: const Icon(Icons.add), label: const Text('Tambah piutang')),
        ]))))),
      const SectionTitle('Utang yang perlu dibayar'),
      if (c.owed.isEmpty) const Text('Tidak ada utang yang menunggu pembayaran. 🎉'),
      ...c.owed.where((d) => d.pending).map((d) => _debtCard(d, d.owner,
        d.debtorId == c.profile?.id ? () => _pay(d) : null)),
      const SectionTitle('Piutang yang menunggu'),
      if (!c.owned.any((d) => d.pending)) const Text('Tidak ada piutang yang menunggu pembayaran.'),
      ...c.owned.where((d) => d.pending).map((d) => _debtCard(d, d.debtor, null)),
    ]);
  }
  Widget _avatar(String name) => CircleAvatar(backgroundColor: lime.withValues(alpha: 0.25),
    foregroundColor: Theme.of(context).colorScheme.onSurface,
    child: Text(name.characters.firstOrNull?.toUpperCase() ?? '?'));
  Widget _debtCard(Debt d, String name, VoidCallback? pay) => Padding(padding: const EdgeInsets.only(bottom: 8),
    child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(name, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 6), Text(d.description),
      const SizedBox(height: 8), Text(rupiah(d.amount), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      if (pay != null) ...[const SizedBox(height: 10), FilledButton(onPressed: _busy ? null : pay, child: const Text('Tandai lunas'))],
    ]))));
}
