import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ddbqqsifculsmgykmojp.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRkYnFxc2lmY3Vsc21neWttb2pwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMxNTU2MDYsImV4cCI6MjA3ODczMTYwNn0.vMlFlhc49upDaf41Vnoksvrjo8LYooUDlyDXVumlAwE',
  );

  runApp(const NeuroFitApp());
}

final supabase = Supabase.instance.client;

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
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF334155)),
          ),
          labelStyle: const TextStyle(color: Colors.white70),
          hintStyle: const TextStyle(color: Colors.white54),
          errorStyle: const TextStyle(color: Colors.redAccent),
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

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final session = supabase.auth.currentSession;
    if (session != null) {
      final user = supabase.auth.currentUser;
      setState(() {
        _isLoggedIn = true;
        _username = user?.userMetadata?['username'] ?? user?.email?.split('@').first ?? 'Athlete';
      });
    }
  }

  void _handleLogin(String username) {
    setState(() {
      _isLoggedIn = true;
      _username = username;
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
                      onSuccess: () {
                        setState(() => _showRegister = false);
                      },
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
  final void Function(String username) onLogin;
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
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is Required.';
    }

    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Invalid Email.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is Required.';
    }
    return null;
  }

  Future<void> _submit() async {
    setState(() {
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailCtrl.text.trim().toLowerCase();
      final password = _passwordCtrl.text;
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        final username = response.user!.userMetadata?['username'] ?? email.split('@').first;

        if (mounted) {
          widget.onLogin(username);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Welcome Back!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid Email or Password.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
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
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: _validateEmail,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: _validatePassword,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 12),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Login'),
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
                        onPressed: _isLoading ? null : widget.onSwitchToRegister,
                        child: const Text('Create an account'),
                      ),
                    ],
                  ),
                ],
              ),
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
  final VoidCallback onSuccess;

  const RegisterCard({
    super.key, 
    required this.onSwitchToLogin,
    required this.onSuccess,
  });

  @override
  State<RegisterCard> createState() => _RegisterCardState();
}

