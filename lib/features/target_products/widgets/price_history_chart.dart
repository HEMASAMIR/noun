import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class PriceHistoryChart extends StatelessWidget {
  final List<double> prices;
  final double height;

  const PriceHistoryChart({
    Key? key,
    required this.prices,
    this.height = 150,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (prices.length < 2) {
      return Container(
        height: height,
        alignment: Alignment.center,
        child: const Text(
          'لا يوجد بيانات كافية للرسم البياني',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      );
    }

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: CustomPaint(
        size: Size(double.infinity, height),
        painter: _LineChartPainter(prices),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> prices;

  _LineChartPainter(this.prices);

  @override
  void paint(Canvas canvas, Size size) {
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final range = maxPrice - minPrice == 0 ? 1.0 : maxPrice - minPrice;

    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withOpacity(0.3),
          AppColors.primary.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    final stepX = size.width / (prices.length - 1);
    
    for (int i = 0; i < prices.length; i++) {
      final x = i * stepX;
      final y = size.height - ((prices[i] - minPrice) / range * size.height * 0.8) - (size.height * 0.1);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
        if (i == prices.length - 1) {
          fillPath.lineTo(x, size.height);
          fillPath.close();
        }
      }
    }

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
    
    // Draw points
    final dotPaint = Paint()..color = AppColors.primary;
    final dotBorderPaint = Paint()..color = Colors.white;
    
    for (int i = 0; i < prices.length; i++) {
      final x = i * stepX;
      final y = size.height - ((prices[i] - minPrice) / range * size.height * 0.8) - (size.height * 0.1);
      
      canvas.drawCircle(Offset(x, y), 5, dotBorderPaint);
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
