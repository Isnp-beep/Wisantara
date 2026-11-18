import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/format.dart';
import '../core/i18n.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'detail.dart';
import 'plans.dart';

/// Hasil rekomendasi: bisa dari kalimat bebas ("budget 2 juta 3 hari") atau dari form.
class RecommendScreen extends StatefulWidget {
  final String prompt;
  const RecommendScreen({super.key, this.prompt = ''});
  @override
  State<RecommendScreen> createState() => _RecommendScreenState();
}

class _RecommendScreenState extends State<RecommendScreen> {
  late final TextEditingController _prompt = TextEditingController(text: widget.prompt);
  final _budget = TextEditingController();
  int _days = 2, _people = 2;
  final Set<String> _interests = {};
  Map? _res;
  bool _busy = false;
  String? _err;

  static const _cats = [
    ['alam', 'nature', 'mountain'], ['pantai', 'beach', 'waves'], ['budaya', 'culture', 'landmark'],
    ['sejarah', 'history', 'landmark'], ['kuliner', 'food', 'utensils'],
  ];

  @override
  void initState() {
    super.initState();
    if (widget.prompt.isNotEmpty) WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  @override
  void dispose() {
    _prompt.dispose();
    _budget.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final api = context.read<AppState>().api;
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      final body = <String, dynamic>{'prompt': _prompt.text.trim(), 'days': _days, 'people': _people};
      final b = int.tryParse(_budget.text.replaceAll(RegExp(r'[^0-9]'), ''));
      if (b != null && b > 0) body['budget'] = b;
      if (_interests.isNotEmpty) body['interests'] = _interests.toList();
      final r = await api.post('/recommend', body);
      if (mounted) setState(() => _res = Map.from(r));
    } catch (e) {
      if (mounted) setState(() => _err = errText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final results = _res == null ? <Map>[] : List<Map>.from((_res!['results'] as List).map((e) => Map.from(e)));
    return Scaffold(
      appBar: AppBar(title: const Text('Rekomendasi AI')),
      body: ListView(padding: const EdgeInsets.only(bottom: 30), children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextField(controller: _prompt, minLines: 1, maxLines: 3, decoration: const InputDecoration(hintText: 'Ceritakan liburan impianmu…')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _budget, keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: '${t('budget')} (Rp)', isDense: true),
                ),
              ),
              const SizedBox(width: 10),
              _Stepper(label: t('days'), value: _days, onChanged: (v) => setState(() => _days = v)),
              const SizedBox(width: 10),
              _Stepper(label: t('people'), value: _people, onChanged: (v) => setState(() => _people = v)),
            ]),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (final c in _cats)
                  Pill(t(c[1]), icon: c[2], selected: _interests.contains(c[0]), onTap: () => setState(() {
                        _interests.contains(c[0]) ? _interests.remove(c[0]) : _interests.add(c[0]);
                      })),
              ]),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _busy ? null : _run,
              icon: const LIcon('sparkles', color: Colors.white, size: 18),
              label: Text(_busy ? '…' : 'Cari rekomendasi'),
            ),
          ]),
        ),
        if (_busy) const Padding(padding: EdgeInsets.all(40), child: Center(child: Mascot('loading', height: 120))),
        if (_err != null) Padding(padding: const EdgeInsets.all(24), child: Text(_err!, style: const TextStyle(color: C.red))),
        if (_res != null && !_busy) ...[
          if (_res!['summary'] != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Box(color: C.goldTint, child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Mascot('menjelaskan', height: 60),
                const SizedBox(width: 10),
                Expanded(child: Text('${_res!['summary']}')),
              ])),
            ),
          SectionTitle('${results.length} wisata untukmu',
              trailing: Text(
                '${(_res!['parsed']['budget'] != null) ? rupiah(_res!['parsed']['budget'] as num) : 'tanpa batas'} · ${_res!['parsed']['days']} hari',
                style: const TextStyle(color: C.muted, fontSize: 12),
              )),
          for (final r in results)
            DestCard(
              d: Map.from(r['destination']),
              onTap: () => go(context, DetailScreen(id: (r['destination']['id'] as num).toInt())),
              footer: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${r['reason']}', style: const TextStyle(color: C.green, fontSize: 12.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Estimasi total: ${rupiah(r['est_cost'] as num)}', style: const TextStyle(color: C.muted, fontSize: 12.5)),
                const SizedBox(height: 10),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
                  onPressed: () => addToPlanSheet(context, (r['destination']['id'] as num).toInt()),
                  child: const Text('Tambah ke rencana'),
                ),
              ]),
            ),
        ],
      ]),
    );
  }
}

class _Stepper extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  const _Stepper({required this.label, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => Column(children: [
        Text(label, style: const TextStyle(fontSize: 11, color: C.muted)),
        Row(children: [
          GestureDetector(onTap: () => value > 1 ? onChanged(value - 1) : null, child: const Icon(Icons.remove_circle_outline, color: C.green)),
          SizedBox(width: 24, child: Text('$value', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800))),
          GestureDetector(onTap: () => value < 14 ? onChanged(value + 1) : null, child: const Icon(Icons.add_circle_outline, color: C.green)),
        ]),
      ]);
}
