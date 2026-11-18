import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../core/format.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'detail.dart';

/// Peta OpenStreetMap + wisata terdekat dari lokasimu.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _mc = MapController();
  LatLng? _me;
  List<Map> _items = [];
  Map? _selected;
  bool _loading = true;
  String? _err;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _locate() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;
      final p = await Geolocator.getCurrentPosition().timeout(const Duration(seconds: 8));
      _me = LatLng(p.latitude, p.longitude);
    } catch (_) {}
  }

  Future<void> _load() async {
    final app = context.read<AppState>();
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      await _locate();
      final q = <String, dynamic>{'lang': app.lang};
      if (_me != null) {
        q['lat'] = _me!.latitude;
        q['lng'] = _me!.longitude;
      }
      final r = await app.api.get('/destinations', query: q);
      _items = List<Map>.from((r as List).map((e) => Map.from(e)));
    } catch (e) {
      _err = errText(e);
    }
    if (mounted) setState(() => _loading = false);
  }

  void _select(Map d) {
    setState(() => _selected = d);
    _mc.move(LatLng((d['lat'] as num).toDouble(), (d['lng'] as num).toDouble()), 9);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Peta wisata'), actions: [
        IconButton(onPressed: _load, icon: const LIcon('navigation', size: 22)),
      ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: C.green))
          : _err != null
              ? Center(child: Text(_err!))
              : Column(children: [
                  Expanded(
                    flex: 5,
                    child: FlutterMap(
                      mapController: _mc,
                      options: MapOptions(initialCenter: const LatLng(-7.6, 112.5), initialZoom: 5.2),
                      children: [
                        TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'id.wisantara.wisantara'),
                        MarkerLayer(markers: [
                          for (final d in _items)
                            Marker(
                              point: LatLng((d['lat'] as num).toDouble(), (d['lng'] as num).toDouble()),
                              width: 44, height: 44,
                              child: GestureDetector(
                                onTap: () => _select(d),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _selected == d ? C.red : C.green, shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2.5),
                                  ),
                                  child: const Center(child: LIcon('map-pin', color: Colors.white, size: 20)),
                                ),
                              ),
                            ),
                          if (_me != null)
                            Marker(
                              point: _me!, width: 22, height: 22,
                              child: Container(decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3))),
                            ),
                        ]),
                        const RichAttributionWidget(attributions: [TextSourceAttribution('© OpenStreetMap contributors')]),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: ListView(padding: const EdgeInsets.only(top: 12, bottom: 16), children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                        child: Text(_me != null ? 'Wisata terdekat dari lokasimu' : 'Semua wisata (aktifkan lokasi untuk urutan terdekat)',
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                      for (final d in _items)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          child: Box(
                            color: _selected == d ? C.greenTint : Colors.white,
                            onTap: () => _select(d),
                            child: Row(children: [
                              NetImg(d['image_url'] as String?, width: 54, height: 54, radius: BorderRadius.circular(12)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('${d['name']}', style: const TextStyle(fontWeight: FontWeight.w800)),
                                  Text('${d['region']}${d['distance_km'] != null ? ' · ${d['distance_km']} km' : ''}',
                                      style: const TextStyle(color: C.muted, fontSize: 12.5)),
                                  Text(rupiah(d['price_idr'] as num), style: const TextStyle(color: C.red, fontWeight: FontWeight.w700, fontSize: 12.5)),
                                ]),
                              ),
                              IconButton(
                                onPressed: () => go(context, DetailScreen(id: (d['id'] as num).toInt())),
                                icon: const LIcon('chevron-right'),
                              ),
                            ]),
                          ),
                        ),
                    ]),
                  ),
                ]),
    );
  }
}
