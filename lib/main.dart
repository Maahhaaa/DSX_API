import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gp/features/onboarding/page_indactor.dart';
=======
import 'package:dsx/features/splash/splash_screen.dart';
>>>>>>> Stashed changes

void main() {
  debugPaintSizeEnabled = false;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(390, 844),
      minTextAdapt: false,
      splitScreenMode: true,
      child: MaterialApp(
        home: PageIndactor(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
