import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/api.dart';
import '../core/format.dart';
import '../core/i18n.dart';
import '../core/theme.dart';

Future<T?> go<T>(BuildContext c, Widget page) => Navigator.of(c).push<T>(MaterialPageRoute(builder: (_) => page));

void toast(BuildContext c, String msg, {bool error = false}) {
  final m = ScaffoldMessenger.of(c);
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    content: Text(msg),
    backgroundColor: error ? C.red : C.brown,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ));
}

String errText(Object e) => e is ApiException ? e.message : 'Terjadi kesalahan. Coba lagi.';

/// Ikon Lucide dari assets/icons/<nama>.svg
class LIcon extends StatelessWidget {
  final String name;
  final double size;
  final Color color;
  const LIcon(this.name, {super.key, this.size = 22, this.color = C.brown});
  @override
  Widget build(BuildContext context) => SvgPicture.asset(
        'assets/icons/$name.svg',
        width: size,
        height: size,
        theme: SvgTheme(currentColor: color),
      );
}

/// Maskot kadal Wisantara. Pose: happy, jempol, berjalan, berpikir, loading, mainhp, menjelaskan, searching.
class Mascot extends StatelessWidget {
  final String pose;
  final double height;
  const Mascot(this.pose, {super.key, this.height = 140});
  @override
  Widget build(BuildContext context) => Image.asset('assets/mascots/$pose.png', height: height, fit: BoxFit.contain);
}

class NetImg extends StatelessWidget {
  final String? url;
  final double? width, height;
  final BorderRadius? radius;
  const NetImg(this.url, {super.key, this.width, this.height, this.radius});
  @override
  Widget build(BuildContext context) {
    final ph = Container(
      width: width, height: height, color: C.greenTint,
      child: const Center(child: LIcon('image', color: C.sage, size: 28)),
    );
    final img = (url == null || url!.isEmpty)
        ? ph
        : Image.network(url!, width: width, height: height, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => ph,
            loadingBuilder: (c, child, p) => p == null ? child : ph);
    return radius == null ? img : ClipRRect(borderRadius: radius!, child: img);
  }
}

class Stars extends StatelessWidget {
  final num value;
  final double size;
  const Stars(this.value, {super.key, this.size = 14});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 1; i <= 5; i++)
          Icon(i <= value.round() ? Icons.star_rounded : Icons.star_outline_rounded, size: size + 2, color: C.gold),
      ]);
}

class StarPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const StarPicker({super.key, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => Row(children: [
        for (var i = 1; i <= 5; i++)
          GestureDetector(
            onTap: () => onChanged(i),
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(i <= value ? Icons.star_rounded : Icons.star_outline_rounded, size: 34, color: C.gold),
            ),
          ),
      ]);
}

class Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final String? icon;
  const Pill(this.label, {super.key, this.selected = false, this.onTap, this.icon});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? C.green : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? C.green : C.line),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[LIcon(icon!, size: 15, color: selected ? Colors.white : C.brown), const SizedBox(width: 6)],
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? Colors.white : C.brown)),
          ]),
        ),
      );
}

class Box extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final VoidCallback? onTap;
  const Box({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.color = Colors.white, this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16), border: Border.all(color: C.line)),
          child: child,
        ),
      );
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
        child: Row(children: [
          Expanded(child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
          if (trailing != null) trailing!,
        ]),
      );
}

class EmptyView extends StatelessWidget {
  final String message;
  final String pose;
  const EmptyView(this.message, {super.key, this.pose = 'searching'});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Mascot(pose, height: 120),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: C.muted)),
          ]),
        ),
      );
}

/// Memuat data async dengan loading, error + coba lagi, dan reload.
class FutureView extends StatefulWidget {
  final Future<dynamic> Function() load;
  final Widget Function(BuildContext context, dynamic data, VoidCallback reload) builder;
  const FutureView({super.key, required this.load, required this.builder});
  @override
  State<FutureView> createState() => _FutureViewState();
}

class _FutureViewState extends State<FutureView> {
  late Future<dynamic> _f;
  @override
  void initState() {
    super.initState();
    _f = widget.load();
  }

  void _reload() => setState(() => _f = widget.load());

  @override
  Widget build(BuildContext context) => FutureBuilder<dynamic>(
        future: _f,
        builder: (c, s) {
          if (s.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: C.green));
          }
          if (s.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Mascot('berpikir', height: 110),
                  const SizedBox(height: 10),
                  Text(errText(s.error!), textAlign: TextAlign.center, style: const TextStyle(color: C.muted)),
                  const SizedBox(height: 14),
                  SizedBox(width: 160, child: FilledButton(onPressed: _reload, child: Text(t('retry')))),
                ]),
              ),
            );
          }
          return widget.builder(c, s.data, _reload);
        },
      );
}

/// Kartu destinasi dipakai di Jelajah, hasil rekomendasi, favorit.
class DestCard extends StatelessWidget {
  final Map d;
  final VoidCallback onTap;
  final Widget? footer;
  final Widget? trailing;
  const DestCard({super.key, required this.d, required this.onTap, this.footer, this.trailing});
  @override
  Widget build(BuildContext context) {
    final rating = (d['rating'] as num?) ?? 0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: C.line)),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            NetImg(d['image_url'] as String?, width: double.infinity, height: 150),
            Positioned(
              left: 10, top: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(.92), borderRadius: BorderRadius.circular(12)),
                child: Text('${d['category']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: C.green)),
              ),
            ),
            if (trailing != null) Positioned(right: 8, top: 8, child: trailing!),
          ]),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${d['name']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Row(children: [
                const LIcon('map-pin', size: 14, color: C.muted),
                const SizedBox(width: 4),
                Expanded(child: Text('${d['region']}', style: const TextStyle(color: C.muted, fontSize: 13))),
                if (d['distance_km'] != null) Text('${d['distance_km']} km', style: const TextStyle(color: C.muted, fontSize: 12)),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.star_rounded, color: C.gold, size: 18),
                const SizedBox(width: 2),
                Text(rating > 0 ? '$rating' : '-', style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('  (${d['review_count'] ?? 0})', style: const TextStyle(color: C.muted, fontSize: 12)),
                const Spacer(),
                Text(rupiah((d['price_idr'] as num?) ?? 0), style: const TextStyle(fontWeight: FontWeight.w800, color: C.red)),
              ]),
              if (footer != null) ...[const SizedBox(height: 10), footer!],
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Baris label-nilai sederhana.
class KV extends StatelessWidget {
  final String k, v;
  final bool bold;
  const KV(this.k, this.v, {super.key, this.bold = false});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Expanded(child: Text(k, style: TextStyle(color: bold ? C.text : C.muted, fontWeight: bold ? FontWeight.w800 : FontWeight.w400))),
          Text(v, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: bold ? C.red : C.text)),
        ]),
      );
}

Future<DateTime?> pickDate(BuildContext c, {DateTime? initial}) => showDatePicker(
      context: c,
      initialDate: initial ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );

String langName(String code) => I18n.names[code] ?? code;
