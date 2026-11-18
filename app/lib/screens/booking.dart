import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/format.dart';
import '../core/i18n.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'guides.dart';

/// Langkah 1: pilih tanggal, jumlah tiket, dan pemandu (opsional).
class BookingScreen extends StatefulWidget {
  final Map<String, dynamic> destination;
  const BookingScreen({super.key, required this.destination});
  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? _date;
  int _qty = 1;
  Map? _guide;
  bool _busy = false;
  static const _svc = 5000;

  int get _sub => (widget.destination['price_idr'] as num).toInt() * _qty;
  int get _guideFee => _guide == null ? 0 : (_guide!['price_idr'] as num).toInt();

  Future<void> _create() async {
    if (_date == null) {
      toast(context, 'Pilih tanggal kunjungan dulu', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final b = await context.read<AppState>().api.post('/bookings', {
        'destination_id': widget.destination['id'],
        'visit_date': isoDate(_date!),
        'qty': _qty,
        if (_guide != null) 'guide_id': _guide!['id'],
      });
      if (!mounted) return;
      context.read<AppState>().bump();
      await Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => CheckoutScreen(booking: Map<String, dynamic>.from(b))));
    } catch (e) {
      if (mounted) toast(context, errText(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.destination;
    return Scaffold(
      appBar: AppBar(title: Text(t('book_now'))),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 30), children: [
        Box(child: Row(children: [
          NetImg(d['image_url'] as String?, width: 64, height: 64, radius: BorderRadius.circular(12)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${d['name']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              Text('${d['region']}', style: const TextStyle(color: C.muted)),
            ]),
          ),
        ])),
        const SizedBox(height: 16),
        const Text('Tanggal kunjungan', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Box(
          onTap: () async {
            final v = await pickDate(context, initial: _date);
            if (v != null) setState(() => _date = v);
          },
          child: Row(children: [
            const LIcon('calendar-days', color: C.green),
            const SizedBox(width: 12),
            Text(_date == null ? 'Pilih tanggal' : tgl(isoDate(_date!)), style: TextStyle(fontWeight: FontWeight.w700, color: _date == null ? C.muted : C.text)),
          ]),
        ),
        const SizedBox(height: 16),
        Row(children: [
          const Expanded(child: Text('Jumlah tiket', style: TextStyle(fontWeight: FontWeight.w800))),
          IconButton(onPressed: _qty > 1 ? () => setState(() => _qty--) : null, icon: const Icon(Icons.remove_circle_outline, color: C.green)),
          Text('$_qty', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          IconButton(onPressed: _qty < 20 ? () => setState(() => _qty++) : null, icon: const Icon(Icons.add_circle_outline, color: C.green)),
        ]),
        const SizedBox(height: 8),
        const Text('Pemandu (opsional)', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Box(
          onTap: () async {
            final g = await go<Map>(context, const GuidesScreen(pick: true));
            if (g != null) setState(() => _guide = g);
          },
          child: Row(children: [
            const LIcon('users', color: C.green),
            const SizedBox(width: 12),
            Expanded(child: Text(_guide == null ? 'Tanpa pemandu · pilih' : '${_guide!['name']} · ${rupiah(_guide!['price_idr'] as num)}', style: const TextStyle(fontWeight: FontWeight.w700))),
            if (_guide != null)
              GestureDetector(onTap: () => setState(() => _guide = null), child: const Icon(Icons.close, color: C.muted, size: 20))
            else
              const LIcon('chevron-right'),
          ]),
        ),
        const SizedBox(height: 20),
        Box(color: C.goldTint, child: Column(children: [
          KV('Tiket × $_qty', rupiah(_sub)),
          KV('Pemandu', rupiah(_guideFee)),
          KV('Biaya layanan', rupiah(_svc)),
          const Divider(),
          KV(t('total'), rupiah(_sub + _guideFee + _svc), bold: true),
        ])),
        const SizedBox(height: 20),
        FilledButton(onPressed: _busy ? null : _create, child: Text(_busy ? '…' : 'Lanjut ke pembayaran')),
      ]),
    );
  }
}

/// Langkah 2: pilih metode pembayaran (simulasi).
class CheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  const CheckoutScreen({super.key, required this.booking});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _method = 'qris';
  bool _busy = false;

  static const _methods = [
    ['qris', 'QRIS', 'Scan dari aplikasi bank/e-wallet apa pun', 'qr-code'],
    ['va', 'Virtual Account', 'BCA, Mandiri, BNI, BRI', 'building-2'],
    ['ewallet', 'E-Wallet', 'GoPay, OVO, DANA, ShopeePay', 'smartphone'],
    ['card', 'Kartu debit/kredit', 'Visa, Mastercard, JCB', 'credit-card'],
  ];

  Future<void> _pay() async {
    setState(() => _busy = true);
    try {
      await Future.delayed(const Duration(milliseconds: 900)); // simulasi proses gateway
      final r = await context.read<AppState>().api.post('/bookings/${widget.booking['id']}/pay', {'method': _method});
      if (!mounted) return;
      context.read<AppState>().bump();
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => SuccessScreen(booking: Map<String, dynamic>.from(r))));
    } catch (e) {
      if (mounted) toast(context, errText(e), error: true);
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 30), children: [
        Box(color: C.goldTint, child: Column(children: [
          KV('Kode pesanan', '${b['code']}'),
          KV('Wisata', '${b['destination_name']}'),
          KV('Tanggal', tgl(b['visit_date'] as String?)),
          KV('Tiket × ${b['qty']}', rupiah(b['subtotal'] as num)),
          if ((b['guide_fee'] as num) > 0) KV('Pemandu ${b['guide_name'] ?? ''}', rupiah(b['guide_fee'] as num)),
          KV('Biaya layanan', rupiah(b['service_fee'] as num)),
          const Divider(),
          KV(t('total'), rupiah(b['total'] as num), bold: true),
        ])),
        const SizedBox(height: 18),
        const Text('Metode pembayaran', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        for (final m in _methods)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Box(
              color: _method == m[0] ? C.greenTint : Colors.white,
              onTap: () => setState(() => _method = m[0]),
              child: Row(children: [
                LIcon(m[3], color: C.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(m[1], style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(m[2], style: const TextStyle(color: C.muted, fontSize: 12.5)),
                  ]),
                ),
                Icon(_method == m[0] ? Icons.radio_button_checked : Icons.radio_button_off, color: C.green),
              ]),
            ),
          ),
        const SizedBox(height: 6),
        const Text('Mode demo: pembayaran disimulasikan, tidak ada uang sungguhan yang diproses.', style: TextStyle(fontSize: 12, color: C.muted)),
        const SizedBox(height: 16),
        FilledButton(onPressed: _busy ? null : _pay, child: Text(_busy ? 'Memproses…' : '${t('pay_now')} · ${rupiah(b['total'] as num)}')),
      ]),
    );
  }
}