class _RegisterCardState extends State<RegisterCard> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String? _successMessage;
  String? _errorMessage;
  bool _isLoading = false;
  int _passwordStrength = 0;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  int _scorePassword(String password) {
    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password) && RegExp(r'\d').hasMatch(password)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;
    return score > 4 ? 4 : score;
  }

  String? _validateUsername(String? value) {
    if  (value == null || value.trim().length < 3) {
      return 'Username Must be at Least 3 Characters.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is Required.';
    }

    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a Valid Email Address.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is Required.';
    }
    
    final score = _scorePassword(value);
    if (score < 3) {
      return 'Use 8+ Characters with Upper/Lowercase, a Number, and a Special Character.';
    }
    return null;
  }

  Future<void> _submit() async {
    setState(() {
      _successMessage = null;
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final username = _usernameCtrl.text.trim();
      final email = _emailCtrl.text.trim().toLowerCase();
      final password = _passwordCtrl.text;
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );

      if (response.user != null) {
        await supabase.from('profiles').insert({
          'id': response.user!.id,
          'username': username,
          'units': 'lbs',
          'weekly_goal': 3,
        });

        if (mounted) {
          setState(() {
            _successMessage = 'Registration Successful. Check your Email to Confirm, then Log In.';
          });

          await Future.delayed(const Duration(milliseconds: 800));
          if (mounted) {
            widget.onSuccess();
          }
        }
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Registration Failed. Please Try Again!';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color _getStrengthColor() {
    switch (_passwordStrength) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.lightGreen;
      case 4:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  double _getStrengthWidth() {
    return (_passwordStrength / 4.0);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
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
                  TextFormField(
                    controller: _usernameCtrl,
                    decoration: const InputDecoration(labelText: 'Username'),
                    validator: _validateUsername,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: _validateEmail,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password (8+ characters)'),
                    validator: _validatePassword,
                    enabled: !_isLoading,
                    onChanged: (value) {
                      setState(() {
                        _passwordStrength = _scorePassword(value);
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _getStrengthWidth(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _getStrengthColor(),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Use Upper & Lowercase, a Number, and a Special Character.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  if (_successMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(color: Colors.greenAccent),
                      ),
                    ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white
                          ),
                        ),
                      )
                     : const Text('Register'),
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
                        onPressed: _isLoading ? null : widget.onSwitchToLogin,
                        child: const Text('Sign in'),
                      ),
                    ],
                  ),
                ],
              )
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
  final _formKey = GlobalKey<FormState>();
  final _dateCtrl = TextEditingController();
  final _exerciseCtrl = TextEditingController();
  final _setsCtrl = TextEditingController();
  final _repsCtrl = TextEditingController();
  final _weightCtrl= TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _successMessage;
  String? _errorMessage;
  bool _isLoading = false;

  final List<String> _exerciseSuggestions = [
    'Barbell Squat',
    'Bench Press',
    'Deadlift',
    'Overhead Press',
    'Lat Pulldown',
    'Dumbbell Row',
    'Incline Bench',
    'Romanian Deadlift',
    'Pull Ups',
    'Dips',
    'Leg Press',
    'Shoulder Press',
  ];

  final List<String> _praiseMessages = [
    "Nice Work!",
    "Let's Go!",
    "Consistency is Key.",
    "Keep it Up!!",
    "Small Steps Add Up.",
  ];

  @override
  void initState() {
    super.initState();
    _dateCtrl.text = DateTime.now().toIso8601String().split('T')[0];
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _exerciseCtrl.dispose();
    _setsCtrl.dispose();
    _repsCtrl.dispose();
    _weightCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String _getRandomPraise() {
    final random = Random();
    return _praiseMessages[random.nextInt(_praiseMessages.length)];
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is Required.';
    }
    return null;
  }

  String? _validateNumber(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is Required.';
    }
    if (int.tryParse(value) == null || int.parse(value) <= 0) {
      return '$fieldName must be a Positive Number.';
    }
    return null;
  }

  String? _validateWeight(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    if (double.tryParse(value) == null || double.parse(value) < 0) {
      return 'Weight must be a Valid Number.';
    }
    return null;
  }

  Future<void> _submitWorkout() async {
    setState(() {
      _successMessage = null;
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Not Authorized');
      }

      final payload = {
        'user_id': user.id,
        'date': _dateCtrl.text,
        'exercise_name': _exerciseCtrl.text.trim(),
        'sets': int.parse(_setsCtrl.text),
        'reps': int.parse(_repsCtrl.text),
        'weight': _weightCtrl.text.isEmpty ? 0.0 : double.parse(_weightCtrl.text),
        'notes': _notesCtrl.text.trim(),
        'visibility': 'friends',
      };

      //Insert into Supabase Table (workout_logs)
      await supabase.from('workout_logs').insert(payload);

      //Create Activity Log
      final activityMessage = 'Logged ${payload['exercise_name']} (${payload['sets']} x ${payload['reps']} @ ${payload['weight']})';
      await supabase.from('activity_feed').insert({
        'user_id': user.id,
        'message': activityMessage,
      });

      //Show Success with Motivational Message
      final praise = _getRandomPraise();
      final details = '${payload['exercise_name']}: ${payload['sets']} x ${payload['reps']} @ ${payload['weight']}';

      if (mounted) {
        setState(() {
          _successMessage = 'Workout Saved!';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  praise,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(details),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(milliseconds: 4500),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _resetForm();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().contains('Exception:') ? e.toString().split('Exception: ')[1] : 'Failed to Save Workout. Please Try Again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _exerciseCtrl.clear();
    _setsCtrl.clear();
    _repsCtrl.clear();
    _weightCtrl.clear();
    _notesCtrl.clear();
    _dateCtrl.text = DateTime.now().toIso8601String().split('T')[0];

    setState(() {
      _successMessage = null;
      _errorMessage = null;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateCtrl.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Log a Workout',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          
                          // Date and Exercise (responsive layout)
                          Flex(
                            direction: isWide ? Axis.horizontal : Axis.vertical,
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _dateCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'Date',
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.calendar_today),
                                      onPressed: () => _selectDate(context),
                                    ),
                                  ),
                                  readOnly: true,
                                  validator: (value) =>
                                      _validateRequired(value, 'Date'),
                                ),
                              ),
                              if (isWide) const SizedBox(width: 12),
                              if (!isWide) const SizedBox(height: 12),
                              Expanded(
                                child: Autocomplete<String>(
                                  optionsBuilder: (textEditingValue) {
                                    if (textEditingValue.text.isEmpty) {
                                      return const Iterable<String>.empty();
                                    }
                                    return _exerciseSuggestions.where((option) {
                                      return option
                                          .toLowerCase()
                                          .contains(
                                              textEditingValue.text.toLowerCase());
                                    });
                                  },
                                  onSelected: (selection) {
                                    _exerciseCtrl.text = selection;
                                  },
                                  fieldViewBuilder: (context, controller,
                                      focusNode, onEditingComplete) {
                                    // Sync with our controller
                                    controller.text = _exerciseCtrl.text;
                                    controller.selection = _exerciseCtrl.selection;
                                    
                                    return TextFormField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      decoration: const InputDecoration(
                                        labelText: 'Exercise',
                                        hintText: 'e.g., Bench Press',
                                      ),
                                      onChanged: (value) {
                                        _exerciseCtrl.text = value;
                                      },
                                      validator: (value) =>
                                          _validateRequired(value, 'Exercise'),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Sets, Reps, Weight (responsive layout)
                          Flex(
                            direction: isWide ? Axis.horizontal : Axis.vertical,
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _setsCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Sets',
                                  ),
                                  validator: (value) =>
                                      _validateNumber(value, 'Sets'),
                                ),
                              ),
                              if (isWide) const SizedBox(width: 12),
                              if (!isWide) const SizedBox(height: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _repsCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Reps',
                                  ),
                                  validator: (value) =>
                                      _validateNumber(value, 'Reps'),
                                ),
                              ),
                              if (isWide) const SizedBox(width: 12),
                              if (!isWide) const SizedBox(height: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _weightCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'Weight (lbs)',
                                  ),
                                  validator: _validateWeight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Notes
                          TextFormField(
                            controller: _notesCtrl,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Notes (optional)',
                              hintText: 'How did it feel? Any observations?',
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isLoading ? null : _resetForm,
                                  child: const Text('Reset'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: FilledButton(
                                  onPressed: _isLoading ? null : _submitWorkout,
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : const Text('Save Entry'),
                                ),
                              ),
                            ],
                          ),
                          
                          // Success/Error messages
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                border: Border.all(color: Colors.red),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          ],
                          if (_successMessage != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                border: Border.all(color: Colors.green),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle,
                                      color: Colors.greenAccent),
                                  const SizedBox(width: 8),
                                  Text(
                                    _successMessage!,
                                    style: const TextStyle(
                                        color: Colors.greenAccent),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// BODY DIAGRAM
class BodyDiagramScreen extends StatefulWidget {
  const BodyDiagramScreen({super.key});

  @override
  State<BodyDiagramScreen> createState() => _BodyDiagramScreenState();
}

class Exercise {
  final String name;
  final String img;
  final String videoURL;

  Exercise(this.name, this.img, this.videoURL);
}

final Map<String, List<Exercise>> exercises = {
  'chest': [
    Exercise('Bench Press', 'images/chest/Bench Press.jpg', 'https://www.youtube.com/embed/hWbUlkb5Ms4'),
    Exercise('Close-Grip Bench Press', 'images/chest/Close-Grip Bench Press.jpg', 'https://www.youtube.com/embed/4yKLxOsrGfg'),
    Exercise('Wide-Grip Bench Press', 'images/chest/Wide-Grip Bench Press.jpg', 'https://www.youtube.com/embed/NQNWLYJTtHA'),
    Exercise('Incline Bench Press', 'images/chest/Incline Bench Press.jpg', 'https://www.youtube.com/embed/8fXfwG4ftaQ'),
    Exercise('Decline Barbell Press', 'images/chest/Decline Barbell Press.jpg', 'https://www.youtube.com/embed/a-UFQE4oxWY'),
    Exercise('Incline Dumbbell Bench Press', 'images/chest/Incline Dumbbell Bench Press.jpg', 'https://www.youtube.com/embed/Gruq177Psnk'),
    Exercise('Decline Dumbbell Bench Press', 'images/chest/Decline Dumbbell Bench Press.jpg', 'https://www.youtube.com/embed/5JiZFjxyoJQ'),
    Exercise('Dumbbell Chest Press', 'images/chest/Dumbbell Chest Press.jpg', 'https://www.youtube.com/embed/WbCEvFA0NJs'),
    Exercise('Dumbbell Chest Flyes', 'images/chest/Dumbbell Chest Flyes.jpg', 'https://www.youtube.com/embed/rk8YayRoTRQ'),
    Exercise('Machine Fly', 'images/chest/Machine Fly.jpg', 'https://www.youtube.com/embed/xYExAgLt_4I'),
    Exercise('Machine Chest Press', 'images/chest/Machine Chest Press.jpg', 'https://www.youtube.com/embed/Qu7-ceCvq7w'),
    Exercise('Dumbbell Pullover', 'images/chest/Dumbbell Pullover.jpg', 'https://www.youtube.com/embed/Datv2L6t3-4'),
    Exercise('Cable Flyes', 'images/chest/Cable Flyes.jpg', 'https://www.youtube.com/embed/y4RJDSOBEl8'),
    Exercise('Incline Cable Flyes', 'images/chest/Incline Cable Flyes.jpg', 'https://www.youtube.com/embed/-Eq_GScOGOE'),
    Exercise('Cable Crossover', 'images/chest/Cable Crossover.jpg', 'https://www.youtube.com/embed/WIErn7-YvYQ'),
  ],
  
  'biceps': [
    Exercise('Standing Dumbbell Curls', 'images/biceps/Standing Dumbbell Curls.jpg', 'https://www.youtube.com/embed/oLyP6sORFOc'),
    Exercise('Alternating Dumbbell Curls', 'images/biceps/Alternating Dumbbell Curls.jpg', 'https://www.youtube.com/embed/FHY_2t7R714'),
    Exercise('Hammer Curls', 'images/biceps/Hammer Curls.jpg', 'https://www.youtube.com/embed/vm0zV_WQerE'),
    Exercise('Concentration Curls', 'images/biceps/Concentration Curls.jpg', 'https://www.youtube.com/embed/EjUnEEfTSEY'),
    Exercise('Incline Dumbbell Curls', 'images/biceps/Incline Dumbbell Curls.jpg', 'https://www.youtube.com/embed/fXFN8_1Bh6k'),
    Exercise('Zottman Curls', 'images/biceps/Zottman Curls.jpg', 'https://www.youtube.com/embed/5Go_uOTnFl0'),
    Exercise('Cross-Body Hammer Curls', 'images/biceps/Cross-Body Hammer Curls.jpg', 'https://www.youtube.com/embed/qmQkt1Y-FX8'),
    Exercise('Seated Alternating Dumbbell Curls', 'images/biceps/Seated Alternating Dumbbell Curls.jpg', 'https://www.youtube.com/embed/16v_0ET03Oo'),
    Exercise('Barbell Curls', 'images/biceps/Barbell Curls.jpg', 'https://www.youtube.com/embed/54x2WF1_Suc'),
    Exercise('EZ Bar Curls', 'images/biceps/EZ Bar Curls.jpg', 'https://www.youtube.com/embed/KFinlAT6aEo'),
    Exercise('Reverse Curls', 'images/biceps/Reverse Curls.jpg', 'https://www.youtube.com/embed/ZG2n5IcYIcY'),
    Exercise('Wide-Grip Barbell Curls', 'images/biceps/Wide-Grip Barbell Curls.jpg', 'https://www.youtube.com/embed/pgeSaAKOXRs'),
    Exercise('Close-Grip Barbell Curls', 'images/biceps/Close-Grip Barbell Curls.jpg', 'https://www.youtube.com/embed/a6ZJAmhCfjU'),
    Exercise('Cable Bicep Curls', 'images/biceps/Cable Bicep Curls.jpg', 'https://www.youtube.com/embed/CrbTqNOlFgE'),
    Exercise('Overhead Cable Curls', 'images/biceps/Overhead Cable Curls.jpg', 'https://www.youtube.com/embed/grFE5bhFmiQ'),
  ],
  
  'abs': [
    Exercise('Weighted Crunches', 'images/abs/Weighted Crunches.jpg', 'https://www.youtube.com/embed/Yg6GsyZoqK0'),
    Exercise('Russian Twists', 'images/abs/Russian Twists.jpg', 'https://www.youtube.com/embed/aRUMRbl7KS4'),
    Exercise('Dumbbell Side Bend', 'images/abs/Dumbbell Side Bend.jpg', 'https://www.youtube.com/embed/kqr_IjiUuyY'),
    Exercise('Weighted Sit-Ups', 'images/abs/Weighted Sit-Ups.jpg', 'https://www.youtube.com/embed/MXOK5F6SKXQ'),
    Exercise('Crunches', 'images/abs/Crunches.jpg', 'https://www.youtube.com/embed/eeJ_CYqSoT4'),
    Exercise('Reverse Crunches', 'images/abs/Reverse Crunches.jpg', 'https://www.youtube.com/embed/JkTk8irSNKE'),
    Exercise('Bicycle Crunches', 'images/abs/Bicycle Crunches.jpg', 'https://www.youtube.com/embed/CakPX7X-mSw'),
    Exercise('Leg Raises', 'images/abs/Leg Raises.jpg', 'https://www.youtube.com/embed/FijNSgahpz0'),
    Exercise('Flutter Kicks', 'images/abs/Flutter Kicks.jpg', 'https://www.youtube.com/embed/tPmybsDX8ZY'),
    Exercise('Toe Touches', 'images/abs/Toe Touches.jpg', 'https://www.youtube.com/embed/20P7MU4Oaec'),
    Exercise('Mountain Climbers', 'images/abs/Mountain Climbers.jpg', 'https://www.youtube.com/embed/dqjZ6BGhY9s'),
    Exercise('V-Ups', 'images/abs/V-Ups.jpg', 'https://www.youtube.com/embed/Wks3wpNJqTg'),
    Exercise('Plank', 'images/abs/Plank.jpg', 'https://www.youtube.com/embed/xe2MXatLTUw'),
    Exercise('Side Plank', 'images/abs/Side Plank.jpg', 'https://www.youtube.com/embed/BFOyHDlY2UE'),
    Exercise('Plank with Shoulder Tap', 'images/abs/Plank with Shoulder Tap.jpg', 'https://www.youtube.com/embed/gccQ1hMX46U'),
  ],

  'quads': [
    Exercise('Barbell Back Squat', 'images/quads/Barbell Back Squat.jpg', 'https://www.youtube.com/embed/S9iWwaqbD3Q'),
    Exercise('Front Squat', 'images/quads/Front Squat.jpg', 'https://www.youtube.com/embed/_qv0m3tPd3s'),
    Exercise('Hack Squat', 'images/quads/Hack Squat.jpg', 'https://www.youtube.com/embed/g9i05umL5vc'),
    Exercise('Zercher Squat', 'images/quads/Zercher Squat.jpg', 'https://www.youtube.com/embed/xtMpMCCzPrU'),
    Exercise('Box Squat', 'images/quads/Box Squat.jpg', 'https://www.youtube.com/embed/Go4tSkrFIL8'),
    Exercise('Dumbbell Goblet Squat', 'images/quads/Dumbbell Goblet Squat.jpg', 'https://www.youtube.com/embed/lRYBbchqxtI'),
    Exercise('Dumbbell Split Squat', 'images/quads/Dumbbell Split Squat.jpg', 'https://www.youtube.com/embed/sw4MzpC8l58'),
    Exercise('Bulgarian Split Squat', 'images/quads/Bulgarian Split Squat.jpg', 'https://www.youtube.com/embed/or1frhkjBDc'),
    Exercise('Dumbbell Step-Ups', 'images/quads/Dumbbell Step-Ups.jpg', 'https://www.youtube.com/embed/8q9LVgN2RD4'),
    Exercise('Dumbbell Front Squat', 'images/quads/Dumbbell Front Squat.jpg', 'https://www.youtube.com/embed/0hw86JiWjCM'),
    Exercise('Leg Press', 'images/quads/Leg Press.jpg', 'https://www.youtube.com/embed/EotSw18oR9w'),
    Exercise('Leg Extensions', 'images/quads/Leg Extensions.jpg', 'https://www.youtube.com/embed/iQ92TuvBqRo'),
    Exercise('Cable Pull Through', 'images/quads/Cable Pull Through.jpg', 'https://www.youtube.com/embed/SuTI-n84ezA'),
    Exercise('Sissy Squat', 'images/quads/Sissy Squat.jpg', 'https://www.youtube.com/embed/f4ubaNbsq0Y'),
    Exercise('Smith Machine Front Squat', 'images/quads/Smith Machine Front Squat.jpg', 'https://www.youtube.com/embed/NO-6L6Blneg'),
  ],

  'traps': [
    Exercise('Barbell Shrugs', 'images/traps/Barbell Shrugs.jpg', 'https://www.youtube.com/embed/TUBuBI1U1wc'),
    Exercise('Behind-the-Back Barbell Shrugs', 'images/traps/Behind-the-Back Barbell Shrugs.jpg', 'https://www.youtube.com/embed/xKS-kFgXNPU'),
    Exercise('Upright Rows', 'images/traps/Upright Rows.jpg', 'https://www.youtube.com/embed/AWsGWt-VMl8'),
    Exercise('Snatch-Grip Deadlift', 'images/traps/Snatch-Grip Deadlift.jpg', 'https://www.youtube.com/embed/E42_MZOKktU'),
    Exercise('Rack Pulls', 'images/traps/Rack Pulls.jpg', 'https://www.youtube.com/embed/qFqbJqboCHU'),
    Exercise('Dumbbell Shrugs', 'images/traps/Dumbbell Shrugs.jpg', 'https://www.youtube.com/embed/rFsSeClGnNA'),
    Exercise('Incline Dumbbell Shrugs', 'images/traps/Incline Dumbbell Shrugs.jpg', 'https://www.youtube.com/embed/xEkIB8PeNv0'),
    Exercise('Farmers Walk', 'images/traps/Farmers Walk.jpg', 'https://www.youtube.com/embed/HDoNIkik8r8'),
    Exercise('Dumbbell Upright Rows', 'images/traps/Dumbbell Upright Rows.jpg', 'https://www.youtube.com/embed/fbc8FrvjFHk'),
    Exercise('Dumbbell High Pulls', 'images/traps/Dumbbell High Pulls.jpg', 'https://www.youtube.com/embed/o0KJD3Xn3fc'),
    Exercise('Cable Shrugs', 'images/traps/Cable Shrugs.jpg', 'https://www.youtube.com/embed/m2ifHLnEIaA'),
    Exercise('Cable Face Pulls', 'images/traps/Cable Face Pulls.jpg', 'https://www.youtube.com/embed/qEyoBOpvqR4'),
    Exercise('Reverse Cable Flyes', 'images/traps/Reverse Cable Flyes.jpg', 'https://www.youtube.com/embed/xswhV6zJaxY'),
    Exercise('Smith Machine Shrugs', 'images/traps/Smith Machine Shrugs.jpg', 'https://www.youtube.com/embed/zdBh_Ul2psI'),
    Exercise('Seated Cable Rows', 'images/traps/Seated Cable Rows.jpg', 'https://www.youtube.com/embed/qD1WZ5pSuvk'),
  ],

  'delts': [
    Exercise('Overhead Barbell Press', 'images/delts/Overhead Barbell Press.jpg', 'https://www.youtube.com/embed/4LBVP2Oe7fg'),
    Exercise('Behind-the-Neck Press', 'images/delts/Behind-the-Neck Press.jpg', 'https://www.youtube.com/embed/2EZLxxKRHYY'),
    Exercise('Upright Rows', 'images/delts/Upright Rows.jpg', 'https://www.youtube.com/embed/um3VVzqunPU'),
    Exercise('Front Barbell Raise', 'images/delts/Front Barbell Raise.jpg', 'https://www.youtube.com/embed/MNho_Zw3mFc'),
    Exercise('Arnold Press', 'images/delts/Arnold Press.jpg', 'https://www.youtube.com/embed/g4GUrEFoBxY'),
    Exercise('Seated Dumbbell Shoulder Press', 'images/delts/Seated Dumbbell Shoulder Press.jpg', 'https://www.youtube.com/embed/k6tzKisR3NY'),
    Exercise('Lateral Dumbbell Raises', 'images/delts/Lateral Dumbbell Raises.jpg', 'https://www.youtube.com/embed/iK22GwXJji0'),
    Exercise('Front Dumbbell Raises', 'images/delts/Front Dumbbell Raises.jpg', 'https://www.youtube.com/embed/h9xfpTrAvkE'),
    Exercise('Rear Delt Flyes', 'images/delts/Rear Delt Flyes.jpg', 'https://www.youtube.com/embed/LsT-bR_zxLo'),
    Exercise('Incline Bench Rear Delt Raises', 'images/delts/Incline Bench Rear Delt Raises.jpg', 'https://www.youtube.com/embed/lRTT2YABNIM'),
    Exercise('Dumbbell High Pulls', 'images/delts/Dumbbell High Pulls.jpg', 'https://www.youtube.com/embed/o0KJD3Xn3fc'),
    Exercise('Single-Arm Dumbbell Press', 'images/delts/Single-Arm Dumbbell Press.jpg', 'https://www.youtube.com/embed/Cs2uNF-jW5s'),
    Exercise('Cable Lateral Raises', 'images/delts/Cable Lateral Raises.jpg', 'https://www.youtube.com/embed/xrBcuPNTxLg'),
    Exercise('Cable Front Raises', 'images/delts/Cable Front Raises.jpg', 'https://www.youtube.com/embed/NdQE5Fhfqn4'),
    Exercise('Reverse Cable Flyes', 'images/delts/Reverse Cable Flyes.jpg', 'https://www.youtube.com/embed/xswhV6zJaxY'),
  ],

  'lats': [
    Exercise('Barbell Bent-Over Rows', 'images/lats/Barbell Bent-Over Rows.jpg', 'https://www.youtube.com/embed/phVtqawIgbk'),
    Exercise('Pendlay Rows', 'images/lats/Pendlay Rows.jpg', 'https://www.youtube.com/embed/EzFkN5ge5_k'),
    Exercise('Underhand Barbell Rows', 'images/lats/Underhand Barbell Rows.jpg', 'https://www.youtube.com/embed/ElNQUyDoxkM'),
    Exercise('T-Bar Rows', 'images/lats/T-Bar Rows.jpg', 'https://www.youtube.com/embed/MIulz5576AY'),
    Exercise('Deadlifts', 'images/lats/Deadlifts.jpg', 'https://www.youtube.com/embed/xNwpvDuZJ3k'),
    Exercise('One-Arm Dumbbell Row', 'images/lats/One-Arm Dumbbell Row.jpg', 'https://www.youtube.com/embed/s1H87k4tAaA'),
    Exercise('Dumbbell Pullover', 'images/lats/Dumbbell Pullover.jpg', 'https://www.youtube.com/embed/iy0VwFjTWds'),
    Exercise('Incline Dumbbell Rows', 'images/lats/Incline Dumbbell Rows.jpg', 'https://www.youtube.com/embed/tZUYS7X50so'),
    Exercise('Kroc Rows', 'images/lats/Kroc Rows.jpg', 'https://www.youtube.com/embed/FY53-vxHU34'),
    Exercise('Chest-Supported Dumbbell Rows', 'images/lats/Chest-Supported Dumbbell Rows.jpg', 'https://www.youtube.com/embed/woHK8Lws2xM'),
    Exercise('Lat Pulldowns', 'images/lats/Lat Pulldowns.jpg', 'https://www.youtube.com/embed/51ql2-2kLfA'),
    Exercise('Close-Grip Lat Pulldowns', 'images/lats/Close-Grip Lat Pulldowns.jpg', 'https://www.youtube.com/embed/E8cpBEoCrOs'),
    Exercise('Straight-Arm Cable Pulldowns', 'images/lats/Straight-Arm Cable Pulldowns.jpg', 'https://www.youtube.com/embed/RK2PRy9VwPg'),
    Exercise('Seated Cable Rows', 'images/lats/Seated Cable Rows.jpg', 'https://www.youtube.com/embed/qD1WZ5pSuvk'),
    Exercise('Single-Arm Cable Rows', 'images/lats/Single-Arm Cable Rows.jpg', 'https://www.youtube.com/embed/yIvvQc2Z6uM'),
  ],

  'glutes': [
    Exercise('Barbell Hip Thrusts', 'images/glutes/Barbell Hip Thrusts.jpg', 'https://www.youtube.com/embed/pUdIL5x0fWg'),
    Exercise('Barbell Glute Bridges', 'images/glutes/Barbell Glute Bridges.jpg', 'https://www.youtube.com/embed/DrZdxtfEgik'),
    Exercise('Sumo Deadlifts', 'images/glutes/Sumo Deadlifts.jpg', 'https://www.youtube.com/embed/pfSMst14EFk'),
    Exercise('Romanian Deadlifts', 'images/glutes/Romanian Deadlifts.jpg', 'https://www.youtube.com/embed/g5u75sgpn04'),
    Exercise('Good Mornings', 'images/glutes/Good Mornings.jpg', 'https://www.youtube.com/embed/7cpldMZjLOs'),
    Exercise('Dumbbell Step-Ups', 'images/glutes/Dumbbell Step-Ups.jpg', 'https://www.youtube.com/embed/8q9LVgN2RD4'),
    Exercise('Dumbbell Walking Lunges', 'images/glutes/Dumbbell Walking Lunges.jpg', 'https://www.youtube.com/embed/mJilHWIBWO8'),
    Exercise('Goblet Squats', 'images/glutes/Goblet Squats.jpg', 'https://www.youtube.com/embed/lRYBbchqxtI'),
    Exercise('Dumbbell Romanian Deadlifts', 'images/glutes/Dumbbell Romanian Deadlifts.jpg', 'https://www.youtube.com/embed/oQwnGfZFfzw'),
    Exercise('Kettlebell Swings', 'images/glutes/Kettlebell Swings.jpg', 'https://www.youtube.com/embed/n1df4ASFeZU'),
    Exercise('Cable Kickbacks', 'images/glutes/Cable Kickbacks.jpg', 'https://www.youtube.com/embed/SqO-VUEak2M'),
    Exercise('Cable Pull-Throughs', 'images/glutes/Cable Pull-Throughs.jpg', 'https://www.youtube.com/embed/iQ92TuvBqRo'),
    Exercise('Smith Machine Hip Thrusts', 'images/glutes/Smith Machine Hip Thrusts.jpg', 'https://www.youtube.com/embed/i5Vpsf-c6r0'),
    Exercise('Leg Press', 'images/glutes/Leg Press.jpg', 'https://www.youtube.com/embed/EotSw18oR9w'),
    Exercise('Abductor Machine', 'images/glutes/Abductor Machine.jpg', 'https://www.youtube.com/embed/vNixlpsswr8'),
  ],

  'hams': [
    Exercise('Romanian Deadlift', 'images/hams/Romanian Deadlift.jpg', 'https://www.youtube.com/embed/g5u75sgpn04'),
    Exercise('Lying Leg Curl', 'images/hams/Lying Leg Curl.jpg', 'https://www.youtube.com/embed/YQfohLcJQlI'),
    Exercise('Seated Leg Curl', 'images/hams/Seated Leg Curl.jpg', 'https://www.youtube.com/embed/wFJjI9gBrFQ'),
    Exercise('Good Mornings', 'images/hams/Good Mornings.jpg', 'https://www.youtube.com/embed/7cpldMZjLOs'),
    Exercise('Deadlift', 'images/hams/Deadlift.jpg', 'https://www.youtube.com/embed/xNwpvDuZJ3k'),
    Exercise('Single-Leg Romanian Deadlift', 'images/hams/Single-Leg Romanian Deadlift.jpg', 'https://www.youtube.com/embed/2shsC9MUkAM'),
    Exercise('Nordic Hamstring Curl', 'images/hams/Nordic Hamstring Curl.jpg', 'https://www.youtube.com/embed/3pU0J9KkFv0'),
    Exercise('Glute-Ham Raise (GHR)', 'images/hams/Glute-Ham Raise.jpg', 'https://www.youtube.com/embed/Ok9x6t5_Ki8'),
    Exercise('Cable Pull-Through', 'images/hams/Cable Pull-Through.jpg', 'https://www.youtube.com/embed/5zAkYWoahgU'),
    Exercise('Kettlebell Swing', 'images/hams/Kettlebell Swing.jpg', 'https://www.youtube.com/embed/y0xMCi8iS10'),
    Exercise('Reverse Hyperextension', 'images/hams/Reverse Hyperextension.jpg', 'https://www.youtube.com/embed/0P4nUsG3Y6Q'),
    Exercise('Swiss Ball Leg Curl', 'images/hams/Swiss Ball Leg Curl.jpg', 'https://www.youtube.com/embed/1i5dHjc4bGc'),
    Exercise('Standing Leg Curl Machine', 'images/hams/Standing Leg Curl.jpg', 'https://www.youtube.com/embed/iLwiyq663iM'),
    Exercise('Banded Hamstring Curl', 'images/hams/Banded Hamstring Curl.jpg', 'https://www.youtube.com/embed/C0DPdy98e4c'),
    Exercise('Stiff-Leg Deadlift', 'images/hams/Stiff-Leg Deadlift.jpg', 'https://www.youtube.com/embed/nhoM4ZlX3ao'),
    ],
};

  void _handleMuscleTap(String muscleId) {
    setState(() {
      _selectedMuscle = muscleId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      const Text(
                        'Body Diagram',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Click on a Muscle Group to See the Exercises',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 16),

                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showingFront = !_showingFront;
                            _selectedMuscle = null;
                          });
                        },
                        icon: const Icon(Icons.swap_horiz),
                        label: Text(_showingFront ? 'Show Back View' : 'Show Front View'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  child: Center(
                    child: MouseRegion(
                      onHover: (event) {
                        RenderBox box = context.findRenderObject() as RenderBox;
                        final localPos = box.globalToLocal(event.position);
                        _handleHover(localPos);
                      },
                      onExit: (event) {
                        setState(() {
                          _hoveredMuscle = null;
                        });
                      },
                      child: GestureDetector(
                        onTapUp:(details) {
                          final RenderBox box = context.findRenderObject() as RenderBox;
                          final localPos = box.globalToLocal(details.globalPosition);
                          _handleDiagramTap(localPos);
                        },
                        child: CustomPaint(
                          size: const Size(200, 400),
                          painter: _showingFront ? RealisticFrontBodyPainter(selectedMuscle: _selectedMuscle, hoveredMuscle: _hoveredMuscle) : RealisticBackBodyPainter(selectedMuscle: _selectedMuscle),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              if (_selectedMuscle != null) ...[
                const SizedBox(height: 20),
                _buildExerciseList(_selectedMuscle!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleHover(Offset position) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardPadding = 40.0;
    final diagramWidth = 200.0;
    final centerX = (screenWidth - cardPadding) / 2;
    final adjustedX = position.dx - (centerX - diagramWidth / 2);
    final adjustedY = position.dy - 100;

    String? newHovered;

    if (_showingFront) {
      newHovered = _detectFrontMuscleFromPosition(adjustedX, adjustedY);
    } else {
      newHovered = _detectBackMuscleFromPosition(adjustedX, adjustedY);
    }

    if (newHovered != _hoveredMuscle) {
      setState(() {
        _hoveredMuscle = newHovered;
      });
    }
  }

  void _handleDiagramTap(Offset position) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardPadding = 40.0;
    final diagramWidth = 200.0;
    final centerX = (screenWidth - cardPadding) / 2;
    final adjustedX = position.dx - (centerX - diagramWidth / 2);
    final adjustedY = position.dy - 100;

    String? tappedMuscle;

    if (_showingFront) {
      tappedMuscle = _detectFrontMuscleFromPosition(adjustedX, adjustedY);
    } else {
      tappedMuscle = _detectBackMuscleFromPosition(adjustedX, adjustedY);
    }

    if (tappedMuscle != null) {
      _handleMuscleTap(tappedMuscle);
    }
  }

  String? _detectFrontMuscleFromPosition(double x, double y) {
    final scale = 200.0 / 300.0;
    x = x / scale;
    y = y / scale;

    // Shoulders
    if ((x >= 40 && x <= 95 && y >= 100 && y <= 150) ||
        (x >= 205 && x <= 260 && y >= 100 && y <= 150)) {
      return 'shoulders';
    }
    // Chest
    else if (x >= 90 && x <= 210 && y >= 120 && y <= 190) {
      return 'chest';
    }
    // Biceps
    else if ((x >= 35 && x <= 85 && y >= 155 && y <= 240) ||
        (x >= 215 && x <= 265 && y >= 155 && y <= 240)) {
      return 'biceps';
    }
    // Forearms
    else if ((x >= 25 && x <= 75 && y >= 245 && y <= 335) ||
        (x >= 225 && x <= 275 && y >= 245 && y <= 335)) {
      return 'forearms';
    }
    // Abs
    else if (x >= 110 && x <= 190 && y >= 195 && y <= 310) {
      return 'abs';
    }
    // Quads
    else if (x >= 95 && x <= 205 && y >= 315 && y <= 480) {
      return 'quads';
    }
    // Calves
    else if (x >= 95 && x <= 205 && y >= 485 && y <= 570) {
      return 'calves';
    }
    return null;
  }

  String? _detectBackMuscleFromPosition(double x, double y) {
    final scale = 200.0 / 300.0;
    x = x / scale;
    y = y / scale;

    // Traps
    if (x >= 100 && x <= 200 && y >= 90 && y <= 140) {
      return 'traps';
    }
    // Shoulders (rear delts)
    else if ((x >= 40 && x <= 95 && y >= 105 && y <= 160) ||
        (x >= 205 && x <= 260 && y >= 105 && y <= 160)) {
      return 'shoulders';
    }
    // Lats
    else if (x >= 80 && x <= 220 && y >= 145 && y <= 260) {
      return 'lats';
    }
    // Glutes
    else if (x >= 100 && x <= 200 && y >= 280 && y <= 350) {
      return 'glutes';
    }
    // Hamstrings
    else if (x >= 95 && x <= 205 && y >= 355 && y <= 480) {
      return 'hamstrings';
    }
    // Calves
    else if (x >= 95 && x <= 205 && y >= 485 && y <= 570) {
      return 'calves';
    }
    return null;
  }

  Widget _buildExerciseList(String muscleId) {
    final exercises = _exercises[muscleId] ?? [];
    final muscleName = muscleId.toUpperCase();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$muscleName EXERCISES',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _selectedMuscle = null;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...exercises.map(
              (exercise) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.play_circle_outline, color: Color(0xFF7C3AED)),
                  title: Text(exercise.name),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final uri = Uri.parse(exercise.videoURL);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RealisticFrontBodyPainter extends CustomPainter {
  final String? selectedMuscle;
  final String? hoveredMuscle;

  RealisticFrontBodyPainter({this.selectedMuscle, this.hoveredMuscle});

  @override
  void paint(Canvas canvas, Size size) {
    // Color scheme matching the reference image
    final bodyBaseColor = const Color(0xFF6B7A8F); // Grayish blue for base body
    final muscleHighlight = const Color(0xFFE57B9E); // Pink for muscles
    final darkOutline = const Color(0xFF2A3540);
    
    // Draw the complete body structure
    _drawBodyBase(canvas, size, bodyBaseColor, darkOutline);
    _drawMuscles(canvas, size, muscleHighlight, darkOutline);
  }

  void _drawBodyBase(Canvas canvas, Size size, Color baseColor, Color outline) {
    final basePaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill;
    
    final outlinePaint = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // HEAD
    final headPath = Path()
      ..addOval(Rect.fromCenter(center: const Offset(150, 50), width: 45, height: 55));
    canvas.drawPath(headPath, basePaint);
    canvas.drawPath(headPath, outlinePaint);

    // NECK
    final neckPath = Path()
      ..moveTo(135, 75)
      ..lineTo(135, 95)
      ..lineTo(165, 95)
      ..lineTo(165, 75)
      ..close();
    canvas.drawPath(neckPath, basePaint);
    canvas.drawPath(neckPath, outlinePaint);

    // TORSO
    final torsoPath = Path()
      ..moveTo(135, 95) // Neck connection
      ..lineTo(105, 110) // Left shoulder
      ..lineTo(95, 160) // Left armpit
      ..lineTo(95, 280) // Left waist
      ..lineTo(110, 315) // Left hip
      ..lineTo(115, 480) // Left thigh
      ..lineTo(125, 600) // Left ankle
      ..lineTo(145, 600) // Cross to right ankle
      ..lineTo(145, 480) // Right thigh start
      ..lineTo(155, 480) // Right thigh mid
      ..lineTo(155, 600) // Right ankle
      ..lineTo(175, 600) // Right foot
      ..lineTo(175, 480) // Back up right leg
      ..lineTo(185, 315) // Right hip
      ..lineTo(205, 280) // Right waist
      ..lineTo(205, 160) // Right armpit
      ..lineTo(195, 110) // Right shoulder
      ..lineTo(165, 95) // Neck right
      ..close();
    canvas.drawPath(torsoPath, basePaint);
    canvas.drawPath(torsoPath, outlinePaint);

    // LEFT ARM
    final leftArmPath = Path()
      ..moveTo(105, 110) // Shoulder
      ..lineTo(85, 130) // Upper arm
      ..lineTo(70, 200) // Elbow
      ..lineTo(60, 240) // Forearm
      ..lineTo(55, 300) // Wrist
      ..lineTo(50, 335) // Hand
      ..lineTo(60, 335) // Hand width
      ..lineTo(65, 300) // Wrist inner
      ..lineTo(75, 240) // Forearm inner
      ..lineTo(90, 200) // Elbow inner
      ..lineTo(95, 160) // Armpit
      ..close();
    canvas.drawPath(leftArmPath, basePaint);
    canvas.drawPath(leftArmPath, outlinePaint);

    // RIGHT ARM (mirror)
    final rightArmPath = Path()
      ..moveTo(195, 110)
      ..lineTo(215, 130)
      ..lineTo(230, 200)
      ..lineTo(240, 240)
      ..lineTo(245, 300)
      ..lineTo(250, 335)
      ..lineTo(240, 335)
      ..lineTo(235, 300)
      ..lineTo(225, 240)
      ..lineTo(210, 200)
      ..lineTo(205, 160)
      ..close();
    canvas.drawPath(rightArmPath, basePaint);
    canvas.drawPath(rightArmPath, outlinePaint);
  }

  void _drawMuscles(Canvas canvas, Size size, Color muscleColor, Color outline) {
    final isChestSelected = selectedMuscle == 'chest';
    final isBicepsSelected = selectedMuscle == 'biceps';
    final isAbsSelected = selectedMuscle == 'abs';
    final isQuadsSelected = selectedMuscle == 'quads';
    final isShouldersSelected = selectedMuscle == 'shoulders';
    final isForearmsSelected = selectedMuscle == 'forearms';
    final isCalvesSelected = selectedMuscle == 'calves';

    // SHOULDERS (Deltoids)
    _drawMuscleGroup(canvas, _getShoulderPaths(), muscleColor, outline, isShouldersSelected);

    // CHEST (Pectorals)
    _drawMuscleGroup(canvas, _getChestPaths(), muscleColor, outline, isChestSelected);

    // BICEPS
    _drawMuscleGroup(canvas, _getBicepsPaths(), muscleColor, outline, isBicepsSelected);

    // FOREARMS
    _drawMuscleGroup(canvas, _getForearmPaths(), muscleColor, outline, isForearmsSelected);

    // ABS (Abdominals)
    _drawMuscleGroup(canvas, _getAbsPaths(), muscleColor, outline, isAbsSelected);

    // QUADS
    _drawMuscleGroup(canvas, _getQuadsPaths(), muscleColor, outline, isQuadsSelected);

    // CALVES
    _drawMuscleGroup(canvas, _getCalvesPaths(), muscleColor, outline, isCalvesSelected);
  }

  void _drawMuscleGroup(Canvas canvas, List<Path> paths, Color color, Color outline, bool isSelected) {
    final opacity = isSelected ? 1.0 : 0.75;
    
    final musclePaint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    final musclOutline = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.0 : 1.5;

    for (final path in paths) {
      canvas.drawPath(path, musclePaint);
      canvas.drawPath(path, musclOutline);
      
      if (isSelected) {
        final glowPaint = Paint()
          ..color = color.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawPath(path, glowPaint);
      }
    }
  }

  List<Path> _getShoulderPaths() {
    // Left deltoid
    final leftDelt = Path()
      ..moveTo(105, 110)
      ..quadraticBezierTo(85, 115, 75, 135)
      ..quadraticBezierTo(70, 150, 85, 160)
      ..quadraticBezierTo(90, 165, 95, 160)
      ..lineTo(105, 130)
      ..close();

    // Right deltoid
    final rightDelt = Path()
      ..moveTo(195, 110)
      ..quadraticBezierTo(215, 115, 225, 135)
      ..quadraticBezierTo(230, 150, 215, 160)
      ..quadraticBezierTo(210, 165, 205, 160)
      ..lineTo(195, 130)
      ..close();

    return [leftDelt, rightDelt];
  }

  List<Path> _getChestPaths() {
    // Left pec
    final leftPec = Path()
      ..moveTo(135, 110)
      ..quadraticBezierTo(115, 115, 105, 130)
      ..lineTo(95, 160)
      ..quadraticBezierTo(100, 175, 120, 180)
      ..lineTo(140, 175)
      ..lineTo(145, 140)
      ..close();

    // Right pec
    final rightPec = Path()
      ..moveTo(165, 110)
      ..quadraticBezierTo(185, 115, 195, 130)
      ..lineTo(205, 160)
      ..quadraticBezierTo(200, 175, 180, 180)
      ..lineTo(160, 175)
      ..lineTo(155, 140)
      ..close();

    return [leftPec, rightPec];
  }

  List<Path> _getBicepsPaths() {
    // Left bicep
    final leftBicep = Path()
      ..addOval(Rect.fromCenter(center: const Offset(78, 190), width: 28, height: 55));

    // Right bicep
    final rightBicep = Path()
      ..addOval(Rect.fromCenter(center: const Offset(222, 190), width: 28, height: 55));

    return [leftBicep, rightBicep];
  }

  List<Path> _getForearmPaths() {
    // Left forearm muscles
    final leftForearm = Path()
      ..moveTo(70, 240)
      ..lineTo(60, 280)
      ..lineTo(58, 310)
      ..lineTo(68, 310)
      ..lineTo(75, 280)
      ..lineTo(80, 240)
      ..close();

    // Right forearm muscles
    final rightForearm = Path()
      ..moveTo(230, 240)
      ..lineTo(240, 280)
      ..lineTo(242, 310)
      ..lineTo(232, 310)
      ..lineTo(225, 280)
      ..lineTo(220, 240)
      ..close();

    return [leftForearm, rightForearm];
  }

  List<Path> _getAbsPaths() {
    final absList = <Path>[];
    
    // Upper abs (6 pack)
    for (int i = 0; i < 3; i++) {
      // Left side
      absList.add(Path()
        ..addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(130, 210 + i * 30.0),
            width: 25,
            height: 24,
          ),
          const Radius.circular(4),
        )));
      
      // Right side
      absList.add(Path()
        ..addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(170, 210 + i * 30.0),
            width: 25,
            height: 24,
          ),
          const Radius.circular(4),
        )));
    }

    // Obliques
    final leftOblique = Path()
      ..moveTo(105, 230)
      ..lineTo(95, 280)
      ..lineTo(110, 295)
      ..lineTo(115, 250)
      ..close();

    final rightOblique = Path()
      ..moveTo(195, 230)
      ..lineTo(205, 280)
      ..lineTo(190, 295)
      ..lineTo(185, 250)
      ..close();

    absList.addAll([leftOblique, rightOblique]);

    return absList;
  }

  List<Path> _getQuadsPaths() {
    // Left quad (outer and inner)
    final leftQuadOuter = Path()
      ..moveTo(110, 320)
      ..lineTo(95, 400)
      ..lineTo(100, 475)
      ..lineTo(118, 475)
      ..lineTo(125, 400)
      ..lineTo(120, 320)
      ..close();

    final leftQuadInner = Path()
      ..moveTo(125, 330)
      ..lineTo(130, 400)
      ..lineTo(135, 475)
      ..lineTo(145, 475)
      ..lineTo(145, 400)
      ..lineTo(140, 330)
      ..close();

    // Right quad (outer and inner)
    final rightQuadInner = Path()
      ..moveTo(155, 330)
      ..lineTo(155, 400)
      ..lineTo(155, 475)
      ..lineTo(165, 475)
      ..lineTo(170, 400)
      ..lineTo(175, 330)
      ..close();

    final rightQuadOuter = Path()
      ..moveTo(180, 320)
      ..lineTo(175, 400)
      ..lineTo(182, 475)
      ..lineTo(200, 475)
      ..lineTo(205, 400)
      ..lineTo(190, 320)
      ..close();

    return [leftQuadOuter, leftQuadInner, rightQuadInner, rightQuadOuter];
  }

  List<Path> _getCalvesPaths() {
    // Left calf
    final leftCalf = Path()
      ..addOval(Rect.fromCenter(center: const Offset(120, 530), width: 35, height: 55));

    // Right calf
    final rightCalf = Path()
      ..addOval(Rect.fromCenter(center: const Offset(180, 530), width: 35, height: 55));

    return [leftCalf, rightCalf];
  }

  @override
  bool shouldRepaint(RealisticFrontBodyPainter oldDelegate) {
    return oldDelegate.selectedMuscle != selectedMuscle;
  }
}

class RealisticBackBodyPainter extends CustomPainter {
  final String? selectedMuscle;

  RealisticBackBodyPainter({this.selectedMuscle});

  @override
  void paint(Canvas canvas, Size size) {
    final bodyBaseColor = const Color(0xFF6B7A8F);
    final muscleHighlight = const Color(0xFFE57B9E);
    final darkOutline = const Color(0xFF2A3540);
    
    _drawBodyBase(canvas, size, bodyBaseColor, darkOutline);
    _drawMuscles(canvas, size, muscleHighlight, darkOutline);
  }

  void _drawBodyBase(Canvas canvas, Size size, Color baseColor, Color outline) {
    final basePaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill;
    
    final outlinePaint = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Similar to front, but back view structure
    // HEAD
    final headPath = Path()
      ..addOval(Rect.fromCenter(center: const Offset(150, 50), width: 45, height: 55));
    canvas.drawPath(headPath, basePaint);
    canvas.drawPath(headPath, outlinePaint);

    // NECK
    final neckPath = Path()
      ..moveTo(135, 75)
      ..lineTo(135, 95)
      ..lineTo(165, 95)
      ..lineTo(165, 75)
      ..close();
    canvas.drawPath(neckPath, basePaint);
    canvas.drawPath(neckPath, outlinePaint);

    // TORSO (back view)
    final torsoPath = Path()
      ..moveTo(135, 95)
      ..lineTo(105, 110)
      ..lineTo(95, 160)
      ..lineTo(95, 280)
      ..lineTo(110, 315)
      ..lineTo(115, 480)
      ..lineTo(125, 600)
      ..lineTo(145, 600)
      ..lineTo(145, 480)
      ..lineTo(155, 480)
      ..lineTo(155, 600)
      ..lineTo(175, 600)
      ..lineTo(175, 480)
      ..lineTo(185, 315)
      ..lineTo(205, 280)
      ..lineTo(205, 160)
      ..lineTo(195, 110)
      ..lineTo(165, 95)
      ..close();
    canvas.drawPath(torsoPath, basePaint);
    canvas.drawPath(torsoPath, outlinePaint);

    // LEFT ARM
    final leftArmPath = Path()
      ..moveTo(105, 110)
      ..lineTo(85, 130)
      ..lineTo(70, 200)
      ..lineTo(60, 240)
      ..lineTo(55, 300)
      ..lineTo(50, 335)
      ..lineTo(60, 335)
      ..lineTo(65, 300)
      ..lineTo(75, 240)
      ..lineTo(90, 200)
      ..lineTo(95, 160)
      ..close();
    canvas.drawPath(leftArmPath, basePaint);
    canvas.drawPath(leftArmPath, outlinePaint);

    // RIGHT ARM
    final rightArmPath = Path()
      ..moveTo(195, 110)
      ..lineTo(215, 130)
      ..lineTo(230, 200)
      ..lineTo(240, 240)
      ..lineTo(245, 300)
      ..lineTo(250, 335)
      ..lineTo(240, 335)
      ..lineTo(235, 300)
      ..lineTo(225, 240)
      ..lineTo(210, 200)
      ..lineTo(205, 160)
      ..close();
    canvas.drawPath(rightArmPath, basePaint);
    canvas.drawPath(rightArmPath, outlinePaint);
  }

  void _drawMuscles(Canvas canvas, Size size, Color muscleColor, Color outline) {
    final isTrapsSelected = selectedMuscle == 'traps';
    final isShoulderSelected = selectedMuscle == 'shoulders';
    final isLatsSelected = selectedMuscle == 'lats';
    final isGlutesSelected = selectedMuscle == 'glutes';
    final isHamstringsSelected = selectedMuscle == 'hamstrings';
    final isCalvesSelected = selectedMuscle == 'calves';

    // TRAPS
    _drawMuscleGroup(canvas, _getTrapsPaths(), muscleColor, outline, isTrapsSelected);

    // REAR DELTS
    _drawMuscleGroup(canvas, _getRearDeltsPaths(), muscleColor, outline, isShoulderSelected);

    // LATS
    _drawMuscleGroup(canvas, _getLatsPaths(), muscleColor, outline, isLatsSelected);

    // LOWER BACK
    _drawMuscleGroup(canvas, _getLowerBackPaths(), muscleColor, outline, false);

    // GLUTES
    _drawMuscleGroup(canvas, _getGlutesPaths(), muscleColor, outline, isGlutesSelected);

    // HAMSTRINGS
    _drawMuscleGroup(canvas, _getHamstringsPaths(), muscleColor, outline, isHamstringsSelected);

    // CALVES
    _drawMuscleGroup(canvas, _getCalvesPaths(), muscleColor, outline, isCalvesSelected);
  }

  void _drawMuscleGroup(Canvas canvas, List<Path> paths, Color color, Color outline, bool isSelected) {
    final opacity = isSelected ? 1.0 : 0.75;
    
    final musclePaint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    final muscleOutline = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.0 : 1.5;

    for (final path in paths) {
      canvas.drawPath(path, musclePaint);
      canvas.drawPath(path, muscleOutline);
      
      if (isSelected) {
        final glowPaint = Paint()
          ..color = color.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawPath(path, glowPaint);
      }
    }
  }

  List<Path> _getTrapsPaths() {
    final traps = Path()
      ..moveTo(135, 95)
      ..lineTo(120, 100)
      ..lineTo(105, 110)
      ..lineTo(100, 130)
      ..lineTo(110, 145)
      ..lineTo(135, 150)
      ..lineTo(150, 145)
      ..lineTo(165, 150)
      ..lineTo(190, 145)
      ..lineTo(200, 130)
      ..lineTo(195, 110)
      ..lineTo(180, 100)
      ..lineTo(165, 95)
      ..close();

    return [traps];
  }

  List<Path> _getRearDeltsPaths() {
    // Left rear delt
    final leftDelt = Path()
      ..moveTo(105, 110)
      ..quadraticBezierTo(85, 120, 75, 140)
      ..quadraticBezierTo(72, 155, 85, 165)
      ..lineTo(95, 160)
      ..lineTo(100, 130)
      ..close();

    // Right rear delt
    final rightDelt = Path()
      ..moveTo(195, 110)
      ..quadraticBezierTo(215, 120, 225, 140)
      ..quadraticBezierTo(228, 155, 215, 165)
      ..lineTo(205, 160)
      ..lineTo(200, 130)
      ..close();

    return [leftDelt, rightDelt];
  }

  List<Path> _getLatsPaths() {
    // Left lat
    final leftLat = Path()
      ..moveTo(110, 145)
      ..lineTo(95, 160)
      ..lineTo(95, 240)
      ..lineTo(105, 260)
      ..lineTo(125, 255)
      ..lineTo(135, 240)
      ..lineTo(140, 180)
      ..close();

    // Right lat
    final rightLat = Path()
      ..moveTo(190, 145)
      ..lineTo(205, 160)
      ..lineTo(205, 240)
      ..lineTo(195, 260)
      ..lineTo(175, 255)
      ..lineTo(165, 240)
      ..lineTo(160, 180)
      ..close();

    return [leftLat, rightLat];
  }

  List<Path> _getLowerBackPaths() {
    final lowerBack = Path()
      ..moveTo(125, 255)
      ..lineTo(115, 280)
      ..lineTo(120, 300)
      ..lineTo(150, 305)
      ..lineTo(180, 300)
      ..lineTo(185, 280)
      ..lineTo(175, 255)
      ..close();

    return [lowerBack];
  }

  List<Path> _getGlutesPaths() {
    // Left glute
    final leftGlute = Path()
      ..moveTo(120, 300)
      ..lineTo(110, 315)
      ..quadraticBezierTo(105, 335, 115, 350)
      ..lineTo(140, 345)
      ..lineTo(145, 320)
      ..close();

    // Right glute
    final rightGlute = Path()
      ..moveTo(180, 300)
      ..lineTo(190, 315)
      ..quadraticBezierTo(195, 335, 185, 350)
      ..lineTo(160, 345)
      ..lineTo(155, 320)
      ..close();

    return [leftGlute, rightGlute];
  }

  List<Path> _getHamstringsPaths() {
    // Left hamstring (outer and inner heads)
    final leftHamOuter = Path()
      ..moveTo(115, 355)
      ..lineTo(100, 420)
      ..lineTo(105, 475)
      ..lineTo(120, 475)
      ..lineTo(125, 420)
      ..lineTo(122, 355)
      ..close();

    final leftHamInner = Path()
      ..moveTo(130, 360)
      ..lineTo(132, 420)
      ..lineTo(137, 475)
      ..lineTo(145, 475)
      ..lineTo(143, 420)
      ..lineTo(140, 360)
      ..close();

    // Right hamstring
    final rightHamInner = Path()
      ..moveTo(160, 360)
      ..lineTo(157, 420)
      ..lineTo(155, 475)
      ..lineTo(165, 475)
      ..lineTo(168, 420)
      ..lineTo(170, 360)
      ..close();

    final rightHamOuter = Path()
      ..moveTo(178, 355)
      ..lineTo(175, 420)
      ..lineTo(180, 475)
      ..lineTo(195, 475)
      ..lineTo(200, 420)
      ..lineTo(185, 355)
      ..close();

    return [leftHamOuter, leftHamInner, rightHamInner, rightHamOuter];
  }

  List<Path> _getCalvesPaths() {
    // Left calf
    final leftCalf = Path()
      ..addOval(Rect.fromCenter(center: const Offset(120, 530), width: 35, height: 55));

    // Right calf
    final rightCalf = Path()
      ..addOval(Rect.fromCenter(center: const Offset(180, 530), width: 35, height: 55));

    return [leftCalf, rightCalf];
  }

  @override
  bool shouldRepaint(RealisticBackBodyPainter oldDelegate) {
    return oldDelegate.selectedMuscle != selectedMuscle;
  }
}

/// HISTORY
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _workoutLogs = [];
  bool _isLoading = true;
  String _searchText = '';
  String? _filterDate;
  String _sortBy = 'newest';

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Not authenticated');
      }

      var queryBuilder = supabase
          .from('workout_logs')
          .select('id, date, exercise_name, sets, reps, weight, notes, volume, created_at')
          .eq('user_id', user.id);

      if (_filterDate != null && _filterDate!.isNotEmpty) {
        queryBuilder = queryBuilder.eq('date', _filterDate!);
      }

      if (_searchText.isNotEmpty) {
        queryBuilder = queryBuilder.ilike('exercise_name', '%$_searchText%');
      }

      List<dynamic> response;
      
      if (_sortBy == 'oldest') {
        response = await queryBuilder
            .order('date', ascending: true)
            .limit(200);
      } else if (_sortBy == 'volume') {
        response = await queryBuilder
            .order('volume', ascending: false)
            .limit(200);
      } else {
        response = await queryBuilder
            .order('date', ascending: false)
            .order('created_at', ascending: false)
            .limit(200);
      }
      
      if (mounted) {
        setState(() {
          _workoutLogs = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading logs: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load workout history: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteLog(String logId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workout'),
        content: const Text('Are you sure you want to delete this workout log?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      await supabase
          .from('workout_logs')
          .delete()
          .eq('id', logId)
          .eq('user_id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout deleted'),
            backgroundColor: Colors.green,
          ),
        );
        _loadLogs();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectFilterDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _filterDate = picked.toIso8601String().split('T')[0];
      });
      _loadLogs();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _filterDate = null;
    });
    _loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Card(
        margin: const EdgeInsets.all(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Workout History',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Filters
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectFilterDate,
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(
                        _filterDate ?? 'Filter by Date',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (_filterDate != null) ...[
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearDateFilter,
                      tooltip: 'Clear',
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              TextField(
                decoration: const InputDecoration(
                  labelText: 'Search Exercise',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchText = value.trim();
                  });
                  _loadLogs();
                },
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: _sortBy,
                decoration: const InputDecoration(labelText: 'Sort By'),
                items: const [
                  DropdownMenuItem(value: 'newest', child: Text('Newest First')),
                  DropdownMenuItem(value: 'oldest', child: Text('Oldest First')),
                  DropdownMenuItem(value: 'volume', child: Text('Highest Volume')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _sortBy = value;
                    });
                    _loadLogs();
                  }
                },
              ),
              const SizedBox(height: 20),

              // Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _workoutLogs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.fitness_center, size: 64, color: Colors.grey[600]),
                                const SizedBox(height: 16),
                                Text(
                                  _searchText.isNotEmpty || _filterDate != null
                                      ? 'No workouts found'
                                      : 'No workouts logged yet',
                                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _workoutLogs.length,
                            itemBuilder: (context, index) {
                              final log = _workoutLogs[index];
                              final volume = (log['sets'] ?? 0) *
                                  (log['reps'] ?? 0) *
                                  (log['weight'] ?? 0);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(
                                    log['exercise_name'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    '${log['date']} • ${log['sets']}×${log['reps']} @ ${log['weight']} lbs • Vol: ${volume.toInt()}',
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _deleteLog(log['id'].toString()),
                                  ),
                                  onTap: log['notes']?.toString().isNotEmpty == true
                                      ? () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text(log['exercise_name']),
                                              content: Text(log['notes'] ?? ''),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: const Text('Close'),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                      : null,
                                ),
                              );
                            },
                          ),
              ),

              // Summary
              if (!_isLoading && _workoutLogs.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Showing ${_workoutLogs.length} workout${_workoutLogs.length == 1 ? '' : 's'}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// PROGRESS
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class ExerciseStats {
  final String exerciseName;
  final double maxWeight;
  final int sessions;
  final double totalVolume;
  final String lastDate;

  ExerciseStats({
    required this.exerciseName,
    required this.maxWeight,
    required this.sessions,
    required this.totalVolume,
    required this.lastDate,
  });
}

class _ProgressScreenState extends State<ProgressScreen> {
  List<ExerciseStats> _exerciseStats = [];
  bool _isLoading = true;
  String _sortBy = 'volume';

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Not Authenticated');
      }

      List<ExerciseStats> stats;

      try {
        final viewData = await supabase.from('exercise_stats').select('exercise_name, total_volume, max_weight, last_date').order('total_volume', ascending: false);

        stats = (viewData as List).map((item) {
          return ExerciseStats(
            exerciseName: item['exercise_name'] ?? '', 
            maxWeight: (item['max_weight'] ?? 0).toDouble(), 
            sessions: 0, 
            totalVolume: (item['total_volume'] ?? 0).toDouble(), 
            lastDate: item['last_date'] ?? '',
          );
        }).toList();
      } catch (e) {
        debugPrint('exercise_stats View Not Found. Calculating from Logs.');
        final logs = await supabase.from('workout_logs').select('exercise_name, sets, reps, weight, date').eq('user_id', user.id).order('date', ascending: false);
        final Map<String, ExerciseStats> byExercise = {};

        for (final log in logs) {
          final exerciseName = log['exercise_name'] as String;
          final sets = log['sets'] ?? 0;
          final reps = log['reps'] ?? 0;
          final weight = (log['weight'] ?? 0).toDouble();
          final date = log['date'] ?? '';
          final volume = sets * reps * weight;

          if (!byExercise.containsKey(exerciseName)) {
            byExercise[exerciseName] = ExerciseStats(
              exerciseName: exerciseName, 
              maxWeight: weight, 
              sessions: 1, 
              totalVolume: volume, 
              lastDate: date,
            );
          } else {
            final existing = byExercise[exerciseName]!;
            byExercise[exerciseName] = ExerciseStats(
              exerciseName: exerciseName, 
              maxWeight: weight > existing.maxWeight ? weight : existing.maxWeight, 
              sessions: existing.sessions + 1, 
              totalVolume: existing.totalVolume + volume, 
              lastDate: existing.lastDate,
            );
          }
        }

        stats = byExercise.values.toList();
      }

      _sortStats(stats);

      if (mounted) {
        setState(() {
          _exerciseStats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error Loading Progress: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to Load Progress: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _sortStats(List<ExerciseStats> stats) {
    switch (_sortBy) {
      case 'max_weight':
        stats.sort((a, b) => b.maxWeight.compareTo(a.maxWeight));
        break;
      case 'sessions':
        stats.sort((a, b) => b.sessions.compareTo(a.sessions));
        break;
      case 'recent':
        stats.sort((a, b) => b.lastDate.compareTo(a.lastDate));
        break;
      case 'volume':
      default:
        stats.sort((a, b) => b.totalVolume.compareTo(a.totalVolume));
        break;
    }
  }

  void _onSortChanged(String? value) {
    if (value != null) {
      setState(() {
        _sortBy = value;
        _sortStats(_exerciseStats);
      });
    }
  }

  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toInt().toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Card(
        margin: const EdgeInsets.all(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Progress',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Computed stats per exercise',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Sort dropdown
              DropdownButtonFormField<String>(
                initialValue: _sortBy,
                decoration: const InputDecoration(
                  labelText: 'Sort By',
                  prefixIcon: Icon(Icons.sort),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'volume',
                    child: Text('Total Volume'),
                  ),
                  DropdownMenuItem(
                    value: 'max_weight',
                    child: Text('Max Weight'),
                  ),
                  DropdownMenuItem(
                    value: 'sessions',
                    child: Text('Most Sessions'),
                  ),
                  DropdownMenuItem(
                    value: 'recent',
                    child: Text('Most Recent'),
                  ),
                ],
                onChanged: _onSortChanged,
              ),
              const SizedBox(height: 20),

              // Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _exerciseStats.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.analytics_outlined,
                                  size: 64,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No progress data yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Log some workouts to see progress.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _exerciseStats.length,
                            itemBuilder: (context, index) {
                              final stat = _exerciseStats[index];
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ExpansionTile(
                                  title: Text(
                                    stat.exerciseName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Volume: ${_formatNumber(stat.totalVolume)} • Max: ${stat.maxWeight.toInt()} lbs',
                                    style: TextStyle(color: Colors.grey[400]),
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        children: [
                                          _buildStatRow(
                                            Icons.fitness_center,
                                            'Max Weight',
                                            '${stat.maxWeight.toInt()} lbs',
                                            Colors.orange,
                                          ),
                                          const SizedBox(height: 12),
                                          _buildStatRow(
                                            Icons.calendar_today,
                                            'Sessions',
                                            stat.sessions > 0
                                                ? '${stat.sessions}'
                                                : 'N/A',
                                            Colors.blue,
                                          ),
                                          const SizedBox(height: 12),
                                          _buildStatRow(
                                            Icons.show_chart,
                                            'Total Volume',
                                            _formatNumber(stat.totalVolume),
                                            Colors.green,
                                          ),
                                          const SizedBox(height: 12),
                                          _buildStatRow(
                                            Icons.access_time,
                                            'Last Workout',
                                            stat.lastDate.isNotEmpty
                                                ? stat.lastDate
                                                : 'N/A',
                                            Colors.purple,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),

              // Summary
              if (!_isLoading && _exerciseStats.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Tracking ${_exerciseStats.length} exercise${_exerciseStats.length == 1 ? '' : 's'}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
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
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _weeklyGoalCtrl = TextEditingController();
  String _units = 'lbs';
  bool _isLoading = true;
  bool _isSaving = false;
  String? _successMessage;
  String? _errorMessage;
  String? _userEmail;
  String? _username;
  DateTime? _accountCreated;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _weeklyGoalCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Not Authenticated.');
      }

      _userEmail = user.email;
      _username = user.userMetadata?['username'] as String? ?? 'Athlete';
      final createdAtString = user.createdAt;
      if (createdAtString.isNotEmpty ?? false) {
        try {
          _accountCreated = DateTime.parse(createdAtString);
        } catch (e) {
          debugPrint('Error Parsing Date: $e');
          _accountCreated = null;
        }
      }

      final profileData = await supabase.from('profiles').select('units, weekly_goal').eq('id', user.id).single();

      if (mounted) {
        setState(() {
          _units = profileData['units'] ?? 'lbs';
          _weeklyGoalCtrl.text = (profileData['weekly_goal'] ?? 3).toString();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error Loading Settings: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _units = 'lbs';
          _weeklyGoalCtrl.text = '3';
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
      _successMessage = null;
      _errorMessage = null;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Not Authenticated.');
      }

      final weeklyGoal = int.tryParse(_weeklyGoalCtrl.text) ?? 3;
      if (weeklyGoal < 1 || weeklyGoal > 7) {
        throw Exception('Weekly Goal must be Between 1 and 7 Days.');
      }

      await supabase.from('profiles').update({'units': _units, 'weekly_goal': weeklyGoal}).eq('id', user.id);

      if (mounted) {
        setState(() {
          _successMessage = 'Settings Saved Successfully!';
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings Saved!'),
            backgroundColor: Colors.green,
          )
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      children: [
                        // Account Info Card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundColor: const Color(0xFF7C3AED),
                                      child: Text(
                                        (_username ?? 'A')[0].toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _username ?? 'Athlete',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _userEmail ?? '',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                          if (_accountCreated != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'Member since ${_accountCreated!.year}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Settings Card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Settings',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Customize your NeuroFit experience.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Weight Units
                                DropdownButtonFormField<String>(
                                  initialValue: _units,
                                  decoration: const InputDecoration(
                                    labelText: 'Weight Units',
                                    prefixIcon: Icon(Icons.fitness_center),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'lbs',
                                      child: Text('Pounds (lbs)'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'kg',
                                      child: Text('Kilograms (kg)'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _units = value;
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Weekly Goal
                                TextFormField(
                                  controller: _weeklyGoalCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Weekly Workout Goal',
                                    helperText: 'How many days per week do you want to work out?',
                                    prefixIcon: Icon(Icons.calendar_today),
                                    suffixText: 'days',
                                  ),
                                  validator: (value) {
                                    final num = int.tryParse(value ?? '');
                                    if (num == null || num < 1 || num > 7) {
                                      return 'Must be between 1 and 7';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),

                                // Save Button
                                FilledButton.icon(
                                  onPressed: _isSaving ? null : _saveSettings,
                                  icon: _isSaving
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : const Icon(Icons.save),
                                  label: const Text('Save Settings'),
                                ),

                                // Messages
                                if (_successMessage != null) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.1),
                                      border: Border.all(color: Colors.green),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_circle,
                                            color: Colors.green),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _successMessage!,
                                            style: const TextStyle(
                                                color: Colors.green),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (_errorMessage != null) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.1),
                                      border: Border.all(color: Colors.red),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.error, color: Colors.red),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _errorMessage!,
                                            style: const TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
