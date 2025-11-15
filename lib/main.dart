import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NeuroFitApp());
}

class NeuroFitApp extends StatelessWidget {
  const NeuroFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0F172A);
    const card = Color(0xFF1E293B);
    const text = Color(0xFFF1F5F9);
    const primary = Color(0xFF7C3AED);

    return MaterialApp(
      title: 'NeuroFit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        primaryColor: primary,
        colorScheme: const ColorScheme.dark(surface: card, primary: primary),
        cardColor: card,
        fontFamily: 'Roboto',

        //TEXT FIELDS FOR LOGIN, REGISTER, ETC.
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF253246),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF334155)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF334155)),
          ),
          labelStyle: const TextStyle(color: Colors.white70),
          hintStyle: const TextStyle(color: Colors.white54),
        ),

        //CURSOR COLOR
        textSelectionTheme: const TextSelectionThemeData(cursorColor: primary),

        //BUTTONS
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        //CREATE AN ACCOUNT/SIGN IN LINK
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.white),
        ),

        appBarTheme: const AppBarTheme(backgroundColor: bg, elevation: 0),
        textTheme: const TextTheme(bodyMedium: TextStyle(color: text)),
      ),
      home: const AuthSwitcher(),
    );
  }
}

///SWITCH FROM LOGIN TO REGISTRATION AND VICE VERSA
class AuthSwitcher extends StatefulWidget {
  const AuthSwitcher({super.key});

  @override
  State<AuthSwitcher> createState() => _AuthSwitcherState();
}

class _AuthSwitcherState extends State<AuthSwitcher> {
  bool _isLoggedIn = false;
  String _username = 'Athlete';
  bool _showRegister = false;

  void _handleLogin(String email) {
    setState(() {
      _isLoggedIn = true;
      _username = email.split('@').first.isNotEmpty
          ? email.split('@').first
          : 'Athlete';
    });
  }

  void _handleLogout() {
    setState(() {
      _isLoggedIn = false;
      _showRegister = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return Scaffold(
        resizeToAvoidBottomInset: true,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _showRegister
                  ? RegisterCard(
                      onSwitchToLogin: () {
                        setState(() => _showRegister = false);
                      },
                    )
                  : LoginCard(
                      onLogin: _handleLogin,
                      onSwitchToRegister: () {
                        setState(() => _showRegister = true);
                      },
                    ),
            ),
          ),
        ),
      );
    }

    return NeuroFitShell(username: _username, onLogout: _handleLogout);
  }
}

///LOGIN UI
class LoginCard extends StatefulWidget {
  final void Function(String email) onLogin;
  final VoidCallback onSwitchToRegister;

  const LoginCard({
    super.key,
    required this.onLogin,
    required this.onSwitchToRegister,
  });

