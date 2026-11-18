import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/i18n.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'detail.dart';
import 'map_screen.dart';

class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key});
  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  final _q = TextEditingController();
  String _cat = '';
  int _max = 0;
  int _rev = 0;

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<dynamic> _load(AppState app) => app.api.get('/destinations', query: {
        'q': _q.text.trim(), 'category': _cat, 'max_price': _max == 0 ? '' : _max, 'lang': app.lang,
      });

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cats = [['', t('all'), 'compass'], ['alam', t('nature'), 'mountain'], ['pantai', t('beach'), 'waves'],
      ['budaya', t('culture'), 'landmark'], ['sejarah', t('history'), 'landmark'], ['kuliner', t('food'), 'utensils']];
    return SafeArea(
      bottom: false,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _q,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => setState(() => _rev++),
                decoration: InputDecoration(
                  hintText: t('search_hint'),
                  prefixIcon: const Padding(padding: EdgeInsets.all(13), child: LIcon('search', size: 20, color: C.muted)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => go(context, const MapScreen()),
              child: Container(
                width: 50, height: 50,
                decoration: BoxDecoration(color: C.green, borderRadius: BorderRadius.circular(14)),
                child: const Center(child: LIcon('map', color: Colors.white, size: 22)),
              ),
            ),
          ]),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            for (final c in cats) Pill(c[1], icon: c[2], selected: _cat == c[0], onTap: () => setState(() => _cat = c[0])),
          ]),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            for (final p in [[0, 'Semua harga'], [100000, '≤ Rp100rb'], [200000, '≤ Rp200rb'], [500000, '≤ Rp500rb']])
              Pill(p[1] as String, selected: _max == p[0], onTap: () => setState(() => _max = p[0] as int)),
          ]),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: FutureView(
            key: ValueKey('$_cat$_max$_rev${app.lang}'),
            load: () => _load(app),
            builder: (c, data, reload) {
              final list = List<Map>.from((data as List).map((e) => Map.from(e)));
              if (list.isEmpty) return EmptyView(t('empty'));
              return RefreshIndicator(
                color: C.green,
                onRefresh: () async => reload(),
                child: ListView(padding: const EdgeInsets.only(bottom: 20), children: [
                  for (final d in list)
                    _FavCard(d: d, onChanged: reload),
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _FavCard extends StatefulWidget {
  final Map d;
  final VoidCallback onChanged;
  const _FavCard({required this.d, required this.onChanged});
  @override
  State<_FavCard> createState() => _FavCardState();
}

class _FavCardState extends State<_FavCard> {
  late bool _fav = widget.d['is_favorite'] == true;

  Future<void> _toggle() async {
    try {
      final r = await context.read<AppState>().api.post('/destinations/${widget.d['id']}/favorite');
      if (mounted) setState(() => _fav = r['is_favorite'] == true);
    } catch (e) {
      if (mounted) toast(context, errText(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) => DestCard(
        d: widget.d,
        onTap: () async {
          await go(context, DetailScreen(id: (widget.d['id'] as num).toInt()));
        },
        trailing: GestureDetector(
          onTap: _toggle,
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: Colors.white.withOpacity(.92), shape: BoxShape.circle),
            child: Icon(_fav ? Icons.favorite : Icons.favorite_border, color: C.red, size: 20),
          ),
        ),
      );
}
