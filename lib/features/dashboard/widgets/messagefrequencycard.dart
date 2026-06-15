import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gp/core/services/can_service.dart';
import 'package:gp/core/theme/app_colors.dart';

class MessageFrequencyCard extends StatelessWidget {
  final double frequency;
  final List<CANMessage> messages;

  const MessageFrequencyCard({
    super.key,
    required this.frequency,
    required this.messages,
  });

  @override
  Widget build(BuildContext context) {
    final spots = _spots;
    final labels = _timeLabels;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.medDarkblueColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.gradblue, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "MESSAGE FREQUENCY",
                    style: TextStyle(
                      color: AppColors.greyColor,
                      fontSize: 11.sp,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    "${frequency.toStringAsFixed(frequency >= 100 ? 0 : 1)} Hz",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (frequency > 1000)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: AppColors.primaryred.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(
                      color: AppColors.primaryred.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    "High traffic",
                    style: TextStyle(
                      color: AppColors.primaryred,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 20.h),
          SizedBox(
            height: 160.h,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _maxY(spots) / 4,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: AppColors.gradblue.withValues(alpha: 0.8),
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 30,
                        reservedSize: 28.h,
                        getTitlesWidget: (value, meta) {
                          final index = (value / 30).round();
                          if (index < 0 || index >= labels.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: EdgeInsets.only(top: 10.h),
                            child: Text(
                              labels[index],
                              style: TextStyle(
                                color: AppColors.greyColor,
                                fontSize: 10.sp,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.4,
                      color: AppColors.secondaryblueColor,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.secondaryblueColor.withValues(
                              alpha: 0.35,
                            ),
                            AppColors.secondaryblueColor.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ],
                  minX: 0,
                  maxX: 60,
                  minY: 0,
                  maxY: _maxY(spots),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> get _spots {
    if (messages.isEmpty) return const [FlSpot(0, 0), FlSpot(60, 0)];
    final start = messages.first.timestamp;
    final computed = messages.map((message) {
      final x = (message.timestamp - start).clamp(0, 60).toDouble();
      final y = message.timeDiff > 0 ? 1 / message.timeDiff : frequency;
      return FlSpot(x, y.isFinite ? y : 0);
    }).toList();
    if (computed.length == 1) return [const FlSpot(0, 0), computed.first];
    return computed;
  }

  List<String> get _timeLabels {
    if (messages.isEmpty) return const ["--:--", "--:--", "--:--"];
    return [
      _formatTimestamp(messages.first.timestamp),
      _formatTimestamp(messages[messages.length ~/ 2].timestamp),
      _formatTimestamp(messages.last.timestamp),
    ];
  }

  double _maxY(List<FlSpot> spots) {
    final highest = spots.map((spot) => spot.y).fold<double>(frequency, (a, b) {
      return a > b ? a : b;
    });
    if (highest <= 0) return 10;
    return highest * 1.2;
  }

  String _formatTimestamp(double timestamp) {
    if (timestamp <= 0) return "--:--";
    final millis = timestamp > 1000000000000
        ? timestamp.toInt()
        : timestamp > 1000000000
        ? (timestamp * 1000).toInt()
        : null;
    if (millis == null) return "${timestamp.toStringAsFixed(1)}s";
    final date = DateTime.fromMillisecondsSinceEpoch(millis);
    return "${_twoDigits(date.hour)}:${_twoDigits(date.minute)}:${_twoDigits(date.second)}";
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
