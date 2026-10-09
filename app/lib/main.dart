import 'package:flutter/material.dart';

import 'screens/dashboard_screen.dart';
import 'screens/emails_screen.dart';
import 'screens/more_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/password_screen.dart';
import 'services/local_store.dart';
import 'state/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DatenschildApp());
}

class DatenschildApp extends StatefulWidget {
  const DatenschildApp({super.key});

  @override
  State<DatenschildApp> createState() => _DatenschildAppState();
}

class _DatenschildAppState extends State<DatenschildApp> {
  final _state = AppState();
  bool? _onboardingDone;

  @override
  void initState() {
    super.initState();
    LocalStore().onboardingDone().then((done) {
      setState(() => _onboardingDone = done);
      if (done) _state.init();
    });
  }

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF1B5E9E);
    return MaterialApp(
      title: 'Datenschild',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: seed), useMaterial3: true),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: switch (_onboardingDone) {
        null => const Scaffold(body: Center(child: CircularProgressIndicator())),
        false => OnboardingScreen(onDone: () async {
            await LocalStore().setOnboardingDone();
            setState(() => _onboardingDone = true);
            _state.init();
          }),
        true => HomeShell(state: _state),
      },
    );
  }
}

class HomeShell extends StatefulWidget {
  final AppState state;

  const HomeShell({super.key, required this.state});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(state: widget.state, onOpenEmails: () => setState(() => _index = 2)),
      const PasswordScreen(),
      EmailsScreen(state: widget.state),
      MoreScreen(state: widget.state),
    ];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _index, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.shield_outlined), selectedIcon: Icon(Icons.shield), label: 'Übersicht'),
          NavigationDestination(icon: Icon(Icons.password_outlined), selectedIcon: Icon(Icons.password), label: 'Passwort'),
          NavigationDestination(icon: Icon(Icons.mail_outline), selectedIcon: Icon(Icons.mail), label: 'E-Mails'),
          NavigationDestination(icon: Icon(Icons.menu), label: 'Mehr'),
        ],
      ),
    );
  }
}