  @override
  State<LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends State<LoginCard> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter email and password.');
      return;
    }

    // TODO: plug in Supabase auth here later.
    widget.onLogin(email);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Welcome Back',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please sign in to continue.',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                const SizedBox(height: 12),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submit,
                    child: const Text('Login'),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'New here? ',
                      style: TextStyle(color: Colors.grey),
                    ),
                    TextButton(
                      onPressed: widget.onSwitchToRegister,
                      child: const Text('Create an account'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

///REGISTER UI
class RegisterCard extends StatefulWidget {
  final VoidCallback onSwitchToLogin;

  const RegisterCard({super.key, required this.onSwitchToLogin});

  @override
  State<RegisterCard> createState() => _RegisterCardState();
}

class _RegisterCardState extends State<RegisterCard> {
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_usernameCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _passwordCtrl.text.length < 8) {
      setState(
        () => _error =
            'Username, email and a password with 8+ characters are required.',
      );
      return;
    }

    // TODO: call Supabase signUp later.
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Account Created'),
        content: const Text(
          'Your account has been created! You can now log in.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onSwitchToLogin();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Create an Account',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'It takes less than a minute.',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _usernameCtrl,
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password (8+ characters)',
                  ),
                ),
                const SizedBox(height: 12),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submit,
                    child: const Text('Register'),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: Colors.grey),
                    ),
                    TextButton(
                      onPressed: widget.onSwitchToLogin,
                      child: const Text('Sign in'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

///SIDEBAR + DRAWER AND OTHER PAGES
class NeuroFitShell extends StatefulWidget {
  final String username;
  final VoidCallback onLogout;

  const NeuroFitShell({
    super.key,
    required this.username,
    required this.onLogout,
  });

  @override
  State<NeuroFitShell> createState() => _NeuroFitShellState();
}

class _NeuroFitShellState extends State<NeuroFitShell> {
  int _selectedIndex = 0;

  static const _sections = [
    'Dashboard',
    'Progress',
    'Log Workout',
    'Body Diagram',
    'History',
    'Generate Plan',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    Widget body;
    switch (_selectedIndex) {
      case 0:
        body = DashboardScreen(username: widget.username);
        break;
      case 1:
        body = const ProgressScreen();
        break;
      case 2:
        body = const LogWorkoutScreen();
        break;
      case 3:
        body = const BodyDiagramScreen();
        break;
      case 4:
        body = const HistoryScreen();
        break;
      case 5:
        body = const GeneratePlanScreen();
        break;
      case 6:
        body = const SettingsScreen();
        break;
      default:
        body = const SizedBox.shrink();
    }

    final sidebar = NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (i) => setState(() => _selectedIndex = i),
      labelType: isWide
          ? NavigationRailLabelType.selected
          : NavigationRailLabelType.all,
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: Text('Dashboard'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.insights_outlined),
          selectedIcon: Icon(Icons.insights),
          label: Text('Progress'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.fitness_center_outlined),
          selectedIcon: Icon(Icons.fitness_center),
          label: Text('Log Workout'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.accessibility_new_outlined),
          selectedIcon: Icon(Icons.accessibility_new),
          label: Text('Body'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.history),
          selectedIcon: Icon(Icons.history_toggle_off),
          label: Text('History'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.auto_awesome),
          selectedIcon: Icon(Icons.auto_awesome_mosaic),
          label: Text('Plan'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('Settings'),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('NeuroFit'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
          ),
          TextButton(onPressed: widget.onLogout, child: const Text('Logout')),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          if (isWide) sidebar,
          if (isWide) const VerticalDivider(width: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: body,
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: isWide
          ? null
          : Drawer(
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DrawerHeader(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'NeuroFit',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Welcome, ${widget.username}'),
                        ],
                      ),
                    ),
                    for (var i = 0; i < _sections.length; i++)
                      ListTile(
                        title: Text(_sections[i]),
                        selected: i == _selectedIndex,
                        onTap: () {
                          setState(() => _selectedIndex = i);
                          Navigator.of(context).pop();
                        },
                      ),
                    const Spacer(),
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text('Logout'),
                      onTap: widget.onLogout,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

///DASHBOARD
class DashboardScreen extends StatelessWidget {
  final String username;

  const DashboardScreen({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---------- TOP SECTION ----------
          LayoutBuilder(
            builder: (context, constraints) {
              int cols = 1;
              if (constraints.maxWidth > 1200) {
                cols = 3;
              } else if (constraints.maxWidth > 800) {
                cols = 2;
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: 136,
                ),
                itemBuilder: (context, i) {
                  final items = [
                    _simpleCard(
                      title: 'Welcome $username 👋',
                      body: "Here's a quick snapshot of your app.",
                    ),
                    _simpleCard(
                      title: 'Status',
                      body: 'Online • Session active',
                    ),
                    _simpleCard(
                      title: 'Tips',
                      body: 'Use the sidebar to navigate between sections.',
                    ),
                  ];
                  return items[i];
                },
              );
            },
          ),

          const SizedBox(height: 16),

          // ---------- LOWER SECTION ----------
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;

              final left = _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'This Week',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Auto-calculated from your logs.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 132,
                      child: Row(
                        children: [
                          Expanded(
                            child: _metricTile(context, 'Workouts', '0'),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _metricTile(context, 'Total Volume', '0'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );

              final right = _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Activity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Recent actions appear here.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No activity yet. Log a workout to get started!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: left),
                    const SizedBox(width: 16),
                    Expanded(child: right),
                  ],
                );
              } else {
                return Column(
                  children: [left, const SizedBox(height: 16), right],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  //HELPER WIDGETS
  static Widget _simpleCard({required String title, required String body}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                body,
                style: const TextStyle(color: Colors.white70),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _metricTile(BuildContext context, String label, String value) {
    final cardColor = Theme.of(context).cardColor;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _card({required Widget child}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

/// LOG WORKOUT
class LogWorkoutScreen extends StatefulWidget {
  const LogWorkoutScreen({super.key});

  @override
  State<LogWorkoutScreen> createState() => _LogWorkoutScreenState();
}

class _LogWorkoutScreenState extends State<LogWorkoutScreen> {
  DateTime? _date;
  final _exerciseCtrl = TextEditingController();
  final _setsCtrl = TextEditingController();
  final _repsCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _message;

  @override
  void dispose() {
    _exerciseCtrl.dispose();
    _setsCtrl.dispose();
    _repsCtrl.dispose();
    _weightCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  void _reset() {
    setState(() {
      _date = null;
      _exerciseCtrl.clear();
      _setsCtrl.clear();
      _repsCtrl.clear();
      _weightCtrl.clear();
      _notesCtrl.clear();
      _message = null;
    });
  }

  void _submit() {
    if (_date == null ||
        _exerciseCtrl.text.trim().isEmpty ||
        _setsCtrl.text.isEmpty ||
        _repsCtrl.text.isEmpty ||
        _weightCtrl.text.isEmpty) {
      setState(() => _message = 'Please fill out all required fields.');
      return;
    }

    setState(() {
      _message =
          'Workout saved: ${_exerciseCtrl.text} on ${_date!.toIso8601String().split("T").first}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Log a Workout',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 600;
                  return Column(
                    children: [
                      Flex(
                        direction: isWide ? Axis.horizontal : Axis.vertical,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextField(
                              readOnly: true,
                              onTap: _pickDate,
                              decoration: InputDecoration(
                                labelText: _date == null
                                    ? 'Date'
                                    : _date!.toIso8601String().split('T').first,
                                hintText: 'Select date',
                                suffixIcon: const Icon(
                                  Icons.calendar_today_outlined,
                                ),
                              ),
                            ),
                          ),
                          if (isWide) const SizedBox(width: 12),
                          if (!isWide) const SizedBox(height: 12),
                          Expanded(
                            child: TextField(
                              controller: _exerciseCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Exercise',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Flex(
                        direction: isWide ? Axis.horizontal : Axis.vertical,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _setsCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Sets',
                              ),
                            ),
                          ),
                          if (isWide) const SizedBox(width: 12),
                          if (!isWide) const SizedBox(height: 12),
                          Expanded(
                            child: TextField(
                              controller: _repsCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Reps',
                              ),
                            ),
                          ),
                          if (isWide) const SizedBox(width: 12),
                          if (!isWide) const SizedBox(height: 12),
                          Expanded(
                            child: TextField(
                              controller: _weightCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Weight',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _notesCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: _reset,
                            child: const Text('Reset'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: _submit,
                            child: const Text('Save Entry'),
                          ),
                        ],
                      ),
                      if (_message != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _message!,
                          style: const TextStyle(color: Colors.greenAccent),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// BODY DIAGRAM
class BodyDiagramScreen extends StatelessWidget {
  const BodyDiagramScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: const Padding(
        padding: EdgeInsets.all(18),
        child: Center(
          child: Text(
            'Body Diagram coming soon.\n\n'
            'We will recreate your front/back SVG and make muscle groups tappable.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// HISTORY
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Center(
          child: Text(
            'Workout history table will live here.\n'
            'We can add filters for date / exercise / volume like your web app.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// PROGRESS
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Center(
          child: Text(
            'Progress metrics will be shown here.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// GENERATE PLAN
class GeneratePlanScreen extends StatelessWidget {
  const GeneratePlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: ListView(
          children: const [
            Text(
              'Generate Workout Plan',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'We\'ll mirror your plan options (fitness level, days, goal, '
              'equipment, RPE, adherence) and build days dynamically.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

/// SETTINGS
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: ListView(
          children: [
            const Text(
              'Settings',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Customize your NeuroFit experience.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              items: const [
                DropdownMenuItem(value: 'lbs', child: Text('Pounds (lbs)')),
                DropdownMenuItem(value: 'kg', child: Text('Kilograms (kg)')),
              ],
              onChanged: (_) {},
              initialValue: 'lbs',
              decoration: const InputDecoration(labelText: 'Weight Units'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Weekly Workout Goal',
                helperText: 'How many days per week do you want to work out?',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                FilledButton(
                  onPressed: () {},
                  child: const Text('Save Settings'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                  child: const Text('Clear All Data'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
