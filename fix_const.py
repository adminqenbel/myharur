import os
import re

dir_paths = [r'd:\harur\frontend\lib\screens', r'd:\harur\frontend\lib\widgets']

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content
    
    content = content.replace('AppTheme.warning', 'AppTheme.accent')
    content = content.replace('children: const [', 'children: [')
    content = content.replace('const [', '[')
    
    # Also fix some other const prefixes that might have been missed
    content = re.sub(r'\bconst\s+MHButton', 'MHButton', content)
    content = re.sub(r'\bconst\s+MHCard', 'MHCard', content)
    content = re.sub(r'\bconst\s+EdgeInsets', 'EdgeInsets', content)
    content = re.sub(r'\bconst\s+SizedBox', 'SizedBox', content)

    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed remaining const in {os.path.basename(filepath)}")

for d in dir_paths:
    for root, _, files in os.walk(d):
        for f in files:
            if f.endswith('.dart'):
                process_file(os.path.join(root, f))
