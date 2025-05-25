import 'package:flutter/material.dart';
import 'package:property_management_app/providers/lease_provider.dart';
import 'package:property_management_app/providers/subscription_provider.dart';
import 'package:property_management_app/screens/onboarding/onboarding_screen.dart';
import 'package:property_management_app/screens/welcome/welcome_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/auth_provider.dart';
import 'providers/property_provider.dart';
import 'providers/tenant_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/expense_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'utils/constants.dart';
import 'providers/document_provider.dart';
import 'services/lease_service.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // Check if first launch
  final prefs = await SharedPreferences.getInstance();
  final showOnboarding = !(prefs.getBool('onboarding_completed') ?? false);
  final showWelcome = !(prefs.getBool('welcome_screen_seen') ?? false);
  
  // Determine initial screen
  Widget initialScreen;
  if (showOnboarding) {
    initialScreen = OnboardingScreen();
  } else {
    final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
    if (isLoggedIn) {
      initialScreen = showWelcome ? WelcomeScreen() : DashboardScreen();
    } else {
      initialScreen = LoginScreen();
    }
  }

  // Check expired leases when app starts
  await _checkExpiredLeases();
  
  runApp(MyApp(initialScreen: initialScreen));
}

Future<void> _checkExpiredLeases() async {
  final leaseService = LeaseService();
  await leaseService.archiveExpiredLeases();
}

class MyApp extends StatelessWidget {
  final Widget initialScreen;

  const MyApp({required this.initialScreen});
  
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PropertyProvider()),
        ChangeNotifierProvider(create: (_) => TenantProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => DocumentProvider()),
        ChangeNotifierProvider(create: (_) => LeaseProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider())
      ],
      child: MaterialApp(
        title: 'Property Management',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          appBarTheme: AppBarTheme(
            elevation: 0,
            backgroundColor: Colors.blue,
          ),
        ),
        navigatorObservers: [RouteObserver<ModalRoute<void>>()],
        
        // Add this section to handle deep linking
        onGenerateRoute: (settings) {
          // Handle deep links here
          if (settings.name?.startsWith('/billing-return') ?? false) {
            // Refresh subscription data
            Provider.of<SubscriptionProvider>(context, listen: false).loadSubscriptionStatus();
            return MaterialPageRoute(
              builder: (_) => DashboardScreen(),
            );
          }
          return null;
        },
        
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.isLoggedIn) {
              return DashboardScreen();
            } else {
              return LoginScreen();
            }
          },
        ),
      ),
    );
  }
}