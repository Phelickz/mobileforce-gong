import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:team_mobileforce_gong/services/localAuth/lockNotes.dart';
import 'package:team_mobileforce_gong/state/notesProvider.dart';
import 'package:team_mobileforce_gong/state/theme_notifier.dart';
import 'package:team_mobileforce_gong/state/todoProvider.dart';
import 'services/auth/userState.dart';
import 'package:team_mobileforce_gong/state/drawerState.dart';

import 'UI/screens/add_note.dart';
import 'UI/screens/splashscreen.dart';
import 'services/notifications/notifications.dart';
import 'services/quotes/quoteState.dart';
import 'state/authProvider.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
NotificationAppLaunchDetails notificationAppLaunchDetails;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  notificationAppLaunchDetails =
      await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
  await NotificationManager().initNotifications();

  runApp(
    ChangeNotifierProvider<ThemeNotifier>(
      child: MyApp(),
      create: (BuildContext context) {
        return ThemeNotifier();
      },
    ),
  );

  // runApp(
  //   DevicePreview(
  //     enabled: !kReleaseMode,
  //     builder: (context) => ChangeNotifierProvider<ThemeNotifier>(
  //     child: MyApp(),
  //     create: (BuildContext context) {
  //       return ThemeNotifier();
  //     },
  //   ),
  //   )
  // );
}

var navigationKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Provider.of<ThemeNotifier>(context).loadThemeData(context);
    return Consumer<ThemeNotifier>(
      builder: (context, value, child) {
        return MultiProvider(
          providers: [
            Provider(create: (_) => DrawerService()),
            ChangeNotifierProvider(create: (_) => AuthenticationState()),
            ChangeNotifierProvider(create: (_) => QuoteState()),
            ChangeNotifierProvider(create: (_) => NotesProvider()),
            ChangeNotifierProvider(create: (_) => TodoProvider()),
            ChangeNotifierProvider(create: (_) => LocalAuth()),
            ChangeNotifierProvider(create: (_) => UserNotifier()),
          ],
          child: GetMaterialApp(
              // locale: DevicePreview.of(context).locale,
              // builder: DevicePreview.appBuilder,
              debugShowCheckedModeBanner: false,

              // initialRoute: '/',
              // routes: {
              //   '/notes': (context) => AddNote()
              // },
              title: 'Gong',
              theme: Provider.of<ThemeNotifier>(context).currentThemeData,
              home: SplashScreen()),
        );
      },
    );
  }
}




