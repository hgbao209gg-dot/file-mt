import 'package:flutter/material.dart';
import '../widgets/file_panel.dart';
import '../models/file_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _leftPath = '/storage/emulated/0';
  String _rightPath = '/storage/emulated/0/Download';
  FileItem? _selectedLeft;
  FileItem? _selectedRight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    final divider = VerticalDivider(
      width: 1,
      thickness: 1,
      color: theme.colorScheme.outlineVariant,
    );

    final panels = [
      Expanded(
        child: FilePanel(
          path: _leftPath,
          onNavigate: (p) => _leftPath = p,
          onFileTap: (f) => _selectedLeft = f,
        ),
      ),
      divider,
      Expanded(
        child: FilePanel(
          path: _rightPath,
          onNavigate: (p) => _rightPath = p,
          onFileTap: (f) => _selectedRight = f,
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('File Manager'),
        centerTitle: true,
        actions: [
          ToggleButtons(
            isSelected: [isLandscape, !isLandscape],
            onPressed: (i) {
              // simple toggle: in real app lock orientation
            },
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            children: const [
              Icon(Icons.swap_horiz, size: 18),
              Icon(Icons.swap_vert, size: 18),
            ],
          ),
        ],
      ),
      body: Row(children: panels),
      floatingActionButton: FloatingActionButton.small(
        onPressed: _showCopyDialog,
        tooltip: 'Copy / Move',
        child: const Icon(Icons.content_copy),
      ),
    );
  }

  void _showCopyDialog() {
    if (_selectedLeft == null || _selectedRight == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a file in each panel first')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: Text(
                  'Copy "${_selectedLeft!.name}" → ${_selectedRight!.path}'),
              onTap: () => _performCopy(false),
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_move),
              title: Text(
                  'Move "${_selectedLeft!.name}" → ${_selectedRight!.path}'),
              onTap: () => _performCopy(true),
            ),
          ],
        ),
      ),
    );
  }

  void _performCopy(bool move) {
    final src = _selectedLeft!;
    final destDir = _selectedRight!.isDir
        ? _selectedRight!.path
        : _selectedRight!.path.substring(
              0, _selectedRight!.path.lastIndexOf('/'));
    final dest = '$destDir/${src.name}';

    try {
      if (src.isDir) {
        _copyDir(Directory(src.path), Directory(dest));
        if (move) Directory(src.path).deleteSync(recursive: true);
      } else {
        File(src.path).copySync(dest);
        if (move) File(src.path).deleteSync();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${move ? "Moved" : "Copied"} to $dest')),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _copyDir(Directory src, Directory dest) {
    dest.createSync(recursive: true);
    for (final e in src.listSync()) {
      final name = e.path.split('/').last;
      final target = '${dest.path}/$name';
      if (e is Directory) _copyDir(e, Directory(target));
      if (e is File) e.copySync(target);
    }
  }
}