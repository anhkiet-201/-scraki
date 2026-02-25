#!/usr/bin/env python3
"""
Add ffmpeg and ffprobe static binaries to Xcode project.pbxproj as bundled Resources.
These will be copied to Contents/Resources/ in the .app bundle.
"""

import uuid
import re

PBXPROJ_PATH = 'macos/Runner.xcodeproj/project.pbxproj'

# Fixed IDs for the Runner Resources build phase (from existing file)
# 33CC10EB2044A3C60003C045 is the PBXResourcesBuildPhase for Runner target
RUNNER_RESOURCES_PHASE_ID = '33CC10EB2044A3C60003C045'

# The Runner group that holds Resources sub-group
# 33CC11242044D66E0003C045 is the Resources group
RESOURCES_GROUP_ID = '33CC11242044D66E0003C045'

def gen_id():
    """Generate a reproducible-ish 24-char hex UUID."""
    return uuid.uuid4().hex[:24].upper()

def add_resource_file(content, filename, rel_path):
    """
    Inserts a new binary resource file into the pbxproj:
    1. PBXFileReference entry
    2. PBXBuildFile entry (in Resources)
    3. File added to Resources group children
    4. BuildFile added to Resources build phase files list
    Returns (updated content, file_ref_id, build_file_id)
    """
    file_ref_id = gen_id()
    build_file_id = gen_id()

    # 1. PBXFileReference
    file_ref = (
        f'\t\t{file_ref_id} /* {filename} */ = '
        f'{{isa = PBXFileReference; lastKnownFileType = "compiled"; '
        f'name = {filename}; path = "Runner/Resources/{filename}"; sourceTree = "<group>"; }};\n'
    )

    # 2. PBXBuildFile (Resources)
    build_file = (
        f'\t\t{build_file_id} /* {filename} in Resources */ = '
        f'{{isa = PBXBuildFile; fileRef = {file_ref_id} /* {filename} */; '
        f'settings = {{ATTRIBUTES = (CodeSignOnCopy, ); }}; }};\n'
    )

    # Insert PBXFileReference
    marker = '/* Begin PBXFileReference section */'
    pos = content.find(marker)
    if pos == -1:
        raise RuntimeError('PBXFileReference section not found')
    insert_pos = pos + len(marker) + 1
    content = content[:insert_pos] + file_ref + content[insert_pos:]

    # Insert PBXBuildFile
    marker = '/* Begin PBXBuildFile section */'
    pos = content.find(marker)
    if pos == -1:
        raise RuntimeError('PBXBuildFile section not found')
    insert_pos = pos + len(marker) + 1
    content = content[:insert_pos] + build_file + content[insert_pos:]

    # Add to Resources Group children
    # Find the Resources group (33CC11242044D66E0003C045)
    group_start = content.find(f'{RESOURCES_GROUP_ID} /* Resources */ = {{')
    if group_start == -1:
        raise RuntimeError(f'Resources group {RESOURCES_GROUP_ID} not found')
    children_start = content.find('children = (', group_start)
    if children_start == -1:
        raise RuntimeError('children = ( not found in Resources group')
    insert_pos = children_start + len('children = (') + 1
    content = (
        content[:insert_pos]
        + f'\t\t\t\t{file_ref_id} /* {filename} */,\n'
        + content[insert_pos:]
    )

    # Add BuildFile to PBXResourcesBuildPhase for Runner target
    # Find the Resources build phase by its known ID
    resources_phase_start = content.find(f'{RUNNER_RESOURCES_PHASE_ID} /* Resources */ = {{')
    if resources_phase_start == -1:
        raise RuntimeError(f'Resources build phase {RUNNER_RESOURCES_PHASE_ID} not found')
    files_start = content.find('files = (', resources_phase_start)
    if files_start == -1:
        raise RuntimeError('files = ( not found in Resources build phase')
    insert_pos = files_start + len('files = (') + 1
    content = (
        content[:insert_pos]
        + f'\t\t\t\t{build_file_id} /* {filename} in Resources */,\n'
        + content[insert_pos:]
    )

    return content, file_ref_id, build_file_id


def main():
    with open(PBXPROJ_PATH, 'r') as f:
        content = f.read()

    # Safety check — don't add twice
    if 'name = ffmpeg;' in content:
        print('⚠️  ffmpeg already present in project.pbxproj, skipping.')
        return

    content, ffmpeg_ref, ffmpeg_build = add_resource_file(content, 'ffmpeg', 'Runner/Resources/ffmpeg')
    print(f'✅ Added ffmpeg  — fileRef={ffmpeg_ref}, buildFile={ffmpeg_build}')

    content, ffprobe_ref, ffprobe_build = add_resource_file(content, 'ffprobe', 'Runner/Resources/ffprobe')
    print(f'✅ Added ffprobe — fileRef={ffprobe_ref}, buildFile={ffprobe_build}')

    with open(PBXPROJ_PATH, 'w') as f:
        f.write(content)

    print('\n✅ project.pbxproj updated successfully.')
    print('   ffmpeg and ffprobe will be copied to Contents/Resources/ when building.')


if __name__ == '__main__':
    main()
