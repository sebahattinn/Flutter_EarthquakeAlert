import 'package:intl/intl.dart';

/// API'lerden gelen farklı tarih tiplerini güvenli şekilde UTC'ye çevirir.
/// Örnekler:
/// - "2025.08.27 14:12:36"  (Kandilli/AFAD benzeri, timezone yok)
/// - "2025-08-27 14:12:36"
/// - "2025-08-27T11:12:36Z" (ISO-8601)
/// - "1724751156" veya "1724751156000" (epoch s/ms)
DateTime parseQuakeDate(String raw) {
  if (raw.isEmpty) {
    throw const FormatException('Empty date string');
  }
  final s = raw.trim();

  // 0) Epoch (saniye veya milis)
  final onlyDigits = RegExp(r'^\d+$');
  if (onlyDigits.hasMatch(s)) {
    if (s.length <= 10) {
      final secs = int.parse(s);
      return DateTime.fromMillisecondsSinceEpoch(secs * 1000, isUtc: true);
    } else {
      final ms = int.parse(s);
      return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    }
  }

  // 1) ISO-8601 ise doğrudan parse
  if (s.contains('T') || s.contains('Z') || s.contains('+')) {
    final dt = DateTime.parse(s);
    return dt.isUtc ? dt : dt.toUtc();
  }

  // 2) "yyyy.MM.dd HH:mm[:ss]" veya "yyyy-MM-dd HH:mm[:ss]" (yıl-önce)
  final ymd = RegExp(
      r'^(\d{4})[.\-\/](\d{2})[.\-\/](\d{2})[ T](\d{2}):(\d{2})(?::(\d{2}))?$');
  final m1 = ymd.firstMatch(s);
  if (m1 != null) {
    final y = m1.group(1)!;
    final mo = m1.group(2)!;
    final d = m1.group(3)!;
    final hh = m1.group(4)!;
    final mm = m1.group(5)!;
    final ss = m1.group(6) ?? '00';
    // Türkiye saatini varsay (UTC+03:00), sonra UTC'ye çevir
    final iso = '$y-$mo-$d'
        'T$hh:$mm:$ss'
        '+03:00';
    return DateTime.parse(iso).toUtc();
  }

  // 3) "dd.MM.yyyy HH:mm[:ss]" (gün-önce)
  final dmy = RegExp(
      r'^(\d{2})[.\-\/](\d{2})[.\-\/](\d{4})[ T](\d{2}):(\d{2})(?::(\d{2}))?$');
  final m2 = dmy.firstMatch(s);
  if (m2 != null) {
    final d = m2.group(1)!;
    final mo = m2.group(2)!;
    final y = m2.group(3)!;
    final hh = m2.group(4)!;
    final mm = m2.group(5)!;
    final ss = m2.group(6) ?? '00';
    final iso = '$y-$mo-$d'
        'T$hh:$mm:$ss'
        '+03:00';
    return DateTime.parse(iso).toUtc();
  }

  // 4) Son çare: Intl ile yaygın kalıplar
  for (final p in const [
    'yyyy.MM.dd HH:mm:ss',
    'dd.MM.yyyy HH:mm:ss',
    'yyyy-MM-dd HH:mm:ss',
    'dd-MM-yyyy HH:mm:ss',
    'yyyy/MM/dd HH:mm:ss',
    'dd/MM/yyyy HH:mm:ss',
    'yyyy.MM.dd HH:mm',
    'yyyy-MM-dd HH:mm',
  ]) {
    try {
      final local = DateFormat(p).parseStrict(s);
      // TR yerel saat → UTC
      return local.toUtc().subtract(DateTime.timestamp().timeZoneOffset);
    } catch (_) {/* geç */}
  }

  // 5) Noktaları çizgiye çevirip ISO deneyelim
  final fixed = s.replaceFirstMapped(
    RegExp(r'^(\d{4})[./-](\d{2})[./-](\d{2})'),
    (m) => '${m[1]}-${m[2]}-${m[3]}',
  );
  try {
    final dt = DateTime.parse(fixed);
    return dt.isUtc ? dt : dt.toUtc();
  } catch (_) {
    throw FormatException('Unsupported date format: $raw');
  }
}

/// UI için kısa saat formatı
String formatQuakeTimeLocal(DateTime utc) =>
    DateFormat('HH:mm dd.MM.yyyy').format(utc.toLocal());
