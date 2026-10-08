import 'dart:collection';
import 'dart:convert';

double money(Object? value) => value is num ? value.toDouble() : double.parse(value?.toString() ?? '0');
Map<String, dynamic> object(Object? value) => value as Map<String, dynamic>;
List<Map<String, dynamic>> objects(Object? value) =>
    (value as List? ?? []).map(object).toList();

const categories = {
  'makanan': ['makanan', 'jajanan'],
  'minuman': ['minuman', 'jajanan'],
  'transport': ['transport', 'online', 'umum', 'pesawat', 'pribadi'],
  'belanja': ['belanja', 'fashion', 'elektronik', 'kecantikan', 'online_shop', 'harian'],
  'hiburan': ['hiburan', 'streaming', 'game', 'liburan', 'tontonan', 'aktivitas'],
  'tagihan': ['tagihan', 'utilitas', 'internet_pulsa', 'asuransi', 'kredit', 'sewa', 'gaji_pihak3', 'iuran'],
  'kesehatan': ['kesehatan', 'apotek', 'prosedur', 'obat', 'konsul'],
  'gaji': ['gaji', 'bonus', 'komisi'],
  'hadiah': ['hadiah', 'undian', 'reward', 'kado', 'sumbangan', 'pemberian_masuk'],
};
const categoryEmoji = {'makanan': '🍜', 'minuman': '☕', 'transport': '🚗',
  'belanja': '🛍️', 'hiburan': '🎮', 'tagihan': '📋', 'kesehatan': '💊',
  'gaji': '💰', 'hadiah': '🎁'};
double? parseAmount(String input) {
  if (!RegExp(r'^\d{1,15}([,.]\d{1,2})?$').hasMatch(input.trim())) return null;
  final value = double.tryParse(input.trim().replaceAll(',', '.'));
  return value != null && value > 0 && value < 1e15 ? value : null;
}
String? validateUsername(String? value) => value == null ||
    value.runes.length < 3 || value.runes.length > 50 || value.trim() != value ||
    value.runes.any((c) => c < 32 || (c >= 127 && c <= 159))
    ? 'Username harus 3–50 karakter, tanpa spasi di awal/akhir.' : null;
String? validatePassword(String? value, {bool register = false}) {
  final bytes = utf8.encode(value ?? '').length;
  return bytes < (register ? 8 : 1) || bytes > 72 || (value ?? '').contains('\u0000')
      ? (register ? 'Password harus 8–72 byte.' : 'Masukkan password (maksimal 72 byte).') : null;
}
class TrackerRecord {
  TrackerRecord.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String, title = j['title'] as String,
        description = j['description'] as String? ?? '', amount = money(j['amount']),
        type = j['type'] as String, date = DateTime.parse(j['createdAt'] as String).toLocal(),
        isCommitted = j['isCommitted'] == true,
        tags = objects(j['categories']);
  final String id, title, description, type;
  final double amount;
  final DateTime date;
  final bool isCommitted;
  final List<Map<String, dynamic>> tags;
  String _tag(String type) => tags.where((c) => c['type'] == type)
      .map((c) => c['name'] as String).firstOrNull ?? '';
  String get primary => _tag('primary');
  String get secondary => _tag('secondary');
}
class Overview {
  Overview.fromJson(Map<String, dynamic> j)
      : records = [...objects(j['expenses']), ...objects(j['incomes']), ...objects(j['debts'])]
            .map(TrackerRecord.fromJson).toList()..sort((a, b) => b.date.compareTo(a.date)),
        cash = money(j['cash']), debt = money(j['debt']),
        receivable = money(j['receivable']), balance = money(j['balance']);
  final List<TrackerRecord> records;
  final double cash, debt, receivable, balance;
  double total(String type, {DateTime? month}) => filterRecords(records, type: type, month: month)
      .where((r) => r.isCommitted).fold(0.0, (sum, r) => sum + r.amount);
}
List<TrackerRecord> filterRecords(List<TrackerRecord> records,
    {String query = '', String? type, DateTime? month, bool draftsOnly = false}) =>
  records.where((r) => (type == null || r.type == type) &&
    (!draftsOnly || !r.isCommitted) &&
    (month == null || (r.date.year == month.year && r.date.month == month.month)) &&
    '${r.title} ${r.description} ${r.primary} ${r.secondary}'.toLowerCase().contains(query.toLowerCase())).toList();
class Profile {
  Profile.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String, username = j['username'] as String,
        discord = object(j['discord']);
  final String id, username;
  final Map<String, dynamic> discord;
  bool get connected => discord['connected'] == true;
}
class Friend {
  Friend.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String, username = j['username'] as String,
        status = j['status'] as String? ?? '';
  final String id, username, status;
}
class FriendRequest {
  FriendRequest.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String, senderId = object(j['sender'])['id'] as String,
        receiverId = object(j['receiver'])['id'] as String,
        sender = object(j['sender'])['username'] as String,
        receiver = object(j['receiver'])['username'] as String;
  final String id, senderId, receiverId, sender, receiver;
}
class Debt {
  Debt.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String, ownerId = j['ownerId'] as String,
        debtorId = j['debtorId'] as String,
        owner = object(j['owner'])['username'] as String,
        debtor = object(j['debtor'])['username'] as String,
        description = j['description'] as String, amount = money(j['amount']),
        status = j['status'] as String;
  final String id, ownerId, debtorId, owner, debtor, description, status;
  final double amount;
  bool get pending => status == 'pending';
}
