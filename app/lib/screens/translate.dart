import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

/// Buku frasa: kalimat penting wisata dalam beberapa bahasa.
class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});
  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  String _lang = 'en';
  @override
  Widget build(BuildContext context) {
    final api = context.read<AppState>().api;
    return Scaffold(
      appBar: AppBar(title: const Text('Terjemahan frasa')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final l in [['en', 'English'], ['zh', '中文'], ['ja', '日本語'], ['ko', '한국어']])
                Pill(l[1], selected: _lang == l[0], onTap: () => setState(() => _lang = l[0])),
            ]),
          ),
        ),
        Expanded(
          child: FutureView(
            key: ValueKey(_lang),
            load: () => api.get('/phrases', query: {'lang': _lang}),
            builder: (c, data, reload) {
              final list = List<Map>.from((data as List).map((e) => Map.from(e)));
              if (list.isEmpty) return const EmptyView('Belum ada frasa');
              return ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), children: [
                for (final p in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Box(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: '${p['translation']}'));
                        toast(context, 'Disalin');
                      },
                      child: Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('${p['source']}', style: const TextStyle(color: C.muted, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text('${p['translation']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                          ]),
                        ),
                        const Icon(Icons.copy_rounded, size: 18, color: C.muted),
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
