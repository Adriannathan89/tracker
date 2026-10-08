import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'models.dart';
import 'session_store.dart';

enum SessionState { starting, signedOut, signedIn, unavailable }
class AppController extends ChangeNotifier {
  AppController(this.api, this.preferences) {
    api.sessionExpired.addListener(_expired);
  }
  final ApiClient api;
  final KeyValueStore preferences;
  SessionState state = SessionState.starting;
  Profile? profile;
  Overview? overview;
  List<Friend> friends = [];
  List<FriendRequest> requests = [];
  List<Debt> owned = [], owed = [];
  bool dark = false, loading = false;
  String? error;
  int _generation = 0;
  int _loadRevision = 0;
  bool _disposed = false;
  void _notify() { if (!_disposed) { notifyListeners(); } }
  void _expired() {
    if (!api.sessionExpired.value) { return; }
    _generation++;
    loading = false; error = null;
    profile = null; overview = null; friends = []; requests = []; owned = []; owed = [];
    state = SessionState.signedOut;
    _notify();
  }
  Future<void> start() async {
    state = SessionState.starting; error = null; _notify();
    try {
      dark = await preferences.read('tracker.dark') == 'true';
      await api.session.restore();
      if (!api.session.hasSession) { state = SessionState.signedOut; _notify(); return; }
      await api.request('GET', 'auth/validate-session');
      state = SessionState.signedIn;
      await reload();
    } catch (e) {
      if (state != SessionState.signedOut) { state = SessionState.unavailable; error = e.toString(); }
    }
    _notify();
  }
  Future<void> authenticate(String username, String password, {bool register = false}) async {
    if (register) { await api.request('POST', 'user/register',
        body: {'username': username, 'password': password}); }
    await api.login(username, password);
    state = SessionState.signedIn;
    _notify();
    await reload();
  }
  Future<void> reload() async {
    final generation = _generation;
    final revision = ++_loadRevision;
    loading = true; error = null; _notify();
    try {
      // Atomic snapshot: no partial friend/debt state when one endpoint fails.
      final data = await Future.wait([
        api.request('GET', 'user/profile'), api.request('GET', 'user/records'),
        api.request('GET', 'user/friend'), api.request('GET', 'user/friend/request'),
        api.request('GET', 'debt'), api.request('GET', 'debt/owed'),
      ]);
      if (_disposed || generation != _generation || revision != _loadRevision) { return; }
      final nextProfile = Profile.fromJson(object(data[0]));
      final nextOverview = Overview.fromJson(object(data[1]));
      final nextFriends = objects(data[2]).map(Friend.fromJson).toList();
      final nextRequests = objects(data[3]).map(FriendRequest.fromJson).toList();
      final nextOwned = objects(object(data[4])['debts']).map(Debt.fromJson).toList();
      final nextOwed = objects(object(data[5])['debts']).map(Debt.fromJson).toList();
      profile = nextProfile; overview = nextOverview; friends = nextFriends;
      requests = nextRequests; owned = nextOwned; owed = nextOwed;
    } catch (e) { if (!_disposed && generation == _generation && revision == _loadRevision) { error = e.toString(); } }
    finally { if (!_disposed && generation == _generation && revision == _loadRevision) { loading = false; _notify(); } }
  }
  Future<void> mutate(String method, String path, {Object? body}) async {
    await api.request(method, path, body: body);
    await reload();
  }
  Future<void> toggleTheme() async {
    dark = !dark; _notify();
    await preferences.write('tracker.dark', dark.toString());
  }
  Future<void> logout() async {
    try { await api.logout(); }
    finally { _expired(); }
  }
  double friendReceivable(String id) => owned.where((d) => d.pending && d.debtorId == id)
      .fold(0.0, (sum, d) => sum + d.amount);
  double friendDebt(String id) => owed.where((d) => d.pending && d.ownerId == id)
      .fold(0.0, (sum, d) => sum + d.amount);
  @override
  void dispose() {
    _disposed = true;
    api.sessionExpired.removeListener(_expired);
    api.close();
    super.dispose();
  }
}
