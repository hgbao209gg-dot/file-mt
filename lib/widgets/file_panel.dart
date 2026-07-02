import 'dart:io';
import 'package:flutter/material.dart';
import '../models/file_item.dart';
import 'file_icon.dart';

class FilePanel extends StatefulWidget {
  final String path;
  final ValueChanged<String>? onNavigate;
  final ValueChanged<FileItem>? onFileTap;
  final int? selectedIndex;

  const FilePanel({
    super.key,
    required this.path,
    this.onNavigate,
    this.onFileTap,
    this.selectedIndex,
  });
  @override
  State<FilePanel> createState() => _FilePanelState();
}

class _FilePanelState extends State<FilePanel> {
  late List<FileItem> _items;
  String _currentPath = '';

  @override
  void initState() {
    super.initState();
    _currentPath = widget.path;
    _items = FileItem.fromDirectory(_currentPath);
  }

  @override
  void didUpdateWidget(FilePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _currentPath = widget.path;
      _items = FileItem.fromDirectory(_currentPath);
    }
  }

  void _refresh() => setState(() => _items = FileItem.fromDirectory(_currentPath));

  void _goUp() {
    final parent = Directory(_currentPath).parent.path;
    // prevent going above root
    if (parent == _currentPath) return;
    setState(() {
      _currentPath = parent;
      _items = FileItem.fromDirectory(_currentPath);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        // path bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_upward, size: 18),
                tooltip: 'Go up',
                onPressed: _goUp,
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                tooltip: 'Refresh',
                onPressed: _refresh,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _currentPath,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // files
        Expanded(
          child: _items.isEmpty
              ? Center(child: Text('Empty', style: theme.textTheme.bodyMedium))
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, i) {
                    final item = _items[i];
                    final selected = i == widget.selectedIndex;
                    return ListTile(
                      dense: true,
                      selected: selected,
                      selectedTileColor: theme.colorScheme.primaryContainer,
                      leading: fileIcon(item),
                      title: Text(
                        item.name,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          fontWeight:
                              item.isDir ? FontWeight.w600 : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: item.isDir
                          ? null
                          : Text(
                              '${item.sizeFormatted}  ${item.dateFormatted}',
                              style: theme.textTheme.labelSmall,
                            ),
                      onTap: () {
                        if (item.isDir) {
                          setState(() {
                            _currentPath = item.path;
                            _items = FileItem.fromDirectory(_currentPath);
                          });
                          widget.onNavigate?.call(item.path);
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