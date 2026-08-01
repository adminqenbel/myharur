import os
import re

dir_path = r'd:\harur\frontend\lib\screens'

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content
    
    # Fix .shadeXXX calls on Theme colors
    # e.g., Theme.of(context).colorScheme.onSurface.withOpacity(0.5).shade500 -> Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
    # or AppTheme.danger.shade900 -> AppTheme.danger
    content = re.sub(r'\.shade\d{3}', '', content)
    
    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed shadeXXX in {os.path.basename(filepath)}")

for root, _, files in os.walk(dir_path):
    for f in files:
        if f.endswith('.dart'):
            process_file(os.path.join(root, f))
