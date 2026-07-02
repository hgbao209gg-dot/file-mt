import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppTestApp());
}

class AppTestApp extends StatelessWidget {
  const AppTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AppTest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: const PermissionGate(child: HomeScreen()),
    );
  }
}

class PermissionGate extends StatefulWidget {
  final Widget child;
  const PermissionGate({super.key, required this.child});

  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate> {
  bool _granted = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _request();
  }

  Future<void> _request() async {
    final status = await Permission.storage.status;
    if (status.isGranted) {
      if (mounted) { setState(() => _granted = true); }
      return;
    }

    if (await Permission.manageExternalStorage.isGranted) {
      if (mounted) { setState(() => _granted = true); }
      return;
    }

    // Try storage first (API < 30), then manageExternalStorage (API 30+)
    var result = await Permission.storage.request();
    if (result.isGranted) {
      if (mounted) { setState(() => _granted = true); }
      return;
    }

    result = await Permission.manageExternalStorage.request();
    if (result.isGranted) {
      if (mounted) { setState(() => _granted = true); }
      return;
    }

    if (result.isPermanentlyDenied) {
      if (mounted) {
        setState(() => _error = 'Storage access permanently denied. '
            'Please enable "All files access" in Settings > Apps > AppTest.');
      }
    } else {
      if (mounted) { setState(() => _error = 'Storage permission is required.'); }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_granted) { return widget.child; }
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.folder_open, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('File Manager needs storage access\n'
                  'to browse and manage your files.',
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(_error!, style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center),
                ),
              FilledButton.icon(
                icon: const Icon(Icons.done),
                label: const Text('Grant Access'),
                onPressed: () {
                  setState(() { _error = null; _granted = false; });
                  _request();
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: openAppSettings,
                  child: const Text('Open Settings'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}