import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/format.dart';
import '../core/i18n.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

/// Detail rencana: jadwal per jam, budget, barang bawaan, dan pengingat.
class PlanDetailScreen extends StatefulWidget {
  final int id;
  const PlanDetailScreen({super.key, required this.id});
  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen> with SingleTickerProviderStateMixin {
  late final TabController _tc = TabController(length: 3, vsync: this);
  Map<String, dynamic>? _p;
  String? _err;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final r = await context.read<AppState>().api.get('/plans/${widget.id}');
      if (mounted) setState(() { _p = Map<String, dynamic>.from(r); _err = null; });
    } catch (e) {
      if (mounted) setState(() => _err = errText(e));
    }
  }

  /// Jalankan perubahan; respons API berisi detail rencana terbaru.
  Future<void> _mut(Future<dynamic> Function() f) async {
    try {
      final r = await f();
      if (mounted) {
        setState(() => _p = Map<String, dynamic>.from(r));
        context.read<AppState>().bump();
      }
    } catch (e) {
      if (mounted) toast(context, errText(e), error: true);
    }
  }

  Future<String?> _ask(String title, String hint, {bool number = false, String initial = ''}) {
    final ctl = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: TextField(controller: ctl, autofocus: true, keyboardType: number ? TextInputType.number : TextInputType.text, decoration: InputDecoration(hintText: hint)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(t('cancel'))),
          TextButton(onPressed: () => Navigator.pop(c, ctl.text.trim()), child: Text(t('save'))),
        ],
      ),
    );
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus rencana?'),
        content: const Text('Semua jadwal, budget, dan daftar barang di rencana ini ikut terhapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(t('cancel'))),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Hapus', style: TextStyle(color: C.red))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<AppState>().api.delete('/plans/${widget.id}');
      if (!mounted) return;
      context.read<AppState>().bump();
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) toast(context, errText(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_p == null) {
      return Scaffold(
        appBar: AppBar(),
        body: _err != null ? EmptyView(_err!, pose: 'berpikir') : const Center(child: CircularProgressIndicator(color: C.green)),
      );
    }
    final p = _p!;
    final api = context.read<AppState>().api;
    final pid = widget.id;
    return Scaffold(
      appBar: AppBar(
        title: Text('${p['name']}'),
        actions: [IconButton(onPressed: _delete, icon: const LIcon('trash-2', color: C.red, size: 22))],
        bottom: TabBar(
          controller: _tc, labelColor: C.green, indicatorColor: C.green, unselectedLabelColor: C.muted,
          tabs: [Tab(text: t('itinerary')), Tab(text: t('budget')), Tab(text: t('packing'))],
        ),
      ),
      body: Column(children: [
        _Summary(p: p, onToggle: (key, v) => _mut(() => api.put('/plans/$pid', {key: v}))),
        Expanded(
          child: TabBarView(controller: _tc, children: [
            _itinerary(p, api, pid),
            _budget(p, api, pid),
            _packing(p, api, pid),
          ]),
        ),
      ]),
    );
  }

  Widget _itinerary(Map<String, dynamic> p, dynamic api, int pid) {
    final items = List<Map>.from((p['items'] as List).map((e) => Map.from(e)));
    final days = <int, List<Map>>{};
    for (final i in items) {
      days.putIfAbsent((i['day_no'] as num).toInt(), () => []).add(i);
    }
    final keys = days.keys.toList()..sort();
    const icons = {'activity': 'footprints', 'food': 'utensils', 'ticket': 'ticket', 'guide': 'users', 'stay': 'tent-tree'};
    return Stack(children: [
      items.isEmpty
          ? const EmptyView('Belum ada jadwal. Tambah kegiatan atau masukkan wisata dari halaman detail.', pose: 'mainhp')
          : ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 90), children: [
              for (final k in keys) ...[
                Padding(padding: const EdgeInsets.only(top: 12, bottom: 8), child: Text('Hari $k', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
                for (final i in days[k]!)
                  Dismissible(
                    key: ValueKey('item${i['id']}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(color: C.red, borderRadius: BorderRadius.circular(16)),
                      child: const LIcon('trash-2', color: Colors.white),
                    ),
                    onDismissed: (_) => _mut(() => api.delete('/plans/$pid/items/${i['id']}')),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Box(
                        padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
                        color: i['done'] == true ? C.greenTint : Colors.white,
                        child: Row(children: [
                          Checkbox(value: i['done'] == true, activeColor: C.green, onChanged: (v) => _mut(() => api.patch('/plans/$pid/items/${i['id']}', {'done': v}))),
                          SizedBox(width: 50, child: Text('${i['time_label']}', style: const TextStyle(fontWeight: FontWeight.w800, color: C.green))),
                          LIcon(icons['${i['kind']}'] ?? 'footprints', size: 18, color: C.muted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('${i['title']}', style: TextStyle(fontWeight: FontWeight.w700, decoration: i['done'] == true ? TextDecoration.lineThrough : null)),
                              if (i['note'] != null && '${i['note']}'.isNotEmpty) Text('${i['note']}', style: const TextStyle(color: C.muted, fontSize: 12)),
                              if (i['booking_id'] != null) const Text('Sudah dibayar', style: TextStyle(color: C.green, fontSize: 11.5, fontWeight: FontWeight.w800)),
                            ]),
                          ),
                        ]),
                      ),
                    ),
                  ),
              ],
            ]),
      Positioned(
        right: 20, bottom: 18,
        child: FloatingActionButton.extended(
          backgroundColor: C.green, foregroundColor: Colors.white,
          onPressed: () => _addItem(api, pid),
          icon: const LIcon('plus', color: Colors.white, size: 20),
          label: const Text('Kegiatan'),
        ),
      ),
    ]);
  }

  Future<void> _addItem(dynamic api, int pid) async {
    final title = await _ask('Kegiatan baru', 'mis. Sarapan di warung lokal');
    if (title == null || title.isEmpty || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
    if (time == null || !mounted) return;
    final day = await _ask('Hari ke berapa?', '1', number: true, initial: '1');
    final label = '${time.hour.toString().padLeft(2, '0')}.${time.minute.toString().padLeft(2, '0')}';
    _mut(() => api.post('/plans/$pid/items', {'title': title, 'time_label': label, 'day_no': int.tryParse(day ?? '1') ?? 1}));
  }

  Widget _budget(Map<String, dynamic> p, dynamic api, int pid) {
    final ex = List<Map>.from((p['expenses'] as List).map((e) => Map.from(e)));
    final budget = (p['budget_idr'] as num).toInt(), spent = (p['spent_idr'] as num).toInt();
    final ratio = budget == 0 ? 0.0 : (spent / budget).clamp(0.0, 1.0);
    return Stack(children: [
      ListView(padding: const EdgeInsets.fromLTRB(20, 14, 20, 90), children: [
        Box(
          color: C.goldTint,
          child: Column(children: [
            KV('Budget', rupiah(budget)),
            KV(t('expenses'), rupiah(spent)),
            const Divider(),
            KV(t('remaining'), rupiah(budget - spent), bold: true),
            const SizedBox(height: 8),
            ClipRRect(borderRadius: BorderRadius.circular(5), child: LinearProgressIndicator(value: ratio.toDouble(), minHeight: 9, backgroundColor: Colors.white, color: spent > budget ? C.red : C.green)),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  final v = await _ask('Ubah budget', 'Rp', number: true, initial: '$budget');
                  if (v == null || !mounted) return;
                  _mut(() => api.put('/plans/$pid', {'budget_idr': int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0}));
                },
                child: const Text('Ubah budget'),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        if (ex.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('Belum ada pengeluaran. Pembayaran tiket di Wisantara otomatis tercatat di sini.', textAlign: TextAlign.center, style: TextStyle(color: C.muted))),
        for (final e in ex)
          Dismissible(
            key: ValueKey('ex${e['id']}'),
            direction: DismissDirection.endToStart,
            background: Container(color: C.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const LIcon('trash-2', color: Colors.white)),
            onDismissed: (_) => _mut(() => api.delete('/plans/$pid/expenses/${e['id']}')),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Box(child: Row(children: [
                LIcon(e['booking_id'] != null ? 'ticket' : 'wallet', color: C.green),
                const SizedBox(width: 12),
                Expanded(child: Text('${e['title']}', style: const TextStyle(fontWeight: FontWeight.w700))),
                Text('-${rupiah(e['amount'] as num)}', style: const TextStyle(color: C.red, fontWeight: FontWeight.w800)),
              ])),
            ),
          ),
      ]),
      Positioned(
        right: 20, bottom: 18,
        child: FloatingActionButton.extended(
          backgroundColor: C.green, foregroundColor: Colors.white,
          onPressed: () async {
            final title = await _ask('Pengeluaran', 'mis. Bensin');
            if (title == null || title.isEmpty || !mounted) return;
            final amt = await _ask('Jumlah (Rp)', '50000', number: true);
            final n = int.tryParse((amt ?? '').replaceAll(RegExp(r'[^0-9]'), ''));
            if (n == null || !mounted) return;
            _mut(() => api.post('/plans/$pid/expenses', {'title': title, 'amount': n}));
          },
          icon: const LIcon('plus', color: Colors.white, size: 20),
          label: const Text('Catat'),
        ),
      ),
    ]);
  }

  Widget _packing(Map<String, dynamic> p, dynamic api, int pid) {
    final items = List<Map>.from((p['packing'] as List).map((e) => Map.from(e)));
    final done = items.where((i) => i['done'] == true).length;
    return Stack(children: [
      ListView(padding: const EdgeInsets.fromLTRB(20, 14, 20, 90), children: [
        Text('$done dari ${items.length} barang sudah siap', style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        for (final i in items)
          Dismissible(
            key: ValueKey('pk${i['id']}'),
            direction: DismissDirection.endToStart,
            background: Container(color: C.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const LIcon('trash-2', color: Colors.white)),
            onDismissed: (_) => _mut(() => api.delete('/plans/$pid/packing/${i['id']}')),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Box(
                padding: const EdgeInsets.fromLTRB(6, 2, 14, 2),
                color: i['done'] == true ? C.greenTint : Colors.white,
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading, activeColor: C.green,
                  value: i['done'] == true,
                  title: Text('${i['label']}', style: TextStyle(fontWeight: FontWeight.w600, decoration: i['done'] == true ? TextDecoration.lineThrough : null)),
                  onChanged: (v) => _mut(() => api.patch('/plans/$pid/packing/${i['id']}', {'done': v})),
                ),
              ),
            ),
          ),
      ]),
      Positioned(
        right: 20, bottom: 18,
        child: FloatingActionButton.extended(
          backgroundColor: C.green, foregroundColor: Colors.white,
          onPressed: () async {
            final v = await _ask('Barang baru', 'mis. Payung');
            if (v == null || v.isEmpty || !mounted) return;
            _mut(() => api.post('/plans/$pid/packing', {'label': v}));
          },
          icon: const LIcon('plus', color: Colors.white, size: 20),
          label: const Text('Barang'),
        ),
      ),
    ]);
  }
}

