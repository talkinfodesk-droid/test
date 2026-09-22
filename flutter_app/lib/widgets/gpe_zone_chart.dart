import 'package:flutter/material.dart';

import '../models/workout_models.dart';
import '../theme/app_theme.dart';

/// "GPE Per Training": horizontal effort bands (Too easy -> Overdo), a
/// min/max candle per session and a dot on the session mean, joined by a line.
class GpeZoneChart extends StatelessWidget {
  const GpeZoneChart({super.key, required this.sessions, this.height = 220});

  final List<TrainingSession> sessions;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _GpePainter(sessions)),
    );
  }
}

class _GpePainter extends CustomPainter {
  _GpePainter(this.sessions);

  final List<TrainingSession> sessions;

  static const double _maxGpe = 3.0;
  static const double _labelWidth = 56;
  static const double _axisHeight = 34;

  static Color zoneColor(GpeZone zone) => switch (zone) {
        GpeZone.tooEasy => AppColors.red,
        GpeZone.light => AppColors.yellow,
        GpeZone.optimal => AppColors.green,
        GpeZone.heavy => AppColors.orange,
        GpeZone.overdo => AppColors.red,
      };

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTWH(
      _labelWidth,
      8,
      size.width - _labelWidth - 8,
      size.height - _axisHeight - 8,
    );

    double yFor(double gpe) => plot.bottom - (gpe / _maxGpe) * plot.height;

    // Zone bands + labels.
    for (final zone in GpeZone.values) {
      final top = yFor(zone.to);
      final bottom = yFor(zone.from);
      final color = zoneColor(zone);
      canvas.drawRect(
        Rect.fromLTRB(plot.left, top, plot.right, bottom),
        Paint()
          ..color =
              color.withValues(alpha: zone == GpeZone.optimal ? 0.16 : 0.07),
      );
      canvas.drawLine(
        Offset(plot.left, bottom),
        Offset(plot.right, bottom),
        Paint()
          ..color = AppColors.divider
          ..strokeWidth = 1,
      );
      _text(
        canvas,
        zone.label,
        Offset(0, (top + bottom) / 2 - 7),
        TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
            fontFamily: _font),
        maxWidth: _labelWidth - 6,
      );
    }

    if (sessions.isEmpty) return;
    final step = sessions.length == 1 ? 0 : plot.width / (sessions.length - 1);
    double xFor(int i) => plot.left + step * i;

    // Candles (min-max range).
    for (var i = 0; i < sessions.length; i++) {
      final s = sessions[i];
      final x = xFor(i);
      final color = zoneColor(GpeZone.forValue(s.gpeMean));
      canvas.drawLine(
        Offset(x, yFor(s.gpeMin)),
        Offset(x, yFor(s.gpeMax)),
        Paint()
          ..color = color.withValues(alpha: 0.55)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }

    // Mean line.
    final path = Path();
    for (var i = 0; i < sessions.length; i++) {
      final p = Offset(xFor(i), yFor(sessions[i].gpeMean));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Mean dots.
    for (var i = 0; i < sessions.length; i++) {
      final s = sessions[i];
      final p = Offset(xFor(i), yFor(s.gpeMean));
      final color = zoneColor(GpeZone.forValue(s.gpeMean));
      canvas.drawCircle(p, 4.5, Paint()..color = color);
      canvas.drawCircle(
        p,
        4.5,
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    _drawDateAxis(canvas, sessions, plot, size, xFor);
  }

  @override
  bool shouldRepaint(covariant _GpePainter old) => old.sessions != sessions;
}

/// "Total Power Per Training": a blue min/max band with a white mean line.
class PowerBandChart extends StatelessWidget {
  const PowerBandChart({super.key, required this.sessions, this.height = 200});

  final List<TrainingSession> sessions;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _PowerPainter(sessions)),
    );
  }
}

class _PowerPainter extends CustomPainter {
  _PowerPainter(this.sessions);

  final List<TrainingSession> sessions;

  static const double _axisHeight = 34;

  @override
  void paint(Canvas canvas, Size size) {
    if (sessions.isEmpty) return;
    final plot =
        Rect.fromLTWH(8, 12, size.width - 16, size.height - _axisHeight - 12);

    var maxP = 0.0;
    for (final s in sessions) {
      if (s.powerMax > maxP) maxP = s.powerMax;
    }
    maxP = maxP * 1.1;

    double yFor(double p) => plot.bottom - (p / maxP) * plot.height;
    final step = sessions.length == 1 ? 0 : plot.width / (sessions.length - 1);
    double xFor(int i) => plot.left + step * i;

    // Blue band between min and max.
    final band = Path()..moveTo(xFor(0), yFor(sessions[0].powerMax));
    for (var i = 1; i < sessions.length; i++) {
      band.lineTo(xFor(i), yFor(sessions[i].powerMax));
    }
    for (var i = sessions.length - 1; i >= 0; i--) {
      band.lineTo(xFor(i), yFor(sessions[i].powerMin));
    }
    band.close();
    canvas.drawPath(
        band, Paint()..color = AppColors.blue.withValues(alpha: 0.85));

    // Mean line + dots.
    final line = Path();
    for (var i = 0; i < sessions.length; i++) {
      final p = Offset(xFor(i), yFor(sessions[i].powerMean));
      if (i == 0) {
        line.moveTo(p.dx, p.dy);
      } else {
        line.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    for (var i = 0; i < sessions.length; i++) {
      final p = Offset(xFor(i), yFor(sessions[i].powerMean));
      canvas.drawCircle(p, 4, Paint()..color = AppColors.blue);
      canvas.drawCircle(
        p,
        4,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    _drawDateAxis(canvas, sessions, plot, size, xFor);
  }

  @override
  bool shouldRepaint(covariant _PowerPainter old) => old.sessions != sessions;
}

/// Match the app theme so canvas text renders with the same face as widgets.
const _font = 'Roboto';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

void _drawDateAxis(
  Canvas canvas,
  List<TrainingSession> sessions,
  Rect plot,
  Size size,
  double Function(int) xFor,
) {
  const ticks = 5;
  if (sessions.length < 2) return;
  for (var t = 0; t < ticks; t++) {
    final i = ((sessions.length - 1) * t / (ticks - 1)).round();
    final d = sessions[i].date;
    final x = xFor(i);
    _text(
      canvas,
      '${_months[d.month - 1]}\n${d.day}',
      Offset(x - 20, plot.bottom + 6),
      const TextStyle(
          fontSize: 10,
          color: AppColors.textSecondary,
          height: 1.2,
          fontFamily: _font),
      maxWidth: 40,
      align: TextAlign.center,
    );
  }
}

void _text(
  Canvas canvas,
  String text,
  Offset at,
  TextStyle style, {
  required double maxWidth,
  TextAlign align = TextAlign.left,
}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textAlign: align,
    maxLines: 2,
    ellipsis: '…',
  )..layout(
      maxWidth: maxWidth, minWidth: align == TextAlign.center ? maxWidth : 0);
  tp.paint(canvas, at);
}
