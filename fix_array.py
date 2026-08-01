import os
import re

dir_paths = [r'd:\harur\frontend\lib\screens', r'd:\harur\frontend\lib\widgets']

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content
    
    # Strip [800]! or [300] from Theme.of(context) color calls
    # Usually it looks like .withOpacity(0.5)[800]! or .withOpacity(0.5)[300]
    content = re.sub(r'(\.withOpacity\([\d.]+\))\[\d{3}\]!?', r'\1', content)
    
    # Also strip it if it's attached directly to colorScheme.onSurface[800]!
    content = re.sub(r'(\.onSurface)\[\d{3}\]!?', r'\1', content)
    content = re.sub(r'(\.surface)\[\d{3}\]!?', r'\1', content)
    content = re.sub(r'(AppTheme\.\w+)\[\d{3}\]!?', r'\1', content)

    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed array indexing in {os.path.basename(filepath)}")

for d in dir_paths:
    for root, _, files in os.walk(d):
        for f in files:
            if f.endswith('.dart'):
                process_file(os.path.join(root, f))
