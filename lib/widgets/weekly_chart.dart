import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import '../providers/life_provider.dart';
import '../utils/constants.dart';

enum ChartFilter { week, month, year }

class WeeklyChart extends StatefulWidget {
  const WeeklyChart({Key? key}) : super(key: key);

  @override
  State<WeeklyChart> createState() => _WeeklyChartState();
}

class _WeeklyChartState extends State<WeeklyChart> {
  ChartFilter filter = ChartFilter.week;

  @override
  Widget build(BuildContext context) {
    return Consumer<LifeProvider>(
      builder: (context, provider, child) {
        Map<DateTime, double> data;
        switch (filter) {
          case ChartFilter.week:
            data = provider.getWeeklyProgress();
            break;
          case ChartFilter.month:
            data = provider.getMonthlyProgress();
            break;
          case ChartFilter.year:
            data = provider.getYearlyProgress();
            break;
        }

        if (data.isEmpty) return const SizedBox.shrink();

        var sortedEntries = data.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
        
        List<double> values = sortedEntries.map((e) => e.value).toList();
        List<String> labels = [];

        if (filter == ChartFilter.week) {
          labels = sortedEntries.map((e) => DateFormat('E').format(e.key).substring(0, 1)).toList();
        } else if (filter == ChartFilter.month) {
          for (int i = 0; i < sortedEntries.length; i++) {
            if (i % 5 == 0 || i == sortedEntries.length - 1) {
              labels.add(DateFormat('d').format(sortedEntries[i].key));
            } else {
              labels.add("");
            }
          }
        } else {
          // Yearly: Show 3-letter Month names (Jan, Feb...)
          labels = sortedEntries.map((e) => DateFormat('MMM').format(e.key)).toList();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 8,
            shadowColor: Colors.black.withOpacity(0.05),
            color: Theme.of(context).cardColor,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text(
                        "Performance", 
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 18,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                          letterSpacing: -0.5
                        )
                      ),
                      
                      // Toggle Switch
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).dividerColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1))
                        ),
                        child: Row(
                          children: [
                            _buildToggleOption(ChartFilter.week),
                            _buildToggleOption(ChartFilter.month),
                            _buildToggleOption(ChartFilter.year),
                          ],
                        ),
                      )
                     ],
                   ),
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    height: 160,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _ChartPainter(
                        values: values, 
                        labels: labels, 
                        isWeekly: filter == ChartFilter.week,
                        isYearly: filter == ChartFilter.year,
                        theme: Theme.of(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildToggleOption(ChartFilter option) {
    final isSelected = filter == option;
    final String text = option.name[0].toUpperCase() + option.name.substring(1);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          filter = option;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).cardColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2)
            )
          ] : [],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Theme.of(context).textTheme.bodyLarge?.color : Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final bool isWeekly;
  final bool isYearly;
  final ThemeData theme;
 
   _ChartPainter({
    required this.values, 
    required this.labels, 
    required this.isWeekly, 
    this.isYearly = false,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final paintLine = Paint()
      ..color = AppColors.sectionSkill
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final textStyle = TextStyle(
      color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
      fontSize: 11,
      fontWeight: FontWeight.w600,
    );

    double w = size.width;
    double h = size.height;
    double bottomMargin = 20.0;
    double leftMargin = 30.0; // Space for Y-axis labels
    double graphHeight = h - bottomMargin;
    double graphWidth = w - leftMargin;
    
    double stepW = graphWidth / (values.length - 1);
    
    // Y-Axis Labels & Grid Lines
    final mainGridPaint = Paint()
      ..color = theme.dividerColor.withOpacity(0.1)
      ..strokeWidth = 1.0; 
    
    final minorGridPaint = Paint()
      ..color = theme.dividerColor.withOpacity(0.05)
      ..strokeWidth = 0.5;
      
    final axisLabelStyle = TextStyle(
      color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
      fontSize: 9,
      fontWeight: FontWeight.w500,
    );

    // Draw Grid Lines every 10%
    for (int i = 0; i <= 10; i++) {
      double level = i / 10.0;
      double y = graphHeight - (level * graphHeight);
      
      // Draw grid line (slightly darker for major 0, 50, 100)
      bool isMajor = (i % 5 == 0); 
      
      canvas.drawLine(
        Offset(leftMargin, y), 
        Offset(w, y), 
        isMajor ? mainGridPaint : minorGridPaint
      );
      
      // Draw Label for EVERY 10% step
      String labelText = "${(level * 100).toInt()}%";
      TextPainter tp = TextPainter(
        text: TextSpan(style: axisLabelStyle, text: labelText),
        textAlign: TextAlign.right,
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftMargin - tp.width - 6, y - tp.height / 2));
    }

    // Build Path
    Path path = Path();
    List<Offset> points = [];
    
    bool isFirstValid = true;
    for (int i = 0; i < values.length; i++) {
      double x = leftMargin + i * stepW;
      double val = values[i];

      double y = graphHeight - (val * graphHeight); 
      points.add(Offset(x, y));
      
      if (isFirstValid) {
        path.moveTo(x, y);
        isFirstValid = false;
      } else {
        double prevX = points[i-1].dx;
        double prevY = points[i-1].dy;
        double cp1x = prevX + (x - prevX) / 2;
        double cp1y = prevY;
        double cp2x = prevX + (x - prevX) / 2;
        double cp2y = y;
        path.cubicTo(cp1x, cp1y, cp2x, cp2y, x, y);
      }
    }
    
    // Draw Line
    canvas.drawPath(path, paintLine);
    
    // Draw Dots & Labels (X-Axis)
    for (int i = 0; i < points.length; i++) {
      Offset p = points[i];
      double val = values[i];

      // Draw Dot logic
      bool shouldDrawDot = false;
      if (isWeekly) {
         shouldDrawDot = val > 0 || i == points.length - 1;
      } else if (isYearly) {
         shouldDrawDot = val > 0;
      } else {
         shouldDrawDot = (labels[i].isNotEmpty && val > 0) || i == points.length - 1;
      }

      if (shouldDrawDot) {
        // Determine Award Color & Glow
        Color dotColor;
        Color glowColor;
        double radius = 5.0;
        bool isSpecial = false;

        if (val >= 1.0) {
          dotColor = Colors.amber[700]!; // Gold
          glowColor = Colors.amber.withOpacity(0.5);
          radius = 7.0;
          isSpecial = true;
        } else if (val >= 0.75) {
          dotColor = Colors.blueGrey[400]!; // Silver/Premium
          glowColor = Colors.blueGrey.withOpacity(0.4);
          radius = 6.0;
          isSpecial = true;
        } else if (val >= 0.5) {
          dotColor = Colors.orange[400]!; // Bronze/Amber
          glowColor = Colors.orange.withOpacity(0.3);
          radius = 5.5;
          isSpecial = true;
        } else {
          dotColor = AppColors.sectionSkillDark;
          glowColor = Colors.transparent;
        }

        // Draw Glow if special
        if (isSpecial) {
          canvas.drawCircle(p, radius + 4, Paint()..color = glowColor..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
        }

        // Draw Main Dot
        final paintAward = Paint()
          ..color = dotColor
          ..style = PaintingStyle.fill;
        
        final paintAwardBorder = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

        canvas.drawCircle(p, radius, paintAward); 
        canvas.drawCircle(p, radius, paintAwardBorder);

        // Draw an inner white "shine" for special dots
        if (isSpecial) {
          canvas.drawCircle(p.translate(-radius/3, -radius/3), radius/4, Paint()..color = Colors.white.withOpacity(0.8));
        }

         // Draw exact value above the dot
         String valueText = "${(val * 100).toStringAsFixed(0)}%";
         TextPainter valueTp = TextPainter(
           text: TextSpan(
             text: valueText,
             style: TextStyle(
               color: isSpecial ? dotColor : AppColors.sectionSkillDark,
               fontSize: isSpecial ? 10 : 9,
               fontWeight: isSpecial ? FontWeight.w900 : FontWeight.bold,
             ),
           ),
           textDirection: TextDirection.ltr,
         )..layout();
         // Position above the dot
         valueTp.paint(canvas, Offset(p.dx - valueTp.width / 2, p.dy - valueTp.height - (isSpecial ? 10 : 6)));
      }
      
      // Draw Label
      if (labels[i].isNotEmpty) {
        TextSpan span = TextSpan(style: textStyle, text: labels[i]);
        TextPainter tp = TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
        tp.layout();
        tp.paint(canvas, Offset(p.dx - tp.width / 2, graphHeight + 12));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
