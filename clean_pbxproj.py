import re

path = r'C:\Users\diego\Documents\Nueva carpeta\iphone app\Novios.xcodeproj\project.pbxproj'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

keep_filenames = {
    'NoviosApp.swift', 'AppGate.swift', 'MainTabView.swift',
    'WelcomeView.swift', 'AddPartnerView.swift',
    'MessagesView.swift', 'ChatBubbleView.swift',
    'FirebaseRESTService.swift', 'AuthService.swift', 'UserService.swift',
    'ChatService.swift', 'StatusService.swift',
    'MessageModel.swift', 'UserModel.swift',
    'ThemeManager.swift',
    'GlassCard.swift', 'LiquidBackgroundView.swift',
    'GradientButton.swift', 'CustomTextField.swift',
    'GoogleService-Info.plist', 'GoogleService-Info (1).plist',
    'Contents.json',
}

UUID_PAT = r'[A-F0-9]{21,25}'

# Build a set of fileRef IDs and buildFile IDs to remove by scanning the PBXFileReference section
file_ref_section = re.search(
    r'/\* Begin PBXFileReference section \*/\n(.*?)/\* End PBXFileReference section \*/',
    content, re.DOTALL
)

file_ref_to_remove = set()
file_ref_all = {}  # id -> name

if file_ref_section:
    section = file_ref_section.group(1)
    # Find each entry: UUID /* name */ = { ... };
    for m in re.finditer(r'\t\t(' + UUID_PAT + r') /\* (.+?) \*/ = \{(.*?)\};', section, re.DOTALL):
        fid = m.group(1)
        fname = m.group(2)
        entry_body = m.group(3)
        file_ref_all[fid] = fname
        
        # Extract path from entry body
        path_match = re.search(r'path = (.+?);', entry_body)
        if path_match:
            fpath = path_match.group(1).strip()
            basename = fpath.split('/')[-1]
        else:
            basename = fname
        
        # Skip non-code files (like Novios.app)
        if not basename.endswith('.swift') and not basename.endswith('.png') and not basename.endswith('.plist') and not basename.endswith('.json'):
            continue
        if basename not in keep_filenames:
            file_ref_to_remove.add(fid)

print(f"File refs to remove: {len(file_ref_to_remove)}")
for fid in sorted(file_ref_to_remove):
    print(f"  {fid} /* {file_ref_all.get(fid, '?')} */")

# Build set of build file IDs to remove
build_section = re.search(
    r'/\* Begin PBXBuildFile section \*/\n(.*?)/\* End PBXBuildFile section \*/',
    content, re.DOTALL
)

build_to_remove = set()
build_all = {}

if build_section:
    section = build_section.group(1)
    for m in re.finditer(r'\t\t(' + UUID_PAT + r') /\* (.+?) \*/ = \{(.*?)\};', section, re.DOTALL):
        bid = m.group(1)
        bname = m.group(2)
        entry_body = m.group(3)
        build_all[bid] = bname
        ref_match = re.search(r'fileRef = (' + UUID_PAT + r')', entry_body)
        if ref_match and ref_match.group(1) in file_ref_to_remove:
            build_to_remove.add(bid)

print(f"Build files to remove: {len(build_to_remove)}")

def remove_from_section(content, section_name, ids):
    pattern = re.compile(
        r'/\* Begin ' + re.escape(section_name) + r' section \*/\n(.*?)/\* End ' + re.escape(section_name) + r' section \*/',
        re.DOTALL
    )
    match = pattern.search(content)
    if not match:
        return content
    section = match.group(1)
    lines = section.split('\n')
    new_lines = []
    for line in lines:
        id_match = re.match(r'\t+(' + UUID_PAT + r') ', line)
        if id_match and id_match.group(1) in ids:
            continue
        new_lines.append(line)
    new_section = '\n'.join(new_lines).rstrip() + '\n'
    return (content[:match.start()] +
            f'/* Begin {section_name} section */\n{new_section}' +
            f'/* End {section_name} section */' +
            content[match.end():])

# Remove build files
content = remove_from_section(content, 'PBXBuildFile', build_to_remove)
# Remove file refs
content = remove_from_section(content, 'PBXFileReference', file_ref_to_remove)

# Remove from PBXGroup
grp_section = re.search(
    r'/\* Begin PBXGroup section \*/(.*?)/\* End PBXGroup section \*/',
    content, re.DOTALL
)
if grp_section:
    section = grp_section.group(1)
    for fid in file_ref_to_remove:
        section = re.sub(
            rf'\t\t\t\t{re.escape(fid)} /\* .+? \*/,\n?', '', section)
    section = re.sub(r'\n{3,}', '\n\n', section)
    content = (content[:grp_section.start()] +
               f'/* Begin PBXGroup section */{section}' +
               f'/* End PBXGroup section */' +
               content[grp_section.end():])

# Remove from Sources phase
content = remove_from_section(content, 'PBXSourcesBuildPhase', build_to_remove)

print(f"\nFinal size: {len(content)} bytes")
with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
