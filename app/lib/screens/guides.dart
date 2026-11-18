import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/format.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

Color _hex(String? h) {
  final s = (h ?? '#5E7A3A').replaceFirst('#', '');
  return Color(int.parse('FF$s', radix: 16));
}

/// Daftar pemandu. Dengan [pick] = true, mengembalikan pemandu terpilih ke layar pemanggil.
class GuidesScreen extends StatefulWidget {
  final bool pick;
  const GuidesScreen({super.key, this.pick = false});
  @override
  State<GuidesScreen> createState() => _GuidesScreenState();
}

class _GuidesScreenState extends State<GuidesScreen> {
  String _lang = '';
  @override
  Widget build(BuildContext context) {
    final api = context.read<AppState>().api;
    return Scaffold(
      appBar: AppBar(title: Text(widget.pick ? 'Pilih pemandu' : 'Pemandu wisata')),
      body: Column(children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
          child: Row(children: [
            for (final l in [['', 'Semua'], ['id', 'Indonesia'], ['en', 'English'], ['zh', '中文'], ['ja', '日本語'], ['ko', '한국어']])
              Pill(l[1], selected: _lang == l[0], onTap: () => setState(() => _lang = l[0])),
          ]),
        ),
        Expanded(
          child: FutureView(
            key: ValueKey(_lang),
            load: () => api.get('/guides', query: {'lang': _lang}),
            builder: (c, data, reload) {
              final list = List<Map>.from((data as List).map((e) => Map.from(e)));
              if (list.isEmpty) return const EmptyView('Belum ada pemandu untuk bahasa ini');
              return ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), children: [
                for (final g in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Box(
                      onTap: widget.pick ? () => Navigator.of(context).pop(g) : null,
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        CircleAvatar(
                          radius: 28, backgroundColor: _hex(g['color'] as String?),
                          child: Text('${g['name']}'.substring(0, 1), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('${g['name']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                            Text('${g['region']} · ${(g['languages'] as List).map((e) => '$e'.toUpperCase()).join(', ')}', style: const TextStyle(color: C.muted, fontSize: 12.5)),
                            const SizedBox(height: 4),
                            Text('${g['bio']}', style: const TextStyle(fontSize: 13, height: 1.35)),
                            const SizedBox(height: 8),
                            Row(children: [
                              const Icon(Icons.star_rounded, color: C.gold, size: 18),
                              Text(' ${(g['rating'] as num) > 0 ? g['rating'] : '-'} (${g['review_count']})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              const Spacer(),
                              Text('${rupiah(g['price_idr'] as num)}/hari', style: const TextStyle(color: C.red, fontWeight: FontWeight.w800)),
                            ]),
                            if (widget.pick) ...[
                              const SizedBox(height: 10),
                              FilledButton(
                                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(40)),
                                onPressed: () => Navigator.of(context).pop(g),
                                child: const Text('Pilih pemandu ini'),
                              ),
                            ],
                          ]),
                        ),
                      ]),
                    ),
                  ),
              ]);
            },
          ),
        ),
      ]),
    );
  }
}
