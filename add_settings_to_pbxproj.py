import re, uuid

path = r'C:\Users\diego\Documents\Nueva carpeta\iphone app\Novios.xcodeproj\project.pbxproj'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

def make_uuid(seed):
    return uuid.uuid5(uuid.NAMESPACE_DNS, seed).hex.upper()[:24]

file_uuid = make_uuid('SettingsView.swift.file')
build_uuid = make_uuid('SettingsView.swift.build')

file_ref = '\t\t' + file_uuid + ' /* SettingsView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Views/Settings/SettingsView.swift; sourceTree = "<group>"; };'
build_ref = '\t\t' + build_uuid + ' /* SettingsView.swift in Sources */ = {isa = PBXBuildFile; fileRef = ' + file_uuid + ' /* SettingsView.swift */; };'

content = content.replace(
    '/* End PBXFileReference section */',
    file_ref + '\n/* End PBXFileReference section */'
)

content = content.replace(
    '/* End PBXBuildFile section */',
    build_ref + '\n/* End PBXBuildFile section */'
)

content = content.replace(
    '9A004392C0000000000000439 /* GoogleService-Info (1).plist */,',
    '9A004392C0000000000000439 /* GoogleService-Info (1).plist */,\n\t\t\t\t' + file_uuid + ' /* SettingsView.swift */,'
)

content = content.replace(
    '/* End PBXSourcesBuildPhase section */',
    '\t\t\t\t' + build_uuid + ' /* SettingsView.swift in Sources */,\n\t\t\t/* End PBXSourcesBuildPhase section */'
)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print(f'Added SettingsView.swift to pbxproj (file={file_uuid}, build={build_uuid})')
