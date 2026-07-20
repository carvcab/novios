import uuid

path = r'C:\Users\diego\Documents\Nueva carpeta\iphone app\Novios.xcodeproj\project.pbxproj'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

def make_uuid(seed):
    return uuid.uuid5(uuid.NAMESPACE_DNS, seed).hex.upper()[:24]

file_uuid = make_uuid('SettingsView.swift.file')
build_uuid = make_uuid('SettingsView.swift.build')

file_ref = '\t\t' + file_uuid + ' /* SettingsView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Views/Settings/SettingsView.swift; sourceTree = "<group>"; };'
build_ref = '\t\t' + build_uuid + ' /* SettingsView.swift in Sources */ = {isa = PBXBuildFile; fileRef = ' + file_uuid + ' /* SettingsView.swift */; };'

idx = content.find('/* End PBXBuildFile section */')
content = content[:idx] + build_ref + '\n' + content[idx:]

idx = content.find('/* End PBXFileReference section */')
content = content[:idx] + file_ref + '\n' + content[idx:]

idx = content.find('9A004392C0000000000000439 /* GoogleService-Info (1).plist */,') + len('9A004392C0000000000000439 /* GoogleService-Info (1).plist */,')
content = content[:idx] + '\n\t\t\t\t' + file_uuid + ' /* SettingsView.swift */,' + content[idx:]

idx = content.rfind('9A0004E2C00000000000004E /* StatusService.swift in Sources */,') + len('9A0004E2C00000000000004E /* StatusService.swift in Sources */,')
content = content[:idx] + '\n\t\t\t\t' + build_uuid + ' /* SettingsView.swift in Sources */,' + content[idx:]

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print(f'Added SettingsView.swift to pbxproj (file={file_uuid}, build={build_uuid})')
