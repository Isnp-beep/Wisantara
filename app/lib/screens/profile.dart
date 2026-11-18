import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/i18n.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'auth.dart';
import 'language.dart';
import 'notifications.dart';
import 'orders.dart';
import 'plans.dart';
import 'detail.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final u = app.user ?? {};
    return SafeArea(
      bottom: false,
      child: FutureView(
        key: ValueKey('p${app.tick}'),
        load: () => app.api.get('/me/stats'),
        builder: (c, stats, reload) => ListView(padding: const EdgeInsets.fromLTRB(20, 18, 20, 24), children: [
          Row(children: [
            CircleAvatar(
              radius: 34, backgroundColor: C.green,
              child: Text('${u['name'] ?? '?'}'.substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${u['name']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                Text('${u['email']}', style: const TextStyle(color: C.muted, fontSize: 13)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: C.greenTint, borderRadius: BorderRadius.circular(10)),
                  child: Text(u['role'] == 'lokal' ? 'Warga lokal' : 'Wisatawan', style: const TextStyle(color: C.green, fontSize: 11.5, fontWeight: FontWeight.w800)),
                ),
              ]),
            ),
            IconButton(onPressed: () => _edit(context), icon: const LIcon('settings', size: 22)),
          ]),
          const SizedBox(height: 18),
          Row(children: [
            for (final s in [['Perjalanan', stats['trips']], ['Disimpan', stats['saved']], ['Posting', stats['posts']], ['Rencana', stats['plans']]])
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: C.goldTint, borderRadius: BorderRadius.circular(14)),
                  child: Column(children: [
                    Text('${s[1]}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                    Text('${s[0]}', style: const TextStyle(fontSize: 11.5, color: C.muted)),
                  ]),
                ),
              ),
          ]),
          const SizedBox(height: 18),
          _row(context, 'clipboard-list', t('planner'), () => go(context, const PlansScreen())),
          _row(context, 'heart', 'Wisata tersimpan', () => go(context, const _FavScreen())),
          _row(context, 'ticket', t('orders'), () => go(context, Scaffold(appBar: AppBar(title: Text(t('orders'))), body: const OrdersTab()))),
          _row(context, 'bell', t('notifications'), () async {
            await go(context, const NotificationsScreen());
            app.refreshUnread();
          }),
          _row(context, 'globe', '${t('language')} · ${I18n.names[app.lang]}', () => go(context, const LanguageScreen())),
          _row(context, 'log-out', t('logout'), () async {
            await app.logout();
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const AuthScreen()), (r) => false);
            }
          }, danger: true),
        ]),
      ),
    );
  }

  Widget _row(BuildContext context, String icon, String label, VoidCallback onTap, {bool danger = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Box(
          onTap: onTap,
          child: Row(children: [
            LIcon(icon, color: danger ? C.red : C.green),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: danger ? C.red : C.text))),
            const LIcon('chevron-right', size: 20, color: C.muted),
          ]),
        ),
      );

  Future<void> _edit(BuildContext context) async {
    final app = context.read<AppState>();
    final ctl = TextEditingController(text: '${app.user?['name'] ?? ''}');
    var role = '${app.user?['role'] ?? 'turis'}';
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setS) => AlertDialog(
          title: const Text('Ubah profil'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: ctl, decoration: InputDecoration(hintText: t('name'))),
            const SizedBox(height: 12),
            Row(children: [
              Pill('Wisatawan', selected: role == 'turis', onTap: () => setS(() => role = 'turis')),
              Pill('Warlok', selected: role == 'lokal', onTap: () => setS(() => role = 'lokal')),
            ]),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(t('cancel'))),
            TextButton(onPressed: () => Navigator.pop(c, true), child: Text(t('save'))),
          ],
        ),
      ),
    );
    if (ok == true && ctl.text.trim().isNotEmpty) {
      try {
        await app.updateProfile({'name': ctl.text.trim(), 'role': role});
      } catch (e) {
        if (context.mounted) toast(context, errText(e), error: true);
      }
    }
  }
}

class _FavScreen extends StatelessWidget {
  const _FavScreen();
  @override
  Widget build(BuildContext context) {
    final api = context.read<AppState>().api;
    return Scaffold(
      appBar: AppBar(title: const Text('Wisata tersimpan')),
      body: FutureView(
        load: () => api.get('/favorites'),
        builder: (c, data, reload) {
          final list = List<Map>.from((data as List).map((e) => Map.from(e)));
          if (list.isEmpty) return const EmptyView('Belum ada wisata tersimpan. Ketuk ikon hati di halaman Jelajah.', pose: 'searching');
          return ListView(padding: const EdgeInsets.only(bottom: 20), children: [
            for (final d in list)
              DestCard(d: d, onTap: () async {
                await go(context, DetailScreen(id: (d['id'] as num).toInt()));
                reload();
              }),
          ]);
        },
      ),
    );
  }
}
