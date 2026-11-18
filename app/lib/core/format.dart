String rupiah(num v) {
  final s = v.round().abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return '${v < 0 ? '-' : ''}Rp $b';
}

const _bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

/// "2027-01-10" -> "10 Jan 2027"
String tgl(String? iso) {
  if (iso == null || iso.length < 10) return '-';
  final p = iso.substring(0, 10).split('-');
  return '${int.parse(p[2])} ${_bulan[int.parse(p[1]) - 1]} ${p[0]}';
}

String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String minutesLabel(int m) {
  if (m < 60) return '$m mnt';
  final h = m ~/ 60, r = m % 60;
  return r == 0 ? '$h jam' : '$h jam $r mnt';
}

String ago(String? ts) {
  if (ts == null) return '';
  final d = DateTime.tryParse(ts.replaceFirst(' ', 'T'));
  if (d == null) return '';
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'baru saja';
  if (diff.inHours < 1) return '${diff.inMinutes} mnt lalu';
  if (diff.inDays < 1) return '${diff.inHours} jam lalu';
  if (diff.inDays < 7) return '${diff.inDays} hari lalu';
  return tgl(ts);
}
