import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    String content = file.readAsStringSync();
    bool changed = false;

    // We do simple string replacements for common hardcoded colors
    final replacements = {
      'Colors.white': 'Theme.of(context).colorScheme.surface',
      'const Color(0xFFC2F1DF)':
          'Theme.of(context).colorScheme.primaryContainer',
      'const Color(0xFF166048)':
          'Theme.of(context).colorScheme.onPrimaryContainer',
      'Color(0xFF0D1512)': 'Theme.of(context).colorScheme.onSurface',
      'Colors.black87': 'Theme.of(context).colorScheme.onSurface',
      'Colors.black54':
          'Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)',
      'Colors.black': 'Theme.of(context).colorScheme.onSurface',
      'const Color.fromARGB(255, 238, 232, 232)':
          'Theme.of(context).colorScheme.surfaceContainerHighest',
    };

    for (final entry in replacements.entries) {
      if (content.contains(entry.key)) {
        // Simple heuristic: if we replace const Colors with Theme.of, we might need to remove const from TextStyle
        content = content.replaceAll(entry.key, entry.value);
        changed = true;
      }
    }

    if (changed) {
      // Very naive cleanup: removing const before TextStyle if it now contains Theme.of
      content = content.replaceAll(
        RegExp(r'const\s+TextStyle\('),
        'TextStyle(',
      );
      content = content.replaceAll(RegExp(r'const\s+Icon\('), 'Icon(');
      file.writeAsStringSync(content);
    }
  }
}
