import 'package:flutter/material.dart';
import '../models/clothing_item.dart';
import '../services/closet_service.dart';

const List<String> _kTagTypes = <String>[
  'General',
  'Color',
  'Season',
  'Occasion',
  'Brand',
  'Material',
  'Fit',
];

class _TagEntry {
  String type;
  String label;
  _TagEntry({required this.type, required this.label});
}

List<_TagEntry> _parseTagEntries(List<String> raw) {
  return raw.map((t) {
    final parts = t.split('|');
    if (parts.length >= 2) {
      final type = parts.first.trim().isEmpty ? 'General' : parts.first.trim();
      final label = parts.sublist(1).join('|').trim();
      return _TagEntry(type: type, label: label);
    }
    return _TagEntry(type: 'General', label: t.trim());
  }).toList();
}

List<String> _serializeTagEntries(List<_TagEntry> entries) {
  return entries
      .where((e) => e.label.trim().isNotEmpty)
      .map((e) => '${e.type.trim()}|${e.label.trim()}')
      .toList();
}

Future<void> _showEditTagsSheet({
  required BuildContext context,
  required ClothingItem item,
  required ClosetService closetService,
  void Function(List<String> updatedTags)? onTagsUpdated,
}) async {
  final TextEditingController _labelCtl = TextEditingController();
  String _newType = _kTagTypes.first;
  List<_TagEntry> entries = _parseTagEntries(item.tags ?? const []);

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          Future<void> save() async {
            final updated = _serializeTagEntries(entries);
            try {
              await closetService.updateItemTags(item.id, updated);
              // notify caller to update its UI if needed
              if (onTagsUpdated != null) onTagsUpdated(updated);

              if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tags updated successfully')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to update tags: $e')),
              );
            }
          }

          void addNew() {
            final label = _labelCtl.text.trim();
            if (label.isEmpty) return;
            setLocal(() {
              entries.add(_TagEntry(type: _newType, label: label));
              _labelCtl.clear();
              _newType = _kTagTypes.first;
            });
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Edit Tags',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.check),
                      tooltip: 'Save',
                      onPressed: save,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (int i = 0; i < entries.length; i++)
                      InputChip(
                        label: Text('${entries[i].type}: ${entries[i].label}'),
                        onPressed: () async {
                          final tmpLabelCtl = TextEditingController(
                            text: entries[i].label,
                          );
                          String tmpType = entries[i].type;
                          await showDialog(
                            context: ctx,
                            builder: (_) => AlertDialog(
                              title: const Text('Edit tag'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  DropdownButtonFormField<String>(
                                    value: _kTagTypes.contains(tmpType)
                                        ? tmpType
                                        : _kTagTypes.first,
                                    decoration: const InputDecoration(
                                      labelText: 'Type',
                                    ),
                                    items: _kTagTypes
                                        .map(
                                          (t) => DropdownMenuItem(
                                            value: t,
                                            child: Text(t),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) {
                                      if (v != null) tmpType = v;
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: tmpLabelCtl,
                                    decoration: const InputDecoration(
                                      labelText: 'Label',
                                      hintText: 'e.g., Blue, Summer, Nike',
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    setLocal(() {
                                      entries[i] = _TagEntry(
                                        type: tmpType,
                                        label: tmpLabelCtl.text.trim(),
                                      );
                                    });
                                    Navigator.pop(ctx);
                                  },
                                  child: const Text('Save'),
                                ),
                              ],
                            ),
                          );
                        },
                        onDeleted: () {
                          setLocal(() {
                            entries.removeAt(i);
                          });
                        },
                      ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: TextField(
                        controller: _labelCtl,
                        decoration: const InputDecoration(
                          labelText: 'New tag label',
                          hintText: 'e.g., Blue',
                        ),
                        onSubmitted: (_) => addNew(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 5,
                      child: DropdownButtonFormField<String>(
                        value: _newType,
                        decoration: const InputDecoration(labelText: 'Type'),
                        items: _kTagTypes
                            .map(
                              (t) => DropdownMenuItem(value: t, child: Text(t)),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setLocal(() => _newType = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: addNew,
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
