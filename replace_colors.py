import os
import re

dir_path = r'd:\harur\frontend\lib\widgets'

replacements = {
    r'const Color\(0xFFF4F6F9\)': r'Theme.of(context).scaffoldBackgroundColor',
    r'Color\(0xFFF4F6F9\)': r'Theme.of(context).scaffoldBackgroundColor',
    r'const Color\(0xFF081C2D\)': r'Theme.of(context).colorScheme.onSurface',
    r'Color\(0xFF081C2D\)': r'Theme.of(context).colorScheme.onSurface',
    r'const Color\(0xFFEF233C\)': r'AppTheme.danger',
    r'Color\(0xFFEF233C\)': r'AppTheme.danger',
    r'const Color\(0xFF3A86FF\)': r'AppTheme.info',
    r'Color\(0xFF3A86FF\)': r'AppTheme.info',
    r'const Color\(0xFF64748B\)': r'Theme.of(context).colorScheme.onSurface.withOpacity(0.6)',
    r'Color\(0xFF64748B\)': r'Theme.of(context).colorScheme.onSurface.withOpacity(0.6)',
    r'const Color\(0xFF06D6A0\)': r'AppTheme.success',
    r'Color\(0xFF06D6A0\)': r'AppTheme.success',
    r'const Color\(0xFFFFB703\)': r'AppTheme.warning',
    r'Color\(0xFFFFB703\)': r'AppTheme.warning',
    r'Colors\.redAccent': r'AppTheme.danger',
    r'Colors\.white': r'Theme.of(context).colorScheme.surface',
    r'Colors\.red': r'AppTheme.danger',
    r'Colors\.grey': r'Theme.of(context).colorScheme.onSurface.withOpacity(0.5)',
}

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content
    for pattern, repl in replacements.items():
        content = re.sub(pattern, repl, content)

    # ensure AppTheme is imported if we use AppTheme
    if 'AppTheme' in content and 'import \'../theme.dart\';' not in content:
        # find the last import and add it after
        content = re.sub(r"(import '.*?';\n)(?!import)", r"\1import '../theme.dart';\n", content, count=1)

    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {os.path.basename(filepath)}")

for root, _, files in os.walk(dir_path):
    for f in files:
        if f.endswith('.dart'):
            process_file(os.path.join(root, f))
