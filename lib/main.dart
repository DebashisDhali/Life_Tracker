import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/models.dart';
import 'providers/life_provider.dart';
import 'providers/money_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/notification_service.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Premium Anti-Crash Error Boundary
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.auto_fix_high_rounded, color: Colors.cyanAccent, size: 48),
            ),
            const SizedBox(height: 32),
            const Text(
              "System Optimization Needed",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.bold, 
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "We encountered an unexpected anomaly. Our systems are ready to recover.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () {
                // Logic to restart app usually happens outside but here we just give a clear CTA
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 10,
                shadowColor: Colors.cyanAccent.withValues(alpha: 0.3),
              ),
              child: const Text("RESTORE SESSION", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  };
  
  // Parallelize critical initializations
  await Future.wait([
    Firebase.initializeApp(),
    Hive.initFlutter().then((_) {
      // Register Adapters immediately after Hive init
      Hive.registerAdapter(SubTaskTypeAdapter());
      Hive.registerAdapter(SubTaskAdapter());
      Hive.registerAdapter(HabitAdapter());
      Hive.registerAdapter(MoneyEntryTypeAdapter());
      Hive.registerAdapter(MoneyEntryStatusAdapter());
      Hive.registerAdapter(MoneyEntryAdapter());
      Hive.registerAdapter(MoneySettingsAdapter());
      Hive.registerAdapter(SectionTypeAdapter());
      Hive.registerAdapter(LifeSectionAdapter());
    }),
    NotificationService().init(),
  ]);

  // Check if first launch
  final prefs = await SharedPreferences.getInstance();
  final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => MoneyProvider()..init()),
        ChangeNotifierProxyProvider<MoneyProvider, LifeProvider>(
          create: (_) => LifeProvider()..init(),
          update: (_, money, life) => life!..updateMoneyProvider(money),
        ),
      ],
      child: LifeTrackerApp(isFirstLaunch: isFirstLaunch),
    ),
  );
}

class LifeTrackerApp extends StatelessWidget {
  final bool isFirstLaunch;
  
  const LifeTrackerApp({super.key, required this.isFirstLaunch});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LifeProvider>(
      builder: (context, themeProvider, lifeProvider, child) {
        return MaterialApp(
          key: ValueKey(lifeProvider.isLoggedIn),
          title: 'Life Tracker',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: _getHome(lifeProvider),
        );
      },
    );
  }

  Widget _getHome(LifeProvider life) {
    if (isFirstLaunch) return const OnboardingWrapper();
    if (!life.isLoggedIn) return const AuthScreen();
    return const HomeScreen();
  }
}

class OnboardingWrapper extends StatefulWidget {
  const OnboardingWrapper({Key? key}) : super(key: key);

  @override
  State<OnboardingWrapper> createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends State<OnboardingWrapper> {
  @override
  void initState() {
    super.initState();
    _markAsLaunched();
  }

  Future<void> _markAsLaunched() async {
    // Moved to OnboardingScreen's Get Started button
  }

  @override
  Widget build(BuildContext context) {
    return const OnboardingScreen();
  }
}
