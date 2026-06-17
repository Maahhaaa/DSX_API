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
    final series = _series;
    final allSpots = series.expand((item) => item.points.map((e) => e.spot));
    final labels = _timeLabels;
    final maxY = _maxY(allSpots);
    final yInterval = maxY / 4;

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
                    horizontalInterval: yInterval,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: AppColors.gradblue.withValues(alpha: 0.8),
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: yInterval,
                        reservedSize: 36.w,
                        getTitlesWidget: (value, meta) {
                          if (value < 0 || value > maxY) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: EdgeInsets.only(right: 6.w),
                            child: Text(
                              _formatHz(value),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: AppColors.greyColor,
                                fontSize: 9.sp,
                              ),
                            ),
                          );
                        },
                      ),
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
                  lineBarsData: series.map((item) {
                    return LineChartBarData(
                      spots: item.points.map((point) => point.spot).toList(),
                      isCurved: item.points.length > 2,
                      curveSmoothness: 0.4,
                      color: item.color,
                      barWidth: 2.5,
                      dotData: FlDotData(
                        show: true,
                        checkToShowDot: (spot, barData) {
                          if (item.points.length == 1) return true;
                          final index = barData.spots.indexOf(spot);
                          if (index < 0 || index >= item.points.length) {
                            return false;
                          }
                          return item.points[index].isAttack;
                        },
                        getDotPainter: (spot, percent, barData, index) {
                          final isAttack =
                              index >= 0 &&
                              index < item.points.length &&
                              item.points[index].isAttack;
                          return FlDotCirclePainter(
                            radius: 3.5.r,
                            color: isAttack ? AppColors.primaryred : item.color,
                            strokeWidth: 1.5.w,
                            strokeColor: AppColors.medDarkblueColor,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: series.length == 1,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            item.color.withValues(alpha: 0.32),
                            item.color.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  minX: 0,
                  maxX: 60,
                  minY: 0,
                  maxY: maxY,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_CanFrequencySeries> get _series {
    if (messages.isEmpty) return const [];
    final groupedMessages = <String, List<CANMessage>>{};
    for (final message in messages) {
      groupedMessages.putIfAbsent(message.canId, () => []).add(message);
    }

    final orderedIds = groupedMessages.keys.toList()
      ..sort(
        (a, b) => groupedMessages[b]!.length.compareTo(
          groupedMessages[a]!.length,
        ),
      );
    final start = messages.first.timestamp;
    return [
      for (var index = 0; index < orderedIds.length; index++)
        _CanFrequencySeries(
          color: _seriesColor(index),
          points: groupedMessages[orderedIds[index]]!
              .map((message) {
                final x = (message.timestamp - start).clamp(0, 60).toDouble();
                final y = message.timeDiff > 0
                    ? 1 / message.timeDiff
                    : frequency;
                return _CanFrequencyPoint(
                  spot: FlSpot(x, y.isFinite ? y : 0),
                  isAttack: _isAttackMessage(message),
                );
              })
              .toList()
            ..sort((a, b) => a.spot.x.compareTo(b.spot.x)),
        ),
    ];
  }

  List<String> get _timeLabels {
    if (messages.isEmpty) return const ["--:--", "--:--", "--:--"];
    return [
      _formatTimestamp(messages.first.timestamp),
      _formatTimestamp(messages[messages.length ~/ 2].timestamp),
      _formatTimestamp(messages.last.timestamp),
    ];
  }

  double _maxY(Iterable<FlSpot> spots) {
    final highest = spots.map((spot) => spot.y).fold<double>(frequency, (a, b) {
      return a > b ? a : b;
    });
    if (highest <= 0) return 10;
    return highest * 1.2;
  }

  Color _seriesColor(int index) {
    final colors = [
      AppColors.secondaryblueColor,
      AppColors.primarygreen,
      AppColors.primaryorange,
      Colors.cyanAccent,
      Colors.pinkAccent,
      Colors.amberAccent,
      Colors.deepPurpleAccent,
    ];
    return colors[index % colors.length];
  }

  bool _isAttackMessage(CANMessage message) {
    return message.label.toLowerCase() != 'normal';
  }

  String _formatHz(double value) {
    if (value >= 1000) return "${(value / 1000).toStringAsFixed(1)}k";
    if (value >= 100) return value.toStringAsFixed(0);
    if (value >= 10) return value.toStringAsFixed(1);
    return value.toStringAsFixed(0);
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

class _CanFrequencySeries {
  final Color color;
  final List<_CanFrequencyPoint> points;

  const _CanFrequencySeries({
    required this.color,
    required this.points,
  });
}

class _CanFrequencyPoint {
  final FlSpot spot;
  final bool isAttack;

  const _CanFrequencyPoint({
    required this.spot,
    required this.isAttack,
  });
}
