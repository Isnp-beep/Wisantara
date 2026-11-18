import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/format.dart';
import '../core/i18n.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'booking.dart';

class OrdersTab extends StatelessWidget {
  const OrdersTab({super.key});
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return SafeArea(
      bottom: false,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 18, 20, 12), child: Text(t('orders'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900))),
        Expanded(
          child: FutureView(
            load: () => app.api.get('/bookings'),
            builder: (c, data, reload) {
              final list = List<Map>.from((data as List).map((e) => Map.from(e)));
              if (list.isEmpty) return EmptyView('Belum ada pesanan. Yuk pesan tiket wisata pertamamu!', pose: 'berjalan');
              return RefreshIndicator(
                color: C.green,
                onRefresh: () async => reload(),
                child: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), children: [
                  for (final b in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Box(
                        onTap: () async {
                          final m = Map<String, dynamic>.from(b);
                          if (b['status'] == 'paid') {
                            await go(context, _TicketScreen(booking: m));
                          } else if (b['status'] == 'pending') {
                            await go(context, CheckoutScreen(booking: m));
                          }
                          reload();
                        },
                        child: Row(children: [
                          NetImg(b['image_url'] as String?, width: 64, height: 64, radius: BorderRadius.circular(12)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('${b['destination_name']}', style: const TextStyle(fontWeight: FontWeight.w800)),
                              Text('${tgl(b['visit_date'] as String?)} · ${b['qty']} tiket', style: const TextStyle(color: C.muted, fontSize: 12.5)),
                              Text(rupiah(b['total'] as num), style: const TextStyle(color: C.red, fontWeight: FontWeight.w800)),
                            ]),
                          ),
                          _StatusChip('${b['status']}'),
                        ]),
                      ),
                    ),
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String s;
  const _StatusChip(this.s);
  @override
  Widget build(BuildContext context) {
    final paid = s == 'paid', cancelled = s == 'cancelled';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: paid ? C.greenTint : (cancelled ? const Color(0xFFEEE7E0) : C.goldTint), borderRadius: BorderRadius.circular(12)),
      child: Text(paid ? t('paid') : (cancelled ? 'Batal' : t('pending')),
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: paid ? C.green : (cancelled ? C.muted : C.brown))),
    );
  }
}

class _TicketScreen extends StatelessWidget {
  final Map<String, dynamic> booking;
  const _TicketScreen({required this.booking});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('E-Tiket')),
        body: ListView(padding: const EdgeInsets.all(20), children: [TicketCard(booking: booking)]),
      );
}
