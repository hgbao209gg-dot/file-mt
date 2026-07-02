import 'package:flutter/material.dart';
import '../services/file_service.dart';
import '../widgets/file_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _leftKey = GlobalKey<FilePanelState>();
  final _rightKey = GlobalKey<FilePanelState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final divider = VerticalDivider(
      width: 1,
      thickness: 1,
      color: theme.colorScheme.outlineVariant,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('File Manager'),
        centerTitle: true,
      ),
      body: Row(
        children: [
          Expanded(
            child: FilePanel(
              key: _leftKey,
              onFileTap: (f) {},
            ),
          ),
          divider,
          Expanded(
            child: FilePanel(
              key: _rightKey,
              onFileTap: (f) {},
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: _showActionSheet,
        tooltip: 'Actions',
        child: const Icon(Icons.more_horiz),
      ),
    );
  }

  void _showActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy (left → right)'),
              onTap: () {
                Navigator.pop(ctx);
                _operate(FileService.copy);
              },
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_move),
              title: const Text('Move (left → right)'),
              onTap: () {
                Navigator.pop(ctx);
                _operate(FileService.move);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete selected'),
              subtitle: const Text('Left panel'),
              onTap: () {
                Navigator.pop(ctx);
                _delete();
              },
            ),
            ListTile(
              leading: const Icon(Icons.create_new_folder),
              title: const Text('New folder (left)'),
              onTap: () {
                Navigator.pop(ctx);
                _newFolder();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _operate(Future<Map<String, dynamic>> Function(String src, String dst) op) async {
    final leftFile = _leftKey.currentState?.selected;
    final rightPath = _rightKey.currentState?.currentPath;
    if (leftFile == null || rightPath == null) {
      _snack('Select a file in left panel first');
      return;
    }
    final dst = '$rightPath/${leftFile.name}';
    final result = await op(leftFile.path, dst);
    _snack(result['message'] as String? ?? 'Done');
    _leftKey.currentState?.refresh();
    _rightKey.currentState?.refresh();
  }

  Future<void> _delete() async {
    final f = _leftKey.currentState?.selected;
    if (f == null) { _snack('Select a file first'); return; }
    final result = await FileService.delete(f.path);
    _snack(result['message'] as String? ?? 'Deleted');
    _leftKey.currentState?.refresh();
  }

  Future<void> _newFolder() async {
    final path = _leftKey.currentState?.currentPath;
    if (path == null) return;
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Folder name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, nameController.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await FileService.mkdir('$path/$name');
      _leftKey.currentState?.refresh();
    }
  }

  void _snack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }
}