/// Langkah 3: tiket dengan QR.
class SuccessScreen extends StatelessWidget {
  final Map<String, dynamic> booking;
  const SuccessScreen({super.key, required this.booking});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(automaticallyImplyLeading: false, title: const Text('Pembayaran berhasil')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          const Center(child: Mascot('jempol', height: 130)),
          const SizedBox(height: 8),
          const Center(child: Text('Terima kasih! Tiketmu sudah aktif.', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17))),
          const SizedBox(height: 18),
          TicketCard(booking: booking),
          const SizedBox(height: 18),
          FilledButton(onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst), child: const Text('Selesai')),
        ]),
      );
}

class TicketCard extends StatelessWidget {
  final Map booking;
  const TicketCard({super.key, required this.booking});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: C.line)),
        child: Column(children: [
          Text('${booking['destination_name']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          Text('${booking['region']}', style: const TextStyle(color: C.muted)),
          const SizedBox(height: 14),
          QrImageView(data: 'WISANTARA|${booking['code']}|${booking['visit_date']}|${booking['qty']}', size: 170, eyeStyle: const QrEyeStyle(color: C.brown, eyeShape: QrEyeShape.square), dataModuleStyle: const QrDataModuleStyle(color: C.brown, dataModuleShape: QrDataModuleShape.square)),
          const SizedBox(height: 8),
          Text('${booking['code']}', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 18)),
          const Divider(height: 24),
          KV('Tanggal', tgl(booking['visit_date'] as String?)),
          KV('Jumlah', '${booking['qty']} tiket'),
          if (booking['guide_name'] != null) KV('Pemandu', '${booking['guide_name']}'),
          KV(t('total'), rupiah(booking['total'] as num), bold: true),
          if (booking['payment_ref'] != null) KV('Ref. pembayaran', '${booking['payment_ref']}'),
        ]),
      );
}
