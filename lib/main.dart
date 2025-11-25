import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'generate_plan_logic.dart';

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
    'Social Feed',
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
      case 7:
        body = const SocialFeedScreen();
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
        NavigationRailDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: Text('Social Feed'),
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
  final String imagePath;
  final String videoURL;

  Exercise(this.name, this.imagePath, this.videoURL);
}

class _BodyDiagramScreenState extends State<BodyDiagramScreen> {
  bool _showingFront = true;
  String? _selectedMuscle;
  String? _hoveredMuscle;

  final Map<String, List<Exercise>> _exercises = {
  'chest': [
    Exercise('Bench Press', 'images/chest/Bench_Press.jpg', 'https://www.youtube.com/watch?hWbUlkb5Ms4'),
    Exercise('Close-Grip Bench Press', 'images/chest/Close_Grip_Bench_Press.jpg', 'https://www.youtube.com/watch?4yKLxOsrGfg'),
    Exercise('Wide-Grip Bench Press', 'images/chest/Wide_Grip_Bench_Press.jpg', 'https://www.youtube.com/watch?NQNWLYJTtHA'),
    Exercise('Incline Bench Press', 'images/chest/Incline_Bench_Press.jpg', 'https://www.youtube.com/watch?8fXfwG4ftaQ'),
    Exercise('Decline Barbell Press', 'images/chest/Decline_Barbell_Press.jpg', 'https://www.youtube.com/watch?a-UFQE4oxWY'),
    Exercise('Incline Dumbbell Bench Press', 'images/chest/Incline_Dumbbell_Bench_Press.jpg', 'https://www.youtube.com/watch?Gruq177Psnk'),
    Exercise('Decline Dumbbell Bench Press', 'images/chest/Decline_Dumbbell_Bench_Press.jpg', 'https://www.youtube.com/watch?5JiZFjxyoJQ'),
    Exercise('Dumbbell Chest Press', 'assets/images/chest/Dumbbell_Chest_Press.jpg', 'https://www.youtube.com/watch?WbCEvFA0NJs'),
    Exercise('Dumbbell Chest Flyes', 'assets/images/chest/Dumbbell_Chest_Flyes.jpg', 'https://www.youtube.com/watch?rk8YayRoTRQ'),
    Exercise('Machine Fly', 'assets/images/chest/Machine_Fly.jpg', 'https://www.youtube.com/watch?xYExAgLt_4I'),
    Exercise('Machine Chest Press', 'assets/images/chest/Machine_Chest_Press.jpg', 'https://www.youtube.com/watch?Qu7-ceCvq7w'),
    Exercise('Dumbbell Pullover', 'assets/images/chest/Dumbbell_Pullover.jpg', 'https://www.youtube.com/watch?Datv2L6t3-4'),
    Exercise('Cable Flyes', 'assets/images/chest/Cable_Flyes.jpg', 'https://www.youtube.com/watch?y4RJDSOBEl8'),
    Exercise('Incline Cable Flyes', 'assets/images/chest/Incline_Cable_Flyes.jpg', 'https://www.youtube.com/watch?-Eq_GScOGOE'),
    Exercise('Cable Crossover', 'assets/images/chest/Cable_Crossover.jpg', 'https://www.youtube.com/watch?WIErn7-YvYQ'),
  ],
  
  'biceps': [
    Exercise('Standing Dumbbell Curls', 'assets/images/biceps/Standing Dumbbell Curls.jpg', 'https://www.youtube.com/watch?oLyP6sORFOc'),
    Exercise('Alternating Dumbbell Curls', 'assets/images/biceps/Alternating Dumbbell Curls.jpg', 'https://www.youtube.com/watch?FHY_2t7R714'),
    Exercise('Hammer Curls', 'assets/images/biceps/Hammer Curls.jpg', 'https://www.youtube.com/watch?vm0zV_WQerE'),
    Exercise('Concentration Curls', 'assets/images/biceps/Concentration Curls.jpg', 'https://www.youtube.com/watch?EjUnEEfTSEY'),
    Exercise('Incline Dumbbell Curls', 'assets/images/biceps/Incline Dumbbell Curls.jpg', 'https://www.youtube.com/watch?fXFN8_1Bh6k'),
    Exercise('Zottman Curls', 'assets/images/biceps/Zottman Curls.jpg', 'https://www.youtube.com/watch?5Go_uOTnFl0'),
    Exercise('Cross-Body Hammer Curls', 'assets/images/biceps/Cross-Body Hammer Curls.jpg', 'https://www.youtube.com/watch?qmQkt1Y-FX8'),
    Exercise('Seated Alternating Dumbbell Curls', 'assets/images/biceps/Seated Alternating Dumbbell Curls.jpg', 'https://www.youtube.com/watch?16v_0ET03Oo'),
    Exercise('Barbell Curls', 'assets/images/biceps/Barbell Curls.jpg', 'https://www.youtube.com/watch?54x2WF1_Suc'),
    Exercise('EZ Bar Curls', 'assets/images/biceps/EZ Bar Curls.jpg', 'https://www.youtube.com/watch?KFinlAT6aEo'),
    Exercise('Reverse Curls', 'assets/images/biceps/Reverse Curls.jpg', 'https://www.youtube.com/watch?ZG2n5IcYIcY'),
    Exercise('Wide-Grip Barbell Curls', 'assets/images/biceps/Wide-Grip Barbell Curls.jpg', 'https://www.youtube.com/watch?pgeSaAKOXRs'),
    Exercise('Close-Grip Barbell Curls', 'assets/images/biceps/Close-Grip Barbell Curls.jpg', 'https://www.youtube.com/watch?a6ZJAmhCfjU'),
    Exercise('Cable Bicep Curls', 'assets/images/biceps/Cable Bicep Curls.jpg', 'https://www.youtube.com/watch?CrbTqNOlFgE'),
    Exercise('Overhead Cable Curls', 'assets/images/biceps/Overhead Cable Curls.jpg', 'https://www.youtube.com/watch?grFE5bhFmiQ'),
  ],
  
  'abs': [
    Exercise('Weighted Crunches', 'assets/images/abs/Weighted Crunches.jpg', 'https://www.youtube.com/watch?Yg6GsyZoqK0'),
    Exercise('Russian Twists', 'assets/images/abs/Russian Twists.jpg', 'https://www.youtube.com/watch?aRUMRbl7KS4'),
    Exercise('Dumbbell Side Bend', 'assets/images/abs/Dumbbell Side Bend.jpg', 'https://www.youtube.com/watch?kqr_IjiUuyY'),
    Exercise('Weighted Sit-Ups', 'assets/images/abs/Weighted Sit-Ups.jpg', 'https://www.youtube.com/watch?MXOK5F6SKXQ'),
    Exercise('Crunches', 'assets/images/abs/Crunches.jpg', 'https://www.youtube.com/watch?eeJ_CYqSoT4'),
    Exercise('Reverse Crunches', 'assets/images/abs/Reverse Crunches.jpg', 'https://www.youtube.com/watch?JkTk8irSNKE'),
    Exercise('Bicycle Crunches', 'assets/images/abs/Bicycle Crunches.jpg', 'https://www.youtube.com/watch?CakPX7X-mSw'),
    Exercise('Leg Raises', 'assets/images/abs/Leg Raises.jpg', 'https://www.youtube.com/watch?FijNSgahpz0'),
    Exercise('Flutter Kicks', 'assets/images/abs/Flutter Kicks.jpg', 'https://www.youtube.com/watch?tPmybsDX8ZY'),
    Exercise('Toe Touches', 'assets/images/abs/Toe Touches.jpg', 'https://www.youtube.com/watch?20P7MU4Oaec'),
    Exercise('Mountain Climbers', 'assets/images/abs/Mountain Climbers.jpg', 'https://www.youtube.com/watch?dqjZ6BGhY9s'),
    Exercise('V-Ups', 'assets/images/abs/V-Ups.jpg', 'https://www.youtube.com/watch?Wks3wpNJqTg'),
    Exercise('Plank', 'assets/images/abs/Plank.jpg', 'https://www.youtube.com/watch?xe2MXatLTUw'),
    Exercise('Side Plank', 'assets/images/abs/Side Plank.jpg', 'https://www.youtube.com/watch?BFOyHDlY2UE'),
    Exercise('Plank with Shoulder Tap', 'assets/images/abs/Plank with Shoulder Tap.jpg', 'https://www.youtube.com/watch?gccQ1hMX46U'),
  ],

  'quads': [
    Exercise('Barbell Back Squat', 'assets/images/quads/Barbell Back Squat.jpg', 'https://www.youtube.com/watch?S9iWwaqbD3Q'),
    Exercise('Front Squat', 'assets/images/quads/Front Squat.jpg', 'https://www.youtube.com/watch?_qv0m3tPd3s'),
    Exercise('Hack Squat', 'assets/images/quads/Hack Squat.jpg', 'https://www.youtube.com/watch?g9i05umL5vc'),
    Exercise('Zercher Squat', 'assets/images/quads/Zercher Squat.jpg', 'https://www.youtube.com/watch?xtMpMCCzPrU'),
    Exercise('Box Squat', 'assets/images/quads/Box Squat.jpg', 'https://www.youtube.com/watch?Go4tSkrFIL8'),
    Exercise('Dumbbell Goblet Squat', 'assets/images/quads/Dumbbell Goblet Squat.jpg', 'https://www.youtube.com/watch?lRYBbchqxtI'),
    Exercise('Dumbbell Split Squat', 'assets/images/quads/Dumbbell Split Squat.jpg', 'https://www.youtube.com/watch?sw4MzpC8l58'),
    Exercise('Bulgarian Split Squat', 'assets/images/quads/Bulgarian Split Squat.jpg', 'https://www.youtube.com/watch?or1frhkjBDc'),
    Exercise('Dumbbell Step-Ups', 'assets/images/quads/Dumbbell Step-Ups.jpg', 'https://www.youtube.com/watch?8q9LVgN2RD4'),
    Exercise('Dumbbell Front Squat', 'assets/images/quads/Dumbbell Front Squat.jpg', 'https://www.youtube.com/watch?0hw86JiWjCM'),
    Exercise('Leg Press', 'assets/images/quads/Leg Press.jpg', 'https://www.youtube.com/watch?EotSw18oR9w'),
    Exercise('Leg Extensions', 'assets/images/quads/Leg Extensions.jpg', 'https://www.youtube.com/watch?iQ92TuvBqRo'),
    Exercise('Cable Pull Through', 'assets/images/quads/Cable Pull Through.jpg', 'https://www.youtube.com/watch?SuTI-n84ezA'),
    Exercise('Sissy Squat', 'assets/images/quads/Sissy Squat.jpg', 'https://www.youtube.com/watch?f4ubaNbsq0Y'),
    Exercise('Smith Machine Front Squat', 'assets/images/quads/Smith Machine Front Squat.jpg', 'https://www.youtube.com/watch?NO-6L6Blneg'),
  ],

  'traps': [
    Exercise('Barbell Shrugs', 'images/traps/Barbell Shrugs.jpg', 'https://www.youtube.com/watch?TUBuBI1U1wc'),
    Exercise('Behind-the-Back Barbell Shrugs', 'images/traps/Behind-the-Back Barbell Shrugs.jpg', 'https://www.youtube.com/watch?xKS-kFgXNPU'),
    Exercise('Upright Rows', 'images/traps/Upright Rows.jpg', 'https://www.youtube.com/watch?AWsGWt-VMl8'),
    Exercise('Snatch-Grip Deadlift', 'images/traps/Snatch-Grip Deadlift.jpg', 'https://www.youtube.com/watch?E42_MZOKktU'),
    Exercise('Rack Pulls', 'images/traps/Rack Pulls.jpg', 'https://www.youtube.com/watch?qFqbJqboCHU'),
    Exercise('Dumbbell Shrugs', 'images/traps/Dumbbell Shrugs.jpg', 'https://www.youtube.com/watch?rFsSeClGnNA'),
    Exercise('Incline Dumbbell Shrugs', 'images/traps/Incline Dumbbell Shrugs.jpg', 'https://www.youtube.com/watch?xEkIB8PeNv0'),
    Exercise('Farmers Walk', 'images/traps/Farmers Walk.jpg', 'https://www.youtube.com/watch?HDoNIkik8r8'),
    Exercise('Dumbbell Upright Rows', 'images/traps/Dumbbell Upright Rows.jpg', 'https://www.youtube.com/watch?fbc8FrvjFHk'),
    Exercise('Dumbbell High Pulls', 'images/traps/Dumbbell High Pulls.jpg', 'https://www.youtube.com/watch?o0KJD3Xn3fc'),
    Exercise('Cable Shrugs', 'images/traps/Cable Shrugs.jpg', 'https://www.youtube.com/watch?m2ifHLnEIaA'),
    Exercise('Cable Face Pulls', 'images/traps/Cable Face Pulls.jpg', 'https://www.youtube.com/watch?qEyoBOpvqR4'),
    Exercise('Reverse Cable Flyes', 'images/traps/Reverse Cable Flyes.jpg', 'https://www.youtube.com/watch?xswhV6zJaxY'),
    Exercise('Smith Machine Shrugs', 'images/traps/Smith Machine Shrugs.jpg', 'https://www.youtube.com/watch?zdBh_Ul2psI'),
    Exercise('Seated Cable Rows', 'images/traps/Seated Cable Rows.jpg', 'https://www.youtube.com/watch?qD1WZ5pSuvk'),
  ],

  'delts': [
    Exercise('Overhead Barbell Press', 'images/delts/Overhead Barbell Press.jpg', 'https://www.youtube.com/watch?4LBVP2Oe7fg'),
    Exercise('Behind-the-Neck Press', 'images/delts/Behind-the-Neck Press.jpg', 'https://www.youtube.com/watch?2EZLxxKRHYY'),
    Exercise('Upright Rows', 'images/delts/Upright Rows.jpg', 'https://www.youtube.com/watch?um3VVzqunPU'),
    Exercise('Front Barbell Raise', 'images/delts/Front Barbell Raise.jpg', 'https://www.youtube.com/watch?MNho_Zw3mFc'),
    Exercise('Arnold Press', 'images/delts/Arnold Press.jpg', 'https://www.youtube.com/watch?g4GUrEFoBxY'),
    Exercise('Seated Dumbbell Shoulder Press', 'images/delts/Seated Dumbbell Shoulder Press.jpg', 'https://www.youtube.com/watch?k6tzKisR3NY'),
    Exercise('Lateral Dumbbell Raises', 'images/delts/Lateral Dumbbell Raises.jpg', 'https://www.youtube.com/watch?iK22GwXJji0'),
    Exercise('Front Dumbbell Raises', 'images/delts/Front Dumbbell Raises.jpg', 'https://www.youtube.com/watch?h9xfpTrAvkE'),
    Exercise('Rear Delt Flyes', 'images/delts/Rear Delt Flyes.jpg', 'https://www.youtube.com/watch?LsT-bR_zxLo'),
    Exercise('Incline Bench Rear Delt Raises', 'images/delts/Incline Bench Rear Delt Raises.jpg', 'https://www.youtube.com/watch?lRTT2YABNIM'),
    Exercise('Dumbbell High Pulls', 'images/delts/Dumbbell High Pulls.jpg', 'https://www.youtube.com/watch?o0KJD3Xn3fc'),
    Exercise('Single-Arm Dumbbell Press', 'images/delts/Single-Arm Dumbbell Press.jpg', 'https://www.youtube.com/watch?Cs2uNF-jW5s'),
    Exercise('Cable Lateral Raises', 'images/delts/Cable Lateral Raises.jpg', 'https://www.youtube.com/watch?xrBcuPNTxLg'),
    Exercise('Cable Front Raises', 'images/delts/Cable Front Raises.jpg', 'https://www.youtube.com/watch?NdQE5Fhfqn4'),
    Exercise('Reverse Cable Flyes', 'images/delts/Reverse Cable Flyes.jpg', 'https://www.youtube.com/watch?xswhV6zJaxY'),
  ],

  'lats': [
    Exercise('Barbell Bent-Over Rows', 'images/lats/Barbell Bent-Over Rows.jpg', 'https://www.youtube.com/watch?phVtqawIgbk'),
    Exercise('Pendlay Rows', 'images/lats/Pendlay Rows.jpg', 'https://www.youtube.com/watch?EzFkN5ge5_k'),
    Exercise('Underhand Barbell Rows', 'images/lats/Underhand Barbell Rows.jpg', 'https://www.youtube.com/watch?ElNQUyDoxkM'),
    Exercise('T-Bar Rows', 'images/lats/T-Bar Rows.jpg', 'https://www.youtube.com/watch?MIulz5576AY'),
    Exercise('Deadlifts', 'images/lats/Deadlifts.jpg', 'https://www.youtube.com/watch?xNwpvDuZJ3k'),
    Exercise('One-Arm Dumbbell Row', 'images/lats/One-Arm Dumbbell Row.jpg', 'https://www.youtube.com/watch?s1H87k4tAaA'),
    Exercise('Dumbbell Pullover', 'images/lats/Dumbbell Pullover.jpg', 'https://www.youtube.com/watch?iy0VwFjTWds'),
    Exercise('Incline Dumbbell Rows', 'images/lats/Incline Dumbbell Rows.jpg', 'https://www.youtube.com/watch?tZUYS7X50so'),
    Exercise('Kroc Rows', 'images/lats/Kroc Rows.jpg', 'https://www.youtube.com/watch?FY53-vxHU34'),
    Exercise('Chest-Supported Dumbbell Rows', 'images/lats/Chest-Supported Dumbbell Rows.jpg', 'https://www.youtube.com/watch?woHK8Lws2xM'),
    Exercise('Lat Pulldowns', 'images/lats/Lat Pulldowns.jpg', 'https://www.youtube.com/watch?51ql2-2kLfA'),
    Exercise('Close-Grip Lat Pulldowns', 'images/lats/Close-Grip Lat Pulldowns.jpg', 'https://www.youtube.com/watch?E8cpBEoCrOs'),
    Exercise('Straight-Arm Cable Pulldowns', 'images/lats/Straight-Arm Cable Pulldowns.jpg', 'https://www.youtube.com/watch?RK2PRy9VwPg'),
    Exercise('Seated Cable Rows', 'images/lats/Seated Cable Rows.jpg', 'https://www.youtube.com/watch?qD1WZ5pSuvk'),
    Exercise('Single-Arm Cable Rows', 'images/lats/Single-Arm Cable Rows.jpg', 'https://www.youtube.com/watch?yIvvQc2Z6uM'),
  ],

  'glutes': [
    Exercise('Barbell Hip Thrusts', 'images/glutes/Barbell Hip Thrusts.jpg', 'https://www.youtube.com/watch?pUdIL5x0fWg'),
    Exercise('Barbell Glute Bridges', 'images/glutes/Barbell Glute Bridges.jpg', 'https://www.youtube.com/watch?DrZdxtfEgik'),
    Exercise('Sumo Deadlifts', 'images/glutes/Sumo Deadlifts.jpg', 'https://www.youtube.com/watch?pfSMst14EFk'),
    Exercise('Romanian Deadlifts', 'images/glutes/Romanian Deadlifts.jpg', 'https://www.youtube.com/watch?g5u75sgpn04'),
    Exercise('Good Mornings', 'images/glutes/Good Mornings.jpg', 'https://www.youtube.com/watch?7cpldMZjLOs'),
    Exercise('Dumbbell Step-Ups', 'images/glutes/Dumbbell Step-Ups.jpg', 'https://www.youtube.com/watch?8q9LVgN2RD4'),
    Exercise('Dumbbell Walking Lunges', 'images/glutes/Dumbbell Walking Lunges.jpg', 'https://www.youtube.com/watch?mJilHWIBWO8'),
    Exercise('Goblet Squats', 'images/glutes/Goblet Squats.jpg', 'https://www.youtube.com/watch?lRYBbchqxtI'),
    Exercise('Dumbbell Romanian Deadlifts', 'images/glutes/Dumbbell Romanian Deadlifts.jpg', 'https://www.youtube.com/watch?oQwnGfZFfzw'),
    Exercise('Kettlebell Swings', 'images/glutes/Kettlebell Swings.jpg', 'https://www.youtube.com/watch?n1df4ASFeZU'),
    Exercise('Cable Kickbacks', 'images/glutes/Cable Kickbacks.jpg', 'https://www.youtube.com/watch?SqO-VUEak2M'),
    Exercise('Cable Pull-Throughs', 'images/glutes/Cable Pull-Throughs.jpg', 'https://www.youtube.com/watch?iQ92TuvBqRo'),
    Exercise('Smith Machine Hip Thrusts', 'images/glutes/Smith Machine Hip Thrusts.jpg', 'https://www.youtube.com/watch?i5Vpsf-c6r0'),
    Exercise('Leg Press', 'images/glutes/Leg Press.jpg', 'https://www.youtube.com/watch?EotSw18oR9w'),
    Exercise('Abductor Machine', 'images/glutes/Abductor Machine.jpg', 'https://www.youtube.com/watch?vNixlpsswr8'),
  ],

  'hams': [
    Exercise('Romanian Deadlift', 'images/hams/Romanian Deadlift.jpg', 'https://www.youtube.com/watch?Wou9zVQrAfs'),
    Exercise('Lying Leg Curl', 'images/hams/Lying Leg Curl.jpg', 'https://www.youtube.com/watch?y7SKfM6Hmiw'),
    Exercise('Seated Leg Curl', 'images/hams/Seated Leg Curl.jpg', 'https://www.youtube.com/watch?_lgE0gPvbik'),
    Exercise('Good Mornings', 'images/hams/Good Mornings.jpg', 'https://www.youtube.com/watch?vBf70Aq2i7I'),
    Exercise('Deadlift', 'images/hams/Deadlift.jpg', 'https://www.youtube.com/watch?xNwpvDuZJ3k'),
    Exercise('Single-Leg Romanian Deadlift', 'images/hams/Single-Leg Romanian Deadlift.jpg', 'https://www.youtube.com/watch?s32cCgmRV3I'),
    Exercise('Nordic Hamstring Curl', 'images/hams/Nordic Hamstring Curl.jpg', 'https://www.youtube.com/watch?hcwtmVuLCV4'),
    Exercise('Glute-Ham Raise', 'images/hams/Glute-Ham Raise.jpg', 'https://www.youtube.com/watch?blX1If7ScxY'),
    Exercise('Cable Pull-Through', 'images/hams/Cable Pull-Through.jpg', 'https://www.youtube.com/watch?C_8Dfrq93II'),
    Exercise('Kettlebell Swing', 'images/hams/Kettlebell Swing.jpg', 'https://www.youtube.com/watch?n1df4ASFeZU'),
    Exercise('Reverse Hyperextension', 'images/hams/Reverse Hyperextension.jpg', 'https://www.youtube.com/watch?MaQmKCpxAjk'),
    Exercise('Swiss Ball Leg Curl', 'images/hams/Swiss Ball Leg Curl.jpg', 'https://www.youtube.com/watch?-53wPef9rWI'),
    Exercise('Standing Leg Curl Machine', 'images/hams/Standing Leg Curl.jpg', 'https://www.youtube.com/watch?I9hgElVIzfg'),
    Exercise('Banded Hamstring Curl', 'images/hams/Banded Hamstring Curl.jpg', 'https://www.youtube.com/watch?89o2fRj5G80'),
    Exercise('Stiff-Leg Deadlift', 'images/hams/Stiff-Leg Deadlift.jpg', 'https://www.youtube.com/watch?BM4Q5Potr5A'),
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
                    child: _showingFront ? _buildFrontView() : _buildBackView(),
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

  Widget _buildFrontView() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: MouseRegion(
        onHover: (event) {
          final RenderBox box = context.findRenderObject() as RenderBox;
          final localPos = box.globalToLocal(event.position);
          _handleHover(localPos);
        },
        onExit: (_) {
          setState(() {
            _hoveredMuscle = null;
          });
        },
        child: GestureDetector(
          onTapUp: (details) {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final localPos = box.globalToLocal(details.globalPosition);
            _handleDiagramTap(localPos);
          },
          onPanUpdate: (details) {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final localPos = box.globalToLocal(details.globalPosition);
            _handleHover(localPos);
          },
          onPanEnd: (_) {
            setState(() {
              _hoveredMuscle = null;
            });
          },
          child: Stack(
            children: [
              Image.asset(
                'assets/body-diagram-front.png',
                fit: BoxFit.contain,
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: BodyDiagramOverlayPainter(
                    selectedMuscle: _selectedMuscle,
                    hoveredMuscle: _hoveredMuscle,
                  ),
                ),
              ),
            ],
          ),
        ),
      )
    );
  }

  Widget _buildBackView() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: MouseRegion(
        onHover: (event) {
          final RenderBox box = context.findRenderObject() as RenderBox;
          final localPos = box.globalToLocal(event.position);
          _handleHover(localPos);
        },
        onExit: (_) {
          setState(() {
            _hoveredMuscle = null;
          });
        },
        child: GestureDetector(
          onTapUp: (details) {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final localPos = box.globalToLocal(details.globalPosition);
            _handleBackDiagramTap(localPos);
          },
          // Also track touch movements for mobile
          onPanUpdate: (details) {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final localPos = box.globalToLocal(details.globalPosition);
            _handleHover(localPos);
          },
          onPanEnd: (_) {
            setState(() {
              _hoveredMuscle = null;
            });
          },
          child: Stack(
            children: [
              Image.asset(
                'assets/body-diagram-back.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback if back image doesn't exist yet
                  return Container(
                    width: 300,
                    height: 600,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      border: Border.all(color: const Color(0xFF334155), width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.image_not_supported, size: 48, color: Color(0xFF7C3AED)),
                            const SizedBox(height: 16),
                            Text(
                              'Back View Image Not Found',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add "body-diagram-back.png" to your assets folder',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              // Invisible clickable overlay using CustomPaint
              Positioned.fill(
                child: CustomPaint(
                  painter: BodyDiagramBackOverlayPainter(
                    selectedMuscle: _selectedMuscle,
                    hoveredMuscle: _hoveredMuscle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleHover(Offset position) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final size = box.size;
    
    final relativeX = position.dx / size.width;
    final relativeY = position.dy / size.height;

    String? hoveredMuscle = _showingFront ? _detectFrontMuscleFromRelativePosition(relativeX, relativeY) : _detectBackMuscleFromRelativePosition(relativeX, relativeY);

    if (hoveredMuscle != _hoveredMuscle) {
      setState(() {
        _hoveredMuscle = hoveredMuscle;
      });
    }
  }

  void _handleDiagramTap(Offset position) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final size = box.size;
    final relativeX = position.dx / size.width;
    final relativeY = position.dy / size.height;
    
    String? tappedMuscle = _detectFrontMuscleFromRelativePosition(relativeX, relativeY);

    if (tappedMuscle != null) {
      _handleMuscleTap(tappedMuscle);
    }
  }

  void _handleBackDiagramTap(Offset position) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final size = box.size;
    final relativeX = position.dx / size.width;
    final relativeY = position.dy / size.height;
    
    String? tappedMuscle = _detectBackMuscleFromRelativePosition(relativeX, relativeY);

    if (tappedMuscle != null) {
      _handleMuscleTap(tappedMuscle);
    }
  }

  String? _detectFrontMuscleFromRelativePosition(double relX, double relY) {
    final x = relX * 650;
    final y = relY * 1280;

    // Chest region (polygon approximation)
    if (x >= 220 && x <= 430 && y >= 230 && y <= 360) {
      return 'chest';
    }
    // Left Bicep (ellipse approximation)
    else if (_isInEllipse(x, y, 150, 330, 45, 80)) {
      return 'biceps';
    }
    // Right Bicep
    else if (_isInEllipse(x, y, 500, 330, 45, 80)) {
      return 'biceps';
    }
    // Abs region (rectangle)
    else if (x >= 250 && x <= 400 && y >= 380 && y <= 580) {
      return 'abs';
    }
    // Left Quad (polygon approximation)
    else if (x >= 240 && x <= 320 && y >= 620 && y <= 1050) {
      return 'quads';
    }
    // Right Quad
    else if (x >= 340 && x <= 410 && y >= 620 && y <= 1050) {
      return 'quads';
    }
    
    return null;
  }

  bool _isInEllipse(double x, double y, double cx, double cy, double rx, double ry) {
    final dx = x - cx;
    final dy = y - cy;

    return (dx * dx) / (rx * rx) + (dy * dy) / (ry * ry) <= 1;
  }

  String? _detectBackMuscleFromRelativePosition(double relX, double relY) {
    final x = relX * 650;
    final y = relY * 1280;

    // Traps region (upper back/neck area)
    if (x >= 220 && x <= 430 && y >= 180 && y <= 280) {
      return 'traps';
    }
    // Left Shoulder (rear delt)
    else if (_isInEllipse(x, y, 150, 250, 50, 70)) {
      return 'delts';
    }
    // Right Shoulder (rear delt)
    else if (_isInEllipse(x, y, 500, 250, 50, 70)) {
      return 'delts';
    }
    // Lats region (mid back, wing area)
    else if (x >= 200 && x <= 450 && y >= 290 && y <= 480) {
      return 'lats';
    }
    // Glutes region (lower back/glutes)
    else if (x >= 240 && x <= 410 && y >= 490 && y <= 620) {
      return 'glutes';
    }
    // Left Hamstring
    else if (x >= 240 && x <= 320 && y >= 630 && y <= 1050) {
      return 'hamstrings';
    }
    // Right Hamstring
    else if (x >= 340 && x <= 410 && y >= 630 && y <= 1050) {
      return 'hamstrings';
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

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final exercise = exercises[index];
                return _buildExerciseCard(exercise);
              },
            ),
            //...exercises.map(
             // (exercise) => Card(
              //  margin: const EdgeInsets.only(bottom: 8),
               // child: ListTile(
                //  leading: const Icon(Icons.play_circle_outline, color: Color(0xFF7C3AED)),
                //  title: Text(exercise.name),
                 // trailing: const Icon(Icons.chevron_right),
                 // onTap: () async {
                   // final uri = Uri.parse(exercise.videoURL);
                   // if (await canLaunchUrl(uri)) {
                   //   await launchUrl(uri, mode: LaunchMode.externalApplication);
                   // }
                 // },
                //),
              //), 
            //),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(Exercise exercise) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(exercise.videoURL);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF334155), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Exercise image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.asset(
                  exercise.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback if image doesn't exist
                    return Container(
                      color: const Color(0xFF334155),
                      child: const Center(
                        child: Icon(
                          Icons.fitness_center,
                          size: 48,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // Exercise name
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    exercise.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.play_circle_outline,
                        size: 16,
                        color: Color(0xFF7C3AED),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Watch Video',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BodyDiagramOverlayPainter extends CustomPainter {
  final String? selectedMuscle;
  final String? hoveredMuscle;

  BodyDiagramOverlayPainter({this.selectedMuscle, this.hoveredMuscle});

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 650;
    final scaleY = size.height / 1280;

    final hoverPaint = Paint()..color = const Color(0xFF7C3AED).withValues(alpha: 0.15)..style = PaintingStyle.fill;
    final hoverBorderPaint = Paint()..color = const Color(0xFF7C3AED).withValues(alpha: 0.4)..style = PaintingStyle.stroke..strokeWidth = 2;
    final selectedPaint = Paint()..color = const Color(0xFF7C3AED).withValues(alpha: 0.3)..style = PaintingStyle.fill;
    final selectedBorderPaint = Paint()..color = const Color(0xFF7C3AED).withValues(alpha: 0.8)..style = PaintingStyle.stroke..strokeWidth = 3;

    if (hoveredMuscle != null && hoveredMuscle != selectedMuscle) {
      _drawMuscleHighlight(canvas, size, scaleX, scaleY, hoveredMuscle!, hoverPaint, hoverBorderPaint);
    }

    if (selectedMuscle != null) {
      _drawMuscleHighlight(canvas, size, scaleX, scaleY, selectedMuscle!, selectedPaint, selectedBorderPaint);
    }
  }

  void _drawMuscleHighlight(Canvas canvas, Size size, double scaleX, double scaleY, String muscle, Paint fill, Paint border) {
    switch (muscle) {
      case 'chest':
        _drawChestHighlight(canvas, size, scaleX, scaleY, fill, border);
        break;
      case 'biceps':
        _drawBicepsHighlight(canvas, size, scaleX, scaleY, fill, border);
        break;
      case 'abs':
        _drawAbsHighlight(canvas, size, scaleX, scaleY, fill, border);
        break;
      case 'quads':
        _drawQuadsHighlight(canvas, size, scaleX, scaleY, fill, border);
        break;
    }
  }

  void _drawChestHighlight(Canvas canvas, Size size, double scaleX, double scaleY, Paint fill, Paint border) {
    final path = Path();

    path.moveTo(220 * scaleX, 230 * scaleY);
    path.lineTo(430 * scaleX, 230 * scaleY);
    path.lineTo(450 * scaleX, 280 * scaleY);
    path.lineTo(450 * scaleX, 360 * scaleY);
    path.lineTo(200 * scaleX, 360 * scaleY);
    path.lineTo(200 * scaleX, 280 * scaleY);
    path.close();

    canvas.drawPath(path, fill);
    canvas.drawPath(path, border);
  }

  void _drawBicepsHighlight(Canvas canvas, Size size, double scaleX, double scaleY, Paint fill, Paint border) {
    // Left bicep
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(150 * scaleX, 330 * scaleY),
        width: 90 * scaleX,
        height: 160 * scaleY,
      ),
      fill,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(150 * scaleX, 330 * scaleY),
        width: 90 * scaleX,
        height: 160 * scaleY,
      ),
      border,
    );
    
    // Right bicep
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(500 * scaleX, 330 * scaleY),
        width: 90 * scaleX,
        height: 160 * scaleY,
      ),
      fill,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(500 * scaleX, 330 * scaleY),
        width: 90 * scaleX,
        height: 160 * scaleY,
      ),
      border,
    );
  }

  void _drawAbsHighlight(Canvas canvas, Size size, double scaleX, double scaleY, Paint fill, Paint border) {
    final rect = Rect.fromLTWH(
      250 * scaleX,
      380 * scaleY,
      150 * scaleX,
      200 * scaleY,
    );

    canvas.drawRect(rect, fill);
    canvas.drawRect(rect, border);
  }

  void _drawQuadsHighlight(Canvas canvas, Size size, double scaleX, double scaleY, Paint fill, Paint border) {
    // Left quad
    final leftPath = Path();
    leftPath.moveTo(240 * scaleX, 620 * scaleY);
    leftPath.lineTo(310 * scaleX, 620 * scaleY);
    leftPath.lineTo(330 * scaleX, 680 * scaleY);
    leftPath.lineTo(340 * scaleX, 800 * scaleY);
    leftPath.lineTo(330 * scaleX, 950 * scaleY);
    leftPath.lineTo(320 * scaleX, 1050 * scaleY);
    leftPath.lineTo(240 * scaleX, 1050 * scaleY);
    leftPath.lineTo(230 * scaleX, 950 * scaleY);
    leftPath.lineTo(220 * scaleX, 800 * scaleY);
    leftPath.close();
    
    canvas.drawPath(leftPath, fill);
    canvas.drawPath(leftPath, border);
    
    // Right quad
    final rightPath = Path();
    rightPath.moveTo(340 * scaleX, 620 * scaleY);
    rightPath.lineTo(410 * scaleX, 620 * scaleY);
    rightPath.lineTo(430 * scaleX, 800 * scaleY);
    rightPath.lineTo(420 * scaleX, 950 * scaleY);
    rightPath.lineTo(410 * scaleX, 1050 * scaleY);
    rightPath.lineTo(330 * scaleX, 1050 * scaleY);
    rightPath.lineTo(320 * scaleX, 950 * scaleY);
    rightPath.lineTo(310 * scaleX, 800 * scaleY);
    rightPath.close();
    
    canvas.drawPath(rightPath, fill);
    canvas.drawPath(rightPath, border);
  }

  @override
  bool shouldRepaint(BodyDiagramOverlayPainter oldDelegate) {
    return oldDelegate.selectedMuscle != selectedMuscle || oldDelegate.hoveredMuscle != hoveredMuscle;
  }
}

class BodyDiagramBackOverlayPainter extends CustomPainter {
  final String? selectedMuscle;
  final String? hoveredMuscle;

  BodyDiagramBackOverlayPainter({this.selectedMuscle, this.hoveredMuscle});

  @override
  void paint(Canvas canvas, Size size) {
    // Scale factor
    final scaleX = size.width / 650;
    final scaleY = size.height / 1280;

    // Paint for hovered muscle (lighter highlight)
    final hoverPaint = Paint()
      ..color = const Color(0xFF7C3AED).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final hoverBorderPaint = Paint()
      ..color = const Color(0xFF7C3AED).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Paint for selected muscle (stronger highlight)
    final selectedPaint = Paint()
      ..color = const Color(0xFF7C3AED).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final selectedBorderPaint = Paint()
      ..color = const Color(0xFF7C3AED).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Draw hovered muscle first (underneath)
    if (hoveredMuscle != null && hoveredMuscle != selectedMuscle) {
      _drawBackMuscleHighlight(canvas, size, scaleX, scaleY, hoveredMuscle!, hoverPaint, hoverBorderPaint);
    }

    // Draw selected muscle on top (stronger highlight)
    if (selectedMuscle != null) {
      _drawBackMuscleHighlight(canvas, size, scaleX, scaleY, selectedMuscle!, selectedPaint, selectedBorderPaint);
    }
  }

  void _drawBackMuscleHighlight(Canvas canvas, Size size, double scaleX, double scaleY, String muscle, Paint fill, Paint border) {
    switch (muscle) {
      case 'traps':
        _drawTrapsHighlight(canvas, size, scaleX, scaleY, fill, border);
        break;
      case 'delts':
        _drawDeltsHighlight(canvas, size, scaleX, scaleY, fill, border);
        break;
      case 'lats':
        _drawLatsHighlight(canvas, size, scaleX, scaleY, fill, border);
        break;
      case 'glutes':
        _drawGlutesHighlight(canvas, size, scaleX, scaleY, fill, border);
        break;
      case 'hamstrings':
        _drawHamstringsHighlight(canvas, size, scaleX, scaleY, fill, border);
        break;
    }
  }

  void _drawTrapsHighlight(Canvas canvas, Size size, double scaleX, double scaleY, Paint fill, Paint border) {
    final rect = Rect.fromLTWH(
      220 * scaleX,
      180 * scaleY,
      210 * scaleX,
      100 * scaleY,
    );
    
    canvas.drawRect(rect, fill);
    canvas.drawRect(rect, border);
  }

  void _drawDeltsHighlight(Canvas canvas, Size size, double scaleX, double scaleY, Paint fill, Paint border) {
    // Left shoulder (rear delt)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(150 * scaleX, 250 * scaleY),
        width: 100 * scaleX,
        height: 140 * scaleY,
      ),
      fill,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(150 * scaleX, 250 * scaleY),
        width: 100 * scaleX,
        height: 140 * scaleY,
      ),
      border,
    );
    
    // Right shoulder (rear delt)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(500 * scaleX, 250 * scaleY),
        width: 100 * scaleX,
        height: 140 * scaleY,
      ),
      fill,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(500 * scaleX, 250 * scaleY),
        width: 100 * scaleX,
        height: 140 * scaleY,
      ),
      border,
    );
  }

  void _drawLatsHighlight(Canvas canvas, Size size, double scaleX, double scaleY, Paint fill, Paint border) {
    final rect = Rect.fromLTWH(
      200 * scaleX,
      290 * scaleY,
      250 * scaleX,
      190 * scaleY,
    );
    
    canvas.drawRect(rect, fill);
    canvas.drawRect(rect, border);
  }

  void _drawGlutesHighlight(Canvas canvas, Size size, double scaleX, double scaleY, Paint fill, Paint border) {
    final rect = Rect.fromLTWH(
      240 * scaleX,
      490 * scaleY,
      170 * scaleX,
      130 * scaleY,
    );
    
    canvas.drawRect(rect, fill);
    canvas.drawRect(rect, border);
  }

  void _drawHamstringsHighlight(Canvas canvas, Size size, double scaleX, double scaleY, Paint fill, Paint border) {
    // Left hamstring
    final leftPath = Path();
    leftPath.moveTo(240 * scaleX, 630 * scaleY);
    leftPath.lineTo(320 * scaleX, 630 * scaleY);
    leftPath.lineTo(320 * scaleX, 1050 * scaleY);
    leftPath.lineTo(240 * scaleX, 1050 * scaleY);
    leftPath.close();
    
    canvas.drawPath(leftPath, fill);
    canvas.drawPath(leftPath, border);
    
    // Right hamstring
    final rightPath = Path();
    rightPath.moveTo(340 * scaleX, 630 * scaleY);
    rightPath.lineTo(410 * scaleX, 630 * scaleY);
    rightPath.lineTo(410 * scaleX, 1050 * scaleY);
    rightPath.lineTo(340 * scaleX, 1050 * scaleY);
    rightPath.close();
    
    canvas.drawPath(rightPath, fill);
    canvas.drawPath(rightPath, border);
  }

  @override
  bool shouldRepaint(BodyDiagramBackOverlayPainter oldDelegate) {
    return oldDelegate.selectedMuscle != selectedMuscle || 
           oldDelegate.hoveredMuscle != hoveredMuscle;
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
class GeneratePlanScreen extends StatefulWidget {
  const GeneratePlanScreen({super.key});

  @override
  State<GeneratePlanScreen> createState() => _GeneratePlanScreenState();
}

class _GeneratePlanScreenState extends State<GeneratePlanScreen> {
  final supabase = Supabase.instance.client;

  String _selectedLevel = 'intermediate';
  int _selectedDays = 4;
  String _selectedGoal = 'recomp';
  Set<String> _selectedEquipment = {};
  List<InjuryInfo> _injuries = [];
  int _rpe = 7;
  String _adherence = 'yes';
  int _weekNumber = 1;
  
  WorkoutPlan? _generatedPlan;
  bool _isLoading = false;

  String? _selectedInjuryType;
  String _selectedInjurySeverity = 'medium';
  bool _isRecovering = false;

  @override
  void initState() {
    super.initState();
    _loadExistingPlan();
  }

  Future<void> _loadExistingPlan() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final weekOf = _getWeekOfISO();
      final response = await supabase
          .from('weekly_plans')
          .select('plan, level, days, goal, equipment')
          .eq('user_id', user.id)
          .eq('week_of', weekOf)
          .maybeSingle();

      if (response != null && response['plan'] != null) {
        setState(() {
          _selectedLevel = response['level'] ?? 'intermediate';
          _selectedDays = response['days'] ?? 4;
          _selectedGoal = response['goal'] ?? 'recomp';
          _selectedEquipment = Set<String>.from(response['equipment'] ?? []);

          // Convert the saved plan back to WorkoutPlan object
          final planData = response['plan'] as List;
          _generatedPlan = WorkoutPlan(
            meta: {
              'level': _selectedLevel,
              'days': _selectedDays,
              'goal': _selectedGoal,
              'week': 1,
              'adherence': 'yes',
              'rpe': 7,
              'equipment': _selectedEquipment.toList(),
            },
            plan: planData.map((day) {
              return WorkoutDay(
                name: day['name'],
                focus: day['focus'],
                main: (day['main'] as List).map((e) => WorkoutExercise(
                  id: e['id'],
                  name: e['name'],
                  sets: e['sets'],
                  reps: List<int>.from(e['reps']),
                  rest: e['rest'],
                  notes: e['notes'],
                )).toList(),
                accessories: (day['accessories'] as List).map((e) => WorkoutExercise(
                  id: e['id'],
                  name: e['name'],
                  sets: e['sets'],
                  reps: List<int>.from(e['reps']),
                  rest: e['rest'],
                  notes: e['notes'],
                )).toList(),
                note: day['note'],
              );
            }).toList(),
          );
        });
      }
    } catch (e) {
      // Silent fail - loading existing plan is optional
      debugPrint('Error loading existing plan: $e');
    }
  }

  String _getWeekOfISO() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: (now.weekday - 1) % 7));
    return '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
  }

  Future<void> _savePlan(WorkoutPlan plan) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final weekOf = _getWeekOfISO();
      final progression = (plan.meta['rpe'] <= 7 && plan.meta['adherence'] == 'yes') ? 1 : (plan.meta['rpe'] >= 9 ? -1 : 0);

      await supabase.from('weekly_plans').upsert({
        'user_id': user.id,
        'week_of': weekOf,
        'level': plan.meta['level'],
        'days': plan.meta['days'],
        'goal': plan.meta['goal'],
        'progression': progression,
        'equipment': plan.meta['equipment'],
        'plan': plan.plan.map((d) => d.toJson()).toList(),
      });
    } catch (e) {
      debugPrint('Error saving plan: $e');
      rethrow;
    }
  }

  void _addInjury() {
    if (_selectedInjuryType != null) {
      setState(() {
        _injuries.add(InjuryInfo(
          type: _selectedInjuryType!,
          severity: _selectedInjurySeverity,
          isRecovering: _isRecovering,
        ));
        _selectedInjuryType = null;
        _isRecovering = false;
      });
    }
  }

  void _removeInjury(int index) {
    setState(() {
      _injuries.removeAt(index);
    });
  }

  Future<void> _generatePlan() async {
    if (_selectedEquipment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one piece of equipment'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Generate plan locally
      final localPlan = generatePlan(
        level: _selectedLevel,
        days: _selectedDays,
        goal: _selectedGoal,
        equipment: _selectedEquipment.toList(),
        injuries: _injuries,
        adherence: _adherence,
        rpe: _rpe,
        week: _weekNumber,
        prioritizeCompounds: _selectedGoal == 'strength' || _selectedGoal == 'athletic',
      );

      setState(() {
        _generatedPlan = localPlan;
      });

      await _savePlan(localPlan);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout Plan Generated! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Workout Plan'),
        backgroundColor: const Color(0xFF0F172A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Create Your Plan',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Week $_weekNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a Personalized Workout Plan Based on your Goals, Equipment, and Injuries',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Fitness Level
            _buildSectionTitle('Fitness Level'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedLevel,
              decoration: _inputDecoration(),
              dropdownColor: const Color(0xFF1E293B),
              items: const [
                DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
                DropdownMenuItem(value: 'intermediate', child: Text('Intermediate')),
                DropdownMenuItem(value: 'advanced', child: Text('Advanced')),
              ],
              onChanged: (value) => setState(() => _selectedLevel = value!),
            ),
            const SizedBox(height: 20),

            // Days, Goal, and Week Number
            _buildSectionTitle('Training Parameters'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Days/Week', style: TextStyle(fontSize: 12, color: Colors.white70)),
                      const SizedBox(height: 4),
                      TextFormField(
                        initialValue: _selectedDays.toString(),
                        decoration: _inputDecoration(),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final days = int.tryParse(value);
                          if (days != null && days >= 2 && days <= 6) {
                            setState(() => _selectedDays = days);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Primary Goal', style: TextStyle(fontSize: 12, color: Colors.white70)),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedGoal,
                        decoration: _inputDecoration(),
                        dropdownColor: const Color(0xFF1E293B),
                        items: const [
                          DropdownMenuItem(value: 'recomp', child: Text('Recomp/General')),
                          DropdownMenuItem(value: 'strength', child: Text('Strength')),
                          DropdownMenuItem(value: 'hypertrophy', child: Text('Hypertrophy')),
                          DropdownMenuItem(value: 'endurance', child: Text('Endurance')),
                          DropdownMenuItem(value: 'athletic', child: Text('Athletic Performance')),
                        ],
                        onChanged: (value) => setState(() => _selectedGoal = value!),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Week #', style: TextStyle(fontSize: 12, color: Colors.white70)),
                      const SizedBox(height: 4),
                      TextFormField(
                        initialValue: _weekNumber.toString(),
                        decoration: _inputDecoration(),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final week = int.tryParse(value);
                          if (week != null && week >= 1) {
                            setState(() => _weekNumber = week);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Equipment
            _buildSectionTitle('Available Equipment'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: EQUIPMENT.map((equip) {
                final isSelected = _selectedEquipment.contains(equip);
                return FilterChip(
                  label: Text(equip),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedEquipment.add(equip);
                      } else {
                        _selectedEquipment.remove(equip);
                      }
                    });
                  },
                  selectedColor: const Color(0xFF7C3AED),
                  backgroundColor: const Color(0xFF1E293B),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Injury Management
            _buildSectionTitle('Injury Management (Optional)'),
            const SizedBox(height: 12),
            Card(
              color: const Color(0xFF1E293B),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedInjuryType,
                            decoration: _inputDecoration().copyWith(
                              hintText: 'Select injury type',
                            ),
                            dropdownColor: const Color(0xFF1E293B),
                            items: const [
                              DropdownMenuItem(value: 'shoulder', child: Text('Shoulder')),
                              DropdownMenuItem(value: 'lower_back', child: Text('Lower Back')),
                              DropdownMenuItem(value: 'knee', child: Text('Knee')),
                              DropdownMenuItem(value: 'elbow', child: Text('Elbow')),
                              DropdownMenuItem(value: 'wrist', child: Text('Wrist')),
                              DropdownMenuItem(value: 'hip', child: Text('Hip')),
                            ],
                            onChanged: (value) => setState(() => _selectedInjuryType = value),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedInjurySeverity,
                            decoration: _inputDecoration(),
                            dropdownColor: const Color(0xFF1E293B),
                            items: const [
                              DropdownMenuItem(value: 'low', child: Text('Low')),
                              DropdownMenuItem(value: 'medium', child: Text('Medium')),
                              DropdownMenuItem(value: 'high', child: Text('High')),
                            ],
                            onChanged: (value) => setState(() => _selectedInjurySeverity = value!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Checkbox(
                          value: _isRecovering,
                          onChanged: (value) => setState(() => _isRecovering = value ?? false),
                          activeColor: const Color(0xFF7C3AED),
                        ),
                        const Text('Currently recovering', style: TextStyle(fontSize: 14)),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: _selectedInjuryType != null ? _addInjury : null,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    if (_injuries.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Divider(color: Color(0xFF334155)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _injuries.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final injury = entry.value;
                          return Chip(
                            label: Text(
                              '${injury.type} (${injury.severity})${injury.isRecovering ? " 🔄" : ""}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () => _removeInjury(idx),
                            backgroundColor: injury.severity == 'high'
                                ? Colors.red.withValues(alpha: 0.2)
                                : injury.severity == 'medium'
                                    ? Colors.orange.withValues(alpha: 0.2)
                                    : Colors.yellow.withValues(alpha: 0.2),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Progress Feedback
            _buildSectionTitle('Progress Feedback'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('RPE Last Week (1-10)', style: TextStyle(fontSize: 14, color: Colors.white70)),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: _rpe.toString(),
                        decoration: _inputDecoration(),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final rpe = int.tryParse(value);
                          if (rpe != null && rpe >= 1 && rpe <= 10) {
                            setState(() => _rpe = rpe);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Completed ≥90% Sets?', style: TextStyle(fontSize: 14, color: Colors.white70)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _adherence,
                        decoration: _inputDecoration(),
                        dropdownColor: const Color(0xFF1E293B),
                        items: const [
                          DropdownMenuItem(value: 'yes', child: Text('Yes')),
                          DropdownMenuItem(value: 'no', child: Text('No')),
                        ],
                        onChanged: (value) => setState(() => _adherence = value!),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: const Text(
                'RPE and Adherence Drive Auto-Progression. Week 4, 8, 12 etc. are deload weeks. Exercise difficulty adjusts based on your fitness level.',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ),
            const SizedBox(height: 24),

            // Generate Button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isLoading ? null : _generatePlan,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Generate Plan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),

            // Display Generated Plan
            if (_generatedPlan != null) ...[
              const Divider(color: Color(0xFF334155)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Your Workout Plan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  if (_generatedPlan!.muscleGroupVolume != null)
                    TextButton.icon(
                      onPressed: () => _showVolumeBreakdown(context),
                      icon: const Icon(Icons.analytics, size: 18),
                      label: const Text('Volume Stats'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              ..._generatedPlan!.plan.map((day) => _buildDayCard(day)),
            ],
          ],
        ),
      ),
    );
  }

  void _showVolumeBreakdown(BuildContext context) {
    if (_generatedPlan?.muscleGroupVolume == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Weekly Volume Breakdown'),
        backgroundColor: const Color(0xFF1E293B),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _generatedPlan!.muscleGroupVolume!.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key.replaceAll('_', ' ').toUpperCase()),
                    Text('${entry.value} sets', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF253246),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
    );
  }

  Widget _buildDayCard(WorkoutDay day) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF334155)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(day.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            ...day.main.map((ex) => _buildExerciseItem(ex, isMain: true)),
            ...day.accessories.map((ex) => _buildExerciseItem(ex, isMain: false)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Text(day.note, style: const TextStyle(fontSize: 12, color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseItem(WorkoutExercise exercise, {required bool isMain}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  exercise.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isMain ? const Color(0xFF7C3AED) : const Color(0xFF94A3B8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isMain ? 'Main' : 'Accessory',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${exercise.sets} × ${fmtRange(exercise.reps)} reps • Rest ${exercise.rest}s',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
          if (exercise.notes != null) ...[
            const SizedBox(height: 4),
            Text(
              exercise.notes!,
              style: const TextStyle(fontSize: 11, color: Colors.orange, fontStyle: FontStyle.italic),
            ),
          ],
        ],
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

//SOCIAL NETWORK
class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class SocialPost {
  final String id;
  final String userId;
  final String authorName;
  final String content;
  final int likes;
  final DateTime createdAt;
  final List<PostComment> comments;

  SocialPost({
    required this.id,
    required this.userId,
    required this.authorName,
    required this.content,
    required this.likes,
    required this.createdAt,
    required this.comments,
  });

  factory SocialPost.fromJson(Map<String, dynamic> json) {
    String username = 'Unknown User';

    if (json['profiles'] != null) {
      if (json['profiles'] is Map) {
        username = json['profiles']['username'] ?? username;
      } else if (json['profiles'] is List && (json['profiles'] as List).isNotEmpty) {
        username = json['profiles'][0]['username'] ?? username;
      }
    }

    if (username == 'Unknown User' && json['username'] != null) {
      username = json['username'];
    }

    return SocialPost(
      id: json['id'].toString(), 
      userId: json['user_id'], 
      authorName: username, 
      content: json['content'] ?? '', 
      likes: json['likes'] ?? 0, 
      createdAt: DateTime.parse(json['created_at']), 
      comments: (json['post_comments'] as List?)?.map((c) => PostComment.fromJson(c)).toList() ?? [],
    );
  }
}

class PostComment {
  final String id;
  final String userId;
  final String authorName;
  final String content;
  final DateTime createdAt;

  PostComment({
    required this.id,
    required this.userId,
    required this.authorName,
    required this.content,
    required this.createdAt,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) {
    String username = 'Unknown User';

    if (json['profiles'] != null) {
      if (json['profiles'] is Map) {
        username = json['profiles']['username'] ?? username;
      } else if (json['profiles'] is List && (json['profiles'] as List).isEmpty) {
        username = json['profiles'][0]['username'] ?? username;
      }
    }

    if (username == 'Unknown User' && json['username'] != null) {
      username = json['username'];
    }

    return PostComment(
      id: json['id'].toString(), 
      userId: json['user_id'], 
      authorName: username, 
      content: json['content'] ?? '', 
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  final TextEditingController _postController = TextEditingController();
  List<SocialPost> _posts = [];
  String _filterType = 'all';
  bool _isLoading = true;
  Map<String, dynamic>? _latestWorkout;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _loadLatestWorkout();
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      var query = supabase.from('social_posts').select('*, profiles!social_posts_user_id_fkey(username), post_comments(*, profiles!post_comments_user_id_fkey(username))');

      if (_filterType == 'mine') {
        query = query.eq('user_id', user.id);
      } else if (_filterType == 'today') {
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);

        query = query.gte('created_at', startOfDay.toIso8601String());
      } else if (_filterType == 'week') {
        final weekAgo = DateTime.now().subtract(const Duration(days: 7));
        query = query.gte('created_at', weekAgo.toIso8601String());
      }

      final response = await query.order('created_at', ascending: false);

      setState(() {
        _posts = (response as List).map((json) => SocialPost.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error Loading Posts: $e')),
        );
      }
    }
  }

  Future<void> _loadLatestWorkout() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase.from('workout_logs').select().eq('user_id', user.id).order('created_at', ascending: false).limit(1).maybeSingle();
      if (response != null) {
        setState(() {
          _latestWorkout = response;
        });
      }
    } catch (e) {
      //Silent fail - latest workout is optional
    }
  }

  Future<void> _createPost(String text) async {
    if (text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please Write Something to Share!')),
      );
      return;
    }

    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase.from('social_posts').insert({
        'user_id': user.id,
        'content': text.trim(),
        'likes': 0,
      });

      _postController.clear();
      _loadPosts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Posted Successfully! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error Creating Post: $e')),
        );
      }
    }
  }

  Future<void> _likePost(String postId, int currentLikes) async {
    try {
      await supabase.from('social_posts').update({'likes': currentLikes + 1}).eq('id', postId);
      _loadPosts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error Liking Post: $e')),
        );
      }
    }
  }

  Future<void> _deletePost(String postId) async {
    try {
      await supabase.from('social_posts').delete().eq('id', postId);
      _loadPosts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post Deleted'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error Deleting Post: $e')),
        );
      }
    }
  }

  Future<void> _addComment(String postId, String commentText) async {
    if (commentText.trim().isEmpty) return;

    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase.from('post_comments').insert({
        'post_id': postId,
        'user_id': user.id,
        'content': commentText.trim(),
      });

      _loadPosts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error Adding Comment: $e')),
        );
      }
    }
  }

  void _useLatestWorkout() {
    if (_latestWorkout != null) {
      final exercise = _latestWorkout!['exercise_name'] ?? '';
      final sets = _latestWorkout!['sets'] ?? 0;
      final reps = _latestWorkout!['reps'] ?? 0;
      final weight = _latestWorkout!['weight'] ?? 0;

      _postController.text = 'Just Crushed $exercise! $sets Sets x $reps Reps @ $weight LBS 💪';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadPosts,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Create Post Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Share Your Progress',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Post your achievements and inspire the community!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Post input
                        TextField(
                          controller: _postController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'What did you accomplish today?',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Quick share latest workout
                        if (_latestWorkout != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                              border: Border.all(
                                color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your latest workout:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_latestWorkout!['exercise_name']} — ${_latestWorkout!['sets']}×${_latestWorkout!['reps']} @ ${_latestWorkout!['weight']} lbs',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: _useLatestWorkout,
                                  icon: const Icon(Icons.fitness_center, size: 16),
                                  label: const Text('Use This Workout'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF7C3AED),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Post button
                        FilledButton.icon(
                          onPressed: () => _createPost(_postController.text),
                          icon: const Icon(Icons.send),
                          label: const Text('Post Update'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Filter Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Community Feed',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        DropdownButton<String>(
                          value: _filterType,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('All Posts')),
                            DropdownMenuItem(value: 'mine', child: Text('My Posts')),
                            DropdownMenuItem(value: 'today', child: Text('Today')),
                            DropdownMenuItem(value: 'week', child: Text('This Week')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _filterType = value);
                              _loadPosts();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Posts Feed
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_posts.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.fitness_center,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No posts yet. Be the first to share! 💪',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ..._posts.map((post) => _buildPostCard(post)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard(SocialPost post) {
    final currentUser = supabase.auth.currentUser;
    final isOwner = currentUser?.id == post.userId;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _timeAgo(post.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOwner)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Post?'),
                          content: const Text('This action cannot be undone.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _deletePost(post.id);
                              },
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Post Content
            Text(
              post.content,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 12),

            // Action Buttons
            const Divider(),
            Row(
              children: [
                // Like Button
                TextButton.icon(
                  onPressed: () => _likePost(post.id, post.likes),
                  icon: const Icon(Icons.thumb_up_outlined, size: 18),
                  label: Text('${post.likes}'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[300],
                  ),
                ),
                const SizedBox(width: 8),

                // Comment Button
                TextButton.icon(
                  onPressed: () => _showCommentsDialog(post),
                  icon: const Icon(Icons.comment_outlined, size: 18),
                  label: Text('${post.comments.length}'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[300],
                  ),
                ),
              ],
            ),

            // Show comments if any
            if (post.comments.isNotEmpty) ...[
              const Divider(),
              ...post.comments.take(2).map((comment) => _buildCommentTile(comment)),
              if (post.comments.length > 2)
                TextButton(
                  onPressed: () => _showCommentsDialog(post),
                  child: Text('View all ${post.comments.length} comments'),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCommentTile(PostComment comment) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      comment.authorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      _timeAgo(comment.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  comment.content,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCommentsDialog(SocialPost post) {
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[800]!),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Comments (${post.comments.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Comments List
              Expanded(
                child: post.comments.isEmpty
                    ? Center(
                        child: Text(
                          'No comments yet. Be the first!',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: post.comments.length,
                        itemBuilder: (context, index) {
                          return _buildCommentTile(post.comments[index]);
                        },
                      ),
              ),

              // Add Comment
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey[800]!),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        decoration: const InputDecoration(
                          hintText: 'Add a comment...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        if (commentController.text.trim().isNotEmpty) {
                          _addComment(post.id, commentController.text);
                          commentController.clear();
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Post'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just Now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m Ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h Ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d Ago';
    } else {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    }
  }
}
