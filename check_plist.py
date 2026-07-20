import plistlib

with open(r'C:\Users\diego\Documents\Nueva carpeta\iphone app\Novios\GoogleService-Info.plist', 'rb') as f:
    primary = plistlib.load(f)
print('PRIMARY (novios-8beb7):')
print('  API_KEY:', primary.get("API_KEY", "NOT FOUND"))
print('  PROJECT_ID:', primary.get("PROJECT_ID", "NOT FOUND"))
print('  BUNDLE_ID:', primary.get("BUNDLE_ID", "NOT FOUND"))

with open(r'C:\Users\diego\Documents\Nueva carpeta\iphone app\Novios\GoogleService-Info (1).plist', 'rb') as f:
    backup = plistlib.load(f)
print()
print('BACKUP (novios-49289):')
print('  API_KEY:', backup.get("API_KEY", "NOT FOUND"))
print('  PROJECT_ID:', backup.get("PROJECT_ID", "NOT FOUND"))
print('  BUNDLE_ID:', backup.get("BUNDLE_ID", "NOT FOUND"))
