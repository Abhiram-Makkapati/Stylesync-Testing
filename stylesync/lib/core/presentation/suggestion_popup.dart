import 'package:flutter/material.dart';
import '../../features/closet/models/clothing_item.dart';


void showColorSuggestionDialog(
    BuildContext context,
    List<ClothingItem> suggestions,
    ValueChanged<ClothingItem> onSuggestionTapped,
    ) {

  if (suggestions.isEmpty) {
    return;
  }

 showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
        contentPadding: EdgeInsets.zero,
        content: _SuggestionSheetContent(
          suggestions: suggestions,
          onSuggestionTapped: onSuggestionTapped,
        ),
      );
    },
  );
}

class _SuggestionSheetContent extends StatefulWidget {
  const _SuggestionSheetContent({
    required this.suggestions,
    required this.onSuggestionTapped,
  });

  final List<ClothingItem> suggestions;
  final ValueChanged<ClothingItem> onSuggestionTapped;

  @override
  State<_SuggestionSheetContent> createState() =>
      _SuggestionSheetContentState();
}

class _SuggestionSheetContentState extends State<_SuggestionSheetContent> {
 int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final ClothingItem currentItem = widget.suggestions[_currentIndex];

    return ClipRRect(
      borderRadius: BorderRadius.circular(24.0),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Suggestions: ',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_left, size: 30),
                  onPressed: widget.suggestions.length <= 1
                      ? null
                      : () {
                    setState(() {
                      _currentIndex =
                          (_currentIndex - 1 + widget.suggestions.length) %
                              widget.suggestions.length;
                    });
                  },
                ),
                const SizedBox(width: 8),

                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      widget.onSuggestionTapped(currentItem);
                      Navigator.of(context).pop();
                    },
                    child: SizedBox(
                      height: 150,
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: currentItem.imageUrl.isNotEmpty
                            ? Image.network(
                          currentItem.imageUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, progress) =>
                          progress == null
                              ? child
                              : const Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2)),
                          errorBuilder: (context, error, stack) =>
                          const Icon(Icons.error_outline,
                              color: Colors.grey),
                        )
                            : const Icon(Icons.checkroom,
                            color: Colors.grey, size: 40),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                IconButton(
                  icon: const Icon(Icons.arrow_right, size: 30),
                  onPressed: widget.suggestions.length <= 1
                      ? null
                      : () {
                    setState(() {
                      _currentIndex =
                          (_currentIndex + 1) % widget.suggestions.length;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              currentItem.name ?? 'Unnamed Item',
              style:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            if (widget.suggestions.length > 1)
              Text(
                '${_currentIndex + 1} of ${widget.suggestions.length}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}