class _Summary extends StatelessWidget {
  final Map<String, dynamic> p;
  final void Function(String key, bool v) onToggle;
  const _Summary({required this.p, required this.onToggle});
  @override
  Widget build(BuildContext context) {
    final d = p['days_until'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Box(
        color: C.greenTint,
        child: Column(children: [
          Row(children: [
            const LIcon('calendar-days', color: C.green),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                p['start_date'] == null ? 'Tanggal belum diatur' : '${tgl(p['start_date'] as String?)} – ${tgl(p['end_date'] as String?)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (d != null) Text((d as num) < 0 ? 'Selesai' : (d == 0 ? 'Hari ini' : 'H-$d'), style: const TextStyle(fontWeight: FontWeight.w900, color: C.green)),
          ]),
          Row(children: [
            Expanded(child: Text('Ingatkan H-1 berangkat', style: const TextStyle(fontSize: 13))),
            Switch(value: p['remind_depart'] == true, activeColor: C.green, onChanged: (v) => onToggle('remind_depart', v)),
          ]),
          Row(children: [
            Expanded(child: Text('Ingatkan H-3 barang bawaan', style: const TextStyle(fontSize: 13))),
            Switch(value: p['remind_pack'] == true, activeColor: C.green, onChanged: (v) => onToggle('remind_pack', v)),
          ]),
        ]),
      ),
    );
  }
}
