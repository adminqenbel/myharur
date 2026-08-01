import os
import re

dir_paths = [r'd:\harur\frontend\lib\screens', r'd:\harur\frontend\lib\widgets']

widgets = [
    'Center', 'Column', 'Row', 'Padding', 'Icon', 'Text', 'BoxDecoration',
    'LinearGradient', 'BoxShadow', 'TextStyle', 'IconThemeData', 'SizedBox',
    'MHCard', 'MHButton', 'Container', 'ThemeData', 'Scaffold', 'AppBar', 'ListView',
    'SingleChildScrollView', 'Card', 'Align', 'Positioned', 'Expanded', 'Flexible',
    'Wrap', 'Stack', 'FractionallySizedBox', 'Material', 'InkWell', 'GestureDetector',
    'CircleAvatar', 'Divider', 'Spacer', 'AlertDialog', 'TextButton', 'OutlinedButton',
    'ElevatedButton', 'CircularProgressIndicator', 'SnackBar', 'TabBar', 'Tab',
    'FloatingActionButton', 'ListTile', 'RefreshIndicator', 'CustomScrollView',
    'SliverAppBar', 'SliverToBoxAdapter', 'SliverPadding', 'SliverList', 'SliverGrid'
]

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content
    
    # Strip const from lists unconditionally just in case
    content = content.replace('children: const [', 'children: [')
    content = content.replace('const [', '[')
    
    for w in widgets:
        # We need to replace "const WidgetName(" or "const WidgetName."
        # Using a regex: \bconst\s+WidgetName\b
        pattern = r'\bconst\s+' + w + r'\b'
        content = re.sub(pattern, w, content)

    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Brute-force stripped const in {os.path.basename(filepath)}")

for d in dir_paths:
    for root, _, files in os.walk(d):
        for f in files:
            if f.endswith('.dart'):
                process_file(os.path.join(root, f))
