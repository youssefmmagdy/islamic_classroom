import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';
import 'providers/app_settings.dart';
// import 'providers/notification_provider.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/teacher/teacher_profile_enhanced.dart';
import 'screens/student/student_profile_screen.dart';
// import 'services/firebase_messaging_service.dart';
import 'utils/theme.dart';

Future<void> main() async {
  // final prefs = await SharedPreferences.getInstance();
  // await prefs.remove('user_data');

  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Initialize Firebase
  // await Firebase.initializeApp();
  
  // Initialize Firebase Messaging
  // await FirebaseMessagingService().initialize();
  
  // Initialize date formatting for Arabic locale
  await initializeDateFormatting('ar');
  
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DataProvider()),
        ChangeNotifierProvider(create: (_) => AppSettings()),
        // ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: Consumer2<AuthProvider, AppSettings>(
        builder: (context, authProvider, appSettings, child) {
          // Load user data when app starts
          if (!authProvider.isLoggedIn) {
            authProvider.loadUserData();
          }

          return MaterialApp(
            title: 'دَارُ الْقُرْآنِ',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: appSettings.themeMode,
            locale: appSettings.locale,
            home: const HomeScreen(),
            routes: {
              '/profile': (context) => const ProfileScreen(),
              '/teacher-profile': (context) => const TeacherProfileScreen(),
              '/student-profile': (context) => const StudentProfileScreen(),
            },
            builder: (context, child) {
              return Directionality(
                textDirection: appSettings.direction,
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
