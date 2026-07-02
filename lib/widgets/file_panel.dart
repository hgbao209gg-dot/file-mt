import 'package:flutter/material.dart';
import '../models/file_item.dart';
import '../services/file_service.dart';
import 'file_icon.dart';

class FilePanel extends StatefulWidget {
  final ValueChanged<String>? onNavigate;
  final ValueChanged<FileItem>? onFileTap;
  final int? selectedIndex;
  final String Function()? getOtherPath;
  final VoidCallback? onRefreshNeeded;

  const FilePanel({
    super.key,
    this.onNavigate,
    this.onFileTap,
    this.selectedIndex,
    this.getOtherPath,
    this.onRefreshNeeded,
  });

  @override
  State<FilePanel> createState() => FilePanelState();
}

class FilePanelState extends State<FilePanel> {
  late String _currentPath;
  List<FileItem> _items = [];
  bool _loading = false;
  FileItem? _selected;

  String get currentPath => _currentPath;

  @override
  void initState() {
    super.initState();
    _currentPath = '/storage/emulated/0';
    _load();
  }

  void navigateTo(String path) {
    setState(() => _currentPath = path);
    _load();
    widget.onNavigate?.call(path);
  }

  String? _error;

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _error = null;
      final list = await FileService.listDir(_currentPath);
      _items = list.map((m) => FileItem.fromMap(m)).toList();
    } catch (e) {
      _items = [];
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> refresh() => _load();

  void goUp() {
    final parts = _currentPath.split('/')..removeLast();
    if (parts.isEmpty) return;
    navigateTo(parts.join('/'));
  }

  FileItem? get selected => _selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_upward, size: 18),
                onPressed: _currentPath == '/' ? null : goUp,
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                onPressed: _load,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _currentPath,
                  style: theme.textTheme.labelSmall?.copyWith(fontFamily: 'monospace'),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
                  ? Center(
                      child: Text(
                        _error ?? 'Empty',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _error != null ? theme.colorScheme.error : null,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, i) {
                        final item = _items[i];
                        final selected = item.path == _selected?.path;
                        return ListTile(
                          dense: true,
                          selected: selected,
                          selectedTileColor: theme.colorScheme.primaryContainer,
                          leading: fileIcon(item),
                          title: Text(
                            item.name,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                              fontWeight: item.isDir ? FontWeight.w600 : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: item.isDir
                              ? null
                              : Text(
                                  '${item.sizeFormatted}  ${item.modified}',
                                  style: theme.textTheme.labelSmall,
                                ),
                          onTap: () {
                            setState(() => _selected = item);
                            if (item.isDir) {
                              navigateTo(item.path);
                            } else {
                              widget.onFileTap?.call(item);
                            }
                          },
                        );
                      },
                    ),
        ),
      ],
    );
  }
}