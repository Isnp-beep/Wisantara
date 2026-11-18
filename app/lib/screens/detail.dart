import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/format.dart';
import '../core/i18n.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'booking.dart';
import 'community.dart';
import 'plans.dart';
import 'post_create.dart';

class DetailScreen extends StatefulWidget {
  final int id;
  const DetailScreen({super.key, required this.id});
  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  String? _origin;
  int _reviewsRev = 0;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      body: FutureView(
        key: ValueKey(app.lang),
        load: () => app.api.get('/destinations/${widget.id}', query: {'lang': app.lang}),
        builder: (c, data, reload) {
          final d = Map<String, dynamic>.from(data as Map);
          final times = Map<String, dynamic>.from(d['access_times'] ?? {});
          _origin ??= times.keys.isNotEmpty ? times.keys.first : null;
          final notes = Map<String, dynamic>.from(d['access_notes'] ?? {});
          final rs = Map<String, dynamic>.from(d['rating_summary'] ?? {});
          return Column(children: [
            Expanded(
              child: CustomScrollView(slivers: [
                SliverAppBar(
                  pinned: true, expandedHeight: 280, backgroundColor: C.cream,
                  leading: Padding(
                    padding: const EdgeInsets.all(8),
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(onPressed: () => Navigator.of(context).pop(), icon: const LIcon('chevron-left', size: 22)),
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(fit: StackFit.expand, children: [
                      NetImg(d['image_url'] as String?),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(begin: Alignment.center, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0x99000000)]),
                        ),
                      ),
                      if (d['image_credit'] != null)
                        Positioned(left: 16, bottom: 8, child: Text('${d['image_credit']}', style: const TextStyle(color: Colors.white70, fontSize: 10))),
                    ]),
                  ),
                ),
                SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${d['name']}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Row(children: [
                          const LIcon('map-pin', size: 15, color: C.muted),
                          const SizedBox(width: 4),
                          Text('${d['region']}', style: const TextStyle(color: C.muted)),
                          const SizedBox(width: 12),
                          const Icon(Icons.star_rounded, color: C.gold, size: 18),
                          Text(' ${(d['rating'] as num) > 0 ? d['rating'] : '-'} (${d['review_count']})', style: const TextStyle(fontWeight: FontWeight.w700)),
                        ]),
                        const SizedBox(height: 12),
                        Text('${d['description']}', style: const TextStyle(height: 1.5)),
                        if (d['best_time'] != null) ...[
                          const SizedBox(height: 12),
                          Box(color: C.goldTint, child: Row(children: [
                            const LIcon('calendar-days', size: 18),
                            const SizedBox(width: 10),
                            Expanded(child: Text('${d['best_time']}', style: const TextStyle(fontWeight: FontWeight.w600))),
                          ])),
                        ],
                      ]),
                    ),
                    if (times.isNotEmpty) ...[
                      SectionTitle(t('access')),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(children: [
                          for (final o in times.keys) Pill('Dari $o', selected: _origin == o, onTap: () => setState(() => _origin = o)),
                        ]),
                      ),
                      const SizedBox(height: 10),
                      if (_origin != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(children: [
                            for (final v in [['car', 'Mobil', 'car'], ['bike', 'Motor', 'bus'], ['walk', 'Jalan kaki', 'footprints']])
                              if ((times[_origin] as Map?)?[v[0]] != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Box(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    LIcon(v[2], color: C.green),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Row(children: [
                                          Text(v[1], style: const TextStyle(fontWeight: FontWeight.w800)),
                                          const Spacer(),
                                          Text('≈ ${minutesLabel(((times[_origin] as Map)[v[0]] as num).toInt())}',
                                              style: const TextStyle(fontWeight: FontWeight.w800, color: C.green)),
                                        ]),
                                        if (notes[v[0]] != null) ...[
                                          const SizedBox(height: 4),
                                          Text('${notes[v[0]]}', style: const TextStyle(color: C.muted, fontSize: 13, height: 1.4)),
                                        ],
                                      ]),
                                    ),
                                  ])),
                                ),
                          ]),
                        ),
                    ],
                    _list(t('pros'), d['pros'], 'thumbs-up', C.green),
                    _list(t('cons'), d['cons'], 'shield-check', C.red),
                    if ((d['equipment'] as List?)?.isNotEmpty ?? false) ...[
                      SectionTitle(t('equipment')),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Wrap(spacing: 8, runSpacing: 8, children: [
                          for (final e in d['equipment'] as List)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(color: C.greenTint, borderRadius: BorderRadius.circular(16)),
                              child: Text('$e', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.green)),
                            ),
                        ]),
                      ),
                    ],
                    if ((d['eat_nearby'] as List?)?.isNotEmpty ?? false) ...[
                      SectionTitle(t('eat_nearby')),
                      for (final e in d['eat_nearby'] as List)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          child: Box(child: Row(children: [
                            const LIcon('utensils', color: C.gold),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('${e['name']}', style: const TextStyle(fontWeight: FontWeight.w800)),
                                Text('${e['note'] ?? ''}', style: const TextStyle(color: C.muted, fontSize: 13)),
                              ]),
                            ),
                            if (e['price'] != null) Text(rupiah(e['price'] as num), style: const TextStyle(fontWeight: FontWeight.w700)),
                          ])),
                        ),
                    ],
                    SectionTitle(t('reviews'),
                        trailing: TextButton(
                          onPressed: () async {
                            final ok = await go<bool>(context, PostCreateScreen(destinationId: widget.id, destinationName: '${d['name']}'));
                            if (ok == true) setState(() => _reviewsRev++);
                          },
                          child: const Text('Tulis ulasan'),
                        )),
                    _Reviews(key: ValueKey(_reviewsRev), id: widget.id, rs: rs),
                    const SizedBox(height: 20),
                  ]),
                ),
              ]),
            ),
            _BottomBar(d: d),
          ]);
        },
      ),
    );
  }

  Widget _list(String title, dynamic items, String icon, Color color) {
    final l = (items as List?) ?? [];
    if (l.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionTitle(title),
      for (final p in l)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.only(top: 2), child: LIcon(icon, size: 16, color: color)),
            const SizedBox(width: 10),
            Expanded(child: Text('$p', style: const TextStyle(height: 1.4))),
          ]),
        ),
    ]);
  }
}

class _BottomBar extends StatelessWidget {
  final Map<String, dynamic> d;
  const _BottomBar({required this.d});
  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: C.line))),
        child: Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(t('ticket'), style: const TextStyle(color: C.muted, fontSize: 12)),
            Text(rupiah(d['price_idr'] as num), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: C.red)),
          ]),
          const SizedBox(width: 14),
          SizedBox(
            width: 52,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
              onPressed: () => addToPlanSheet(context, (d['id'] as num).toInt()),
              child: const LIcon('clipboard-list', size: 22),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              onPressed: () => go(context, BookingScreen(destination: d)),
              child: Text(t('book_now')),
            ),
          ),
        ]),
      );
}

class _Reviews extends StatelessWidget {
  final int id;
  final Map<String, dynamic> rs;
  const _Reviews({super.key, required this.id, required this.rs});
  @override
  Widget build(BuildContext context) {
    final api = context.read<AppState>().api;
    return FutureBuilder<dynamic>(
      future: api.get('/destinations/$id/reviews'),
      builder: (c, s) {
        if (s.connectionState != ConnectionState.done) {
          return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(color: C.green)));
        }
        if (s.hasError) return Padding(padding: const EdgeInsets.all(20), child: Text(errText(s.error!)));
        final sum = Map<String, dynamic>.from(s.data['summary']);
        final posts = List<Map>.from((s.data['posts'] as List).map((e) => Map.from(e)));
        final bars = Map<String, dynamic>.from(sum['bars'] ?? {});
        return Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Box(child: Row(children: [
              Column(children: [
                Text('${sum['avg']}', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
                Stars((sum['avg'] as num)),
                Text('${sum['count']} ulasan', style: const TextStyle(color: C.muted, fontSize: 12)),
                if ((sum['guide_avg'] as num) > 0) Text('Pemandu ${sum['guide_avg']}', style: const TextStyle(color: C.green, fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(width: 18),
              Expanded(
                child: Column(children: [
                  for (final star in ['5', '4', '3', '2', '1'])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(children: [
                        Text(star, style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(value: ((bars[star] as num?) ?? 0) / 100, minHeight: 7, backgroundColor: C.line, color: C.gold),
                          ),
                        ),
                      ]),
                    ),
                ]),
              ),
            ])),
          ),
          const SizedBox(height: 12),
          if (posts.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text('Belum ada ulasan. Jadilah yang pertama!', style: TextStyle(color: C.muted))),
          for (final p in posts) PostCard(post: p),
        ]);
      },
    );
  }
}
