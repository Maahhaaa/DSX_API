import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gp/core/helper/images.dart';
import 'package:gp/core/services/can_service.dart';
import 'package:gp/core/theme/app_colors.dart';
import 'package:gp/core/theme/styles.dart';
import 'package:gp/features/dashboard/widgets/lastsalretcard.dart';
import 'package:gp/features/dashboard/widgets/messagefrequencycard.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final CANService _canService = CANService();

  bool _isScanning = false;
  bool _isConnected = false;
  CANStats? _stats;
  List<CANMessage> _messages = [];

  StreamSubscription? _statsSubscription;
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _connectedSubscription;

  @override
  void initState() {
    super.initState();
    _listenToFirebase();
  }

  void _listenToFirebase() {
    _connectedSubscription = _canService.connectedStream().listen((connected) {
      if (!mounted) return;
      setState(() => _isConnected = connected);
    });

    _statsSubscription = _canService.statsStream().listen((stats) {
      if (!mounted) return;
      setState(() => _stats = stats);
    });

    _messagesSubscription = _canService.messagesStream().listen((messages) {
      if (!mounted) return;
      setState(() => _messages = messages);
    });
  }

  Future<void> _startScan() async {
    setState(() => _isScanning = true);

    try {
      final messages = await _canService.latestMessagesOnce();
      final stats = await _canService.latestStatsOnce();
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _stats = stats;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scan failed: $e'),
            backgroundColor: AppColors.primaryred,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  @override
  void dispose() {
    _statsSubscription?.cancel();
    _messagesSubscription?.cancel();
    _connectedSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alerts = _messages
        .where((m) => m.label.toLowerCase() != 'normal')
        .toList();
    final lastAlert = alerts.isNotEmpty ? alerts.last : null;
    final hasAttack = (_stats?.dosCount ?? 0) > 0;

    return Scaffold(
      backgroundColor: AppColors.primaryblueColor,
      appBar: AppBar(
        toolbarHeight: 90.h,
        centerTitle: true,
        backgroundColor: AppColors.primaryblueColor,
        title: Text(
          "Vehicle Sentinel",
          style: Styles.inter18bold.copyWith(color: Colors.white),
        ),
        leading: const Icon(Icons.menu_rounded, color: Colors.white),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(top: 20.h),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.w),
              child: Center(
                child: Column(
                  children: [
                    _SystemStatusBadge(
                      isConnected: _isConnected,
                      hasAttack: hasAttack,
                    ),
                    SizedBox(height: 28.h),
                    Text(
                      !_isConnected
                          ? "Disconnected"
                          : hasAttack
                              ? "Threat Detected"
                              : "Safe",
                      style: Styles.inter32bold.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "Last scan: ${_lastScanLabel(_messages)}",
                      style: Styles.inter14medium.copyWith(
                        color: AppColors.greyColor,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 24.h),
                      child: ElevatedButton(
                        onPressed: _isScanning ? null : _startScan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryblueColor,
                          foregroundColor: Colors.white,
                          maximumSize: Size(167.w, 46.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9999.r),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _isScanning
                                ? SizedBox(
                                    width: 17.w,
                                    height: 17.h,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Image.asset(
                                    Images.scan,
                                    width: 17.w,
                                    height: 17.h,
                                  ),
                            SizedBox(width: 8.w),
                            Text(
                              _isScanning ? "Scanning..." : "Scan Now",
                              style: Styles.inter16semi.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 50.h),
                    MessageFrequencyCard(
                      frequency: _stats?.messageFrequency ?? 0,
                      messages: _messages,
                    ),
                    SizedBox(height: 20.h),
                    LastAlertCard(
                      time: lastAlert == null
                          ? "--"
                          : _formatTimestamp(lastAlert.timestamp),
                      alertTitle: _stats?.lastAlert ??
                          lastAlert?.label ??
                          "No alerts",
                      onDetailsTap: () {},
                    ),
                    SizedBox(height: 10.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _lastScanLabel(List<CANMessage> messages) {
    if (messages.isEmpty) return "No data";
    final timestamp = messages.last.timestamp;
    final time = _timestampToDateTime(timestamp);
    if (time == null) return "${timestamp.toStringAsFixed(1)}s";
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return "just now";
    if (diff.inHours < 1) return "${diff.inMinutes} min ago";
    if (diff.inDays < 1) return "${diff.inHours} hr ago";
    return "${diff.inDays} day ago";
  }

  String _formatTimestamp(double timestamp) {
    final date = _timestampToDateTime(timestamp);
    if (date == null) return "${timestamp.toStringAsFixed(1)}s";
    return "${_twoDigits(date.hour)}:${_twoDigits(date.minute)}";
  }

  DateTime? _timestampToDateTime(double timestamp) {
    if (timestamp <= 0) return null;
    if (timestamp > 1000000000000) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());
    }
    if (timestamp > 1000000000) {
      return DateTime.fromMillisecondsSinceEpoch((timestamp * 1000).toInt());
    }
    return null;
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

class _SystemStatusBadge extends StatelessWidget {
  final bool isConnected;
  final bool hasAttack;

  const _SystemStatusBadge({
    required this.isConnected,
    required this.hasAttack,
  });

  @override
  Widget build(BuildContext context) {
    final color = !isConnected
        ? AppColors.greyColor
        : hasAttack
            ? AppColors.primaryred
            : AppColors.primarygreen;

    final label = !isConnected
        ? "DATABASE OFFLINE"
        : hasAttack
            ? "ALERT ACTIVE"
            : "SYSTEM SECURE";

    final deticon = !isConnected
        ? Images.offlineicon
        : hasAttack
            ? Images.criticalicon
            : Images.sysSecure;

    return Container(
      height: 45.h,
      width: 210.w,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(9999.r),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: 0.9.w,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            spreadRadius: 4,
            blurRadius: 8,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            deticon,
            width: 14.w,
            height: 17.h,
            color: color,
            colorBlendMode: BlendMode.srcIn,
          ),
          SizedBox(width: 5.w),
          Text(
            label,
            style: Styles.inter14medium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
