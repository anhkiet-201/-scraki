#!/usr/bin/env python3
"""
Add VideoDecoderPlugin.mm to Xcode project.pbxproj
This script manually edits the pbxproj file to add source files.
"""

import uuid
import os

pbxproj_path = 'macos/Runner.xcodeproj/project.pbxproj'

# Read the file
with open(pbxproj_path, 'r') as f:
    content = f.read()

# Generate UUIDs for new file references
mm_file_uuid = uuid.uuid4().hex[:24].upper()
h_file_uuid = uuid.uuid4().hex[:24].upper()
build_file_uuid = uuid.uuid4().hex[:24].upper()

# Add PBXFileReference for .mm
mm_file_ref = f'''\t\t{mm_file_uuid} /* VideoDecoderPlugin.mm */ = {{isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.cpp.objcpp; path = VideoDecoderPlugin.mm; sourceTree = "<group>"; }};
'''

# Add PBXFileReference for .h  
h_file_ref = f'''\t\t{h_file_uuid} /* VideoDecoderPlugin.h */ = {{isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.c.h; path = VideoDecoderPlugin.h; sourceTree = "<group>"; }};
'''

# Add PBXBuildFile for .mm (to compile)
build_file = f'''\t\t{build_file_uuid} /* VideoDecoderPlugin.mm in Sources */ = {{isa = PBXBuildFile; fileRef = {mm_file_uuid} /* VideoDecoderPlugin.mm */; }};
'''

# Find the right places to insert

# 1. Add to PBXBuildFile section
pbx_buildfile_marker = '/* Begin PBXBuildFile section */'
insert_pos = content.find(pbx_buildfile_marker) + len(pbx_buildfile_marker) + 1
content = content[:insert_pos] + build_file + content[insert_pos:]

# 2. Add to PBXFileReference section  
pbx_filereference_marker = '/* Begin PBXFileReference section */'
insert_pos = content.find(pbx_filereference_marker) + len(pbx_filereference_marker) + 1
content = content[:insert_pos] + mm_file_ref + h_file_ref + content[insert_pos:]

# 3. Add to Runner group (children array)
# Find: 33CC10EE2044A3C60003C045 /* Runner */ = {
runner_group_start = content.find('33CC10EE2044A3C60003C045 /* Runner */ = {')
if runner_group_start != -1:
    # Find children array in this group
    children_start = content.find('children = (', runner_group_start)
    if children_start != -1:
        # Insert after opening parenthesis
        insert_pos = children_start + len('children = (') + 1
        content = content[:insert_pos] + f'''\t\t\t\t{mm_file_uuid} /* VideoDecoderPlugin.mm */,
\t\t\t\t{h_file_uuid} /* VideoDecoderPlugin.h */,
''' + content[insert_pos:]

# 4. Add to PBXSourcesBuildPhase (compile sources)
# Find: /* Sources */ = {
sources_buildphase_marker = '/* Sources */ = {'
sources_start = content.find(sources_buildphase_marker)
if sources_start != -1:
    # Find files array
    files_start = content.find('files = (', sources_start)
    if files_start != -1:
        insert_pos = files_start + len('files = (') + 1
        content = content[:insert_pos] + f'''\t\t\t\t{build_file_uuid} /* VideoDecoderPlugin.mm in Sources */,
''' + content[insert_pos:]

# Write back
with open(pbxproj_path, 'w') as f:
    f.write(content)

print("✅ Added VideoDecoderPlugin.mm to Xcode project")
print("✅ Added VideoDecoderPlugin.h to Xcode project")
print("Now run: flutter run -d macos")
