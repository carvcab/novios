import re

path = r'C:\Users\diego\Documents\Nueva carpeta\iphone app\Novios.xcodeproj\project.pbxproj'
with open(path, encoding='utf-8') as f:
    content = f.read()

content = content.replace(
    '\t\tC7D0452E86ED57769C9C771B /* SettingsView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 0D4F7B3D3DCF5B29A3B30953 /* SettingsView.swift */; };',
    '', 1
)
content = content.replace(
    '\t\t0D4F7B3D3DCF5B29A3B30953 /* SettingsView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Views/Settings/SettingsView.swift; sourceTree = "<group>"; };',
    '', 1
)
content = content.replace(
    '\t\t\t\t0D4F7B3D3DCF5B29A3B30953 /* SettingsView.swift */,',
    '', 1
)
content = content.replace(
    '\t\t\t\tC7D0452E86ED57769C9C771B /* SettingsView.swift in Sources */,',
    '', 1
)
content = re.sub(r'\n{3,}', '\n\n', content)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print('Cleaned duplicates from pbxproj')
