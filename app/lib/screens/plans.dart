import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/format.dart';
import '../core/i18n.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'plan_detail.dart';

/// Daftar rencana, dikelompokkan per folder (gaya Notion).
class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});
  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  int _rev = 0;

  Future<void> _new() async {
    final r = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: C.cream,
      builder: (_) => const _NewPlanSheet(),
    );
    if (r == null || !mounted) return;
    try {
      final p = await context.read<AppState>().api.post('/plans', r);
      if (!mounted) return;
      await go(context, PlanDetailScreen(id: (p['id'] as num).toInt()));
      setState(() => _rev++);
    } catch (e) {
      if (mounted) toast(context, errText(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = context.read<AppState>().api;
    return Scaffold(
      appBar: AppBar(title: Text(t('planner'))),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: C.green, foregroundColor: Colors.white,
        onPressed: _new, icon: const LIcon('plus', color: Colors.white, size: 20), label: const Text('Rencana baru'),
      ),
      body: FutureView(
        key: ValueKey(_rev),
        load: () => api.get('/plans'),
        builder: (c, data, reload) {
          final list = List<Map>.from((data as List).map((e) => Map.from(e)));
          if (list.isEmpty) return const EmptyView('Belum ada rencana. Buat folder perjalanan pertamamu!', pose: 'mainhp');
          final folders = <String, List<Map>>{};
          for (final p in list) {
            folders.putIfAbsent('${p['folder']}', () => []).add(p);
          }
          return ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 100), children: [
            for (final e in folders.entries) ...[
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 8),
                child: Row(children: [
                  const LIcon('folder', size: 18, color: C.gold),
                  const SizedBox(width: 8),
                  Text(e.key, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ]),
              ),
              for (final p in e.value)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Box(
                    onTap: () async {
                      await go(context, PlanDetailScreen(id: (p['id'] as num).toInt()));
                      reload();
                    },
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text('${p['name']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                        if (p['days_until'] != null && (p['days_until'] as num) >= 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: C.goldTint, borderRadius: BorderRadius.circular(10)),
                            child: Text('H-${p['days_until']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                          ),
                      ]),
                      const SizedBox(height: 4),
                      Text(p['start_date'] != null ? '${tgl(p['start_date'] as String?)} – ${tgl(p['end_date'] as String?)}' : 'Tanggal belum diatur', style: const TextStyle(color: C.muted, fontSize: 12.5)),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (p['items_total'] as num) == 0 ? 0 : (p['items_done'] as num) / (p['items_total'] as num),
                          minHeight: 6, backgroundColor: C.line, color: C.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(children: [
                        Text('${p['items_done']}/${p['items_total']} selesai', style: const TextStyle(fontSize: 12, color: C.muted)),
                        const Spacer(),
                        Text('${t('remaining')} ${rupiah(p['remaining_idr'] as num)}', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: (p['remaining_idr'] as num) < 0 ? C.red : C.green)),
                      ]),
                    ]),
                  ),
                ),
            ],
          ]);
        },
      ),
    );
  }
}

class _NewPlanSheet extends StatefulWidget {
  const _NewPlanSheet();
  @override
  State<_NewPlanSheet> createState() => _NewPlanSheetState();
}

class _NewPlanSheetState extends State<_NewPlanSheet> {
  final _name = TextEditingController(), _folder = TextEditingController(text: 'Liburan'), _budget = TextEditingController();
  DateTime? _start, _end;

  @override
  void dispose() {
    _name.dispose();
    _folder.dispose();
    _budget.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Rencana baru', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            TextField(controller: _name, decoration: const InputDecoration(hintText: 'Nama rencana, mis. Jogja 3 hari')),
            const SizedBox(height: 10),
            TextField(controller: _folder, decoration: const InputDecoration(hintText: 'Folder')),
            const SizedBox(height: 10),
            TextField(controller: _budget, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Budget (Rp)')),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                  onPressed: () async {
                    final v = await pickDate(context, initial: _start);
                    if (v != null) setState(() { _start = v; if (_end == null || _end!.isBefore(v)) _end = v; });
                  },
                  child: Text(_start == null ? 'Berangkat' : tgl(isoDate(_start!))),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                  onPressed: () async {
                    final v = await pickDate(context, initial: _end ?? _start);
                    if (v != null) setState(() => _end = v);
                  },
                  child: Text(_end == null ? 'Pulang' : tgl(isoDate(_end!))),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                if (_name.text.trim().isEmpty) {
                  toast(context, 'Isi nama rencana', error: true);
                  return;
                }
                Navigator.pop(context, <String, dynamic>{
                  'name': _name.text.trim(),
                  'folder': _folder.text.trim().isEmpty ? 'Liburan' : _folder.text.trim(),
                  'budget_idr': int.tryParse(_budget.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
                  if (_start != null) 'start_date': isoDate(_start!),
                  if (_end != null) 'end_date': isoDate(_end!),
                });
              },
              child: Text(t('save')),
            ),
          ]),
        ),
      );
}

/// Bottom sheet: pilih rencana + hari, lalu destinasi masuk otomatis dengan tiket, pemandu, dan makan siang.
Future<void> addToPlanSheet(BuildContext context, int destinationId) async {
  final api = context.read<AppState>().api;
  List<Map> plans;
  try {
    plans = List<Map>.from((await api.get('/plans') as List).map((e) => Map.from(e)));
  } catch (e) {
    toast(context, errText(e), error: true);
    return;
  }
  if (!context.mounted) return;
  if (plans.isEmpty) {
    toast(context, 'Buat rencana dulu di menu Rencana');
    go(context, const PlansScreen());
    return;
  }
  int? planId = (plans.first['id'] as num).toInt();
  int day = 1;
  bool guide = false;
  await showModalBottomSheet(
    context: context,
    backgroundColor: C.cream,
    isScrollControlled: true,
    builder: (c) => StatefulBuilder(
      builder: (c, setS) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(c).viewInsets.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Tambah ke rencana', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: planId,
            items: [for (final p in plans) DropdownMenuItem(value: (p['id'] as num).toInt(), child: Text('${p['folder']} / ${p['name']}'))],
            onChanged: (v) => setS(() => planId = v),
          ),
          const SizedBox(height: 12),
          Row(children: [
            const Expanded(child: Text('Hari ke-', style: TextStyle(fontWeight: FontWeight.w700))),
            IconButton(onPressed: day > 1 ? () => setS(() => day--) : null, icon: const Icon(Icons.remove_circle_outline, color: C.green)),
            Text('$day', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            IconButton(onPressed: day < 14 ? () => setS(() => day++) : null, icon: const Icon(Icons.add_circle_outline, color: C.green)),
          ]),
          SwitchListTile(
            contentPadding: EdgeInsets.zero, activeColor: C.green,
            title: const Text('Sertakan pemandu', style: TextStyle(fontWeight: FontWeight.w700)),
            value: guide,
            onChanged: (v) => setS(() => guide = v),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () async {
              try {
                await api.post('/plans/$planId/add-destination', {'destination_id': destinationId, 'day_no': day, 'with_guide': guide});
                if (c.mounted) Navigator.pop(c);
                if (context.mounted) {
                  context.read<AppState>().bump();
                  toast(context, 'Ditambahkan: tiket, jadwal, dan makan siang sudah masuk rencana');
                }
              } catch (e) {
                if (c.mounted) toast(c, errText(e), error: true);
              }
            },
            child: const Text('Tambahkan'),
          ),
        ]),
      ),
    ),
  );
}
