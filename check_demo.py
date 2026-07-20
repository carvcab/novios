import os

views_dir = r'C:\Users\diego\Documents\Nueva carpeta\iphone app\Novios\Views'
issues = []

for root, dirs, files in os.walk(views_dir):
    for f in files:
        if not f.endswith('.swift'): continue
        path = os.path.join(root, f)
        with open(path, 'r', encoding='utf-8', errors='ignore') as fp:
            content = fp.read()
            lines = content.split('\n')
            rel_path = os.path.relpath(path, views_dir)

            # Check for hardcoded data arrays with sample/mock
            for i, line in enumerate(lines):
                if 'sample' in line.lower() or 'mock' in line.lower():
                    if 'let ' in line or 'var ' in line or '=' in line:
                        if 'TextField' not in line and 'placeholder' not in line.lower():
                            issues.append(f'{rel_path}:{i+1}: {line.strip()[:100]}')

for i in issues:
    print(i)

if not issues:
    print('OK - No sample/mock data found')
