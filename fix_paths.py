#!/usr/bin/env python3
"""
Fix file reference paths for VideoDecoderPlugin files
The issue is that the files are being referenced from wrong directory
"""

with open('macos/Runner.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# The current path is relative to macos/, but should be relative to macos/Runner  
# Change:   path = VideoDecoderPlugin.mm
# To:       path = Runner/VideoDecoderPlugin.mm

# Actually, looking at the pbxproj format, if files are in Runner group with sourceTree = "<group>",
# they should have just the filename, not the path.
# The problem is the files might not be in the Runner group properly in the filesystem.

# Let's check the actual reference
import re

# Find the file references
mm_ref = re.search(r'([\dA-F]+) /\* VideoDecoderPlugin\.mm \*/ = \{[^}]+path = ([^;]+);[^}]+sourceTree = ([^;]+);[^}]+\};', content)
h_ref = re.search(r'([\dA-F]+) /\* VideoDecoderPlugin\.h \*/ = \{[^}]+path = ([^;]+);[^}]+sourceTree = ([^;]+);[^}]+\};', content)

if mm_ref:
    print(f"MM File: ID={mm_ref.group(1)}, path={mm_ref.group(2)}, sourceTree={mm_ref.group(3)}")
    
if h_ref:
    print(f"H File: ID={h_ref.group(1)}, path={h_ref.group(2)}, sourceTree={h_ref.group(3)}")

# The sourceTree is "<group>" which means relative to parent group
# Since files are in Runner group, paths should just be the filenames
# But Xcode is looking for them in macos/ instead of macos/Runner/

# Solution: Keep path as just filename, but make sure files are in Runner filesystem group
# OR: Change path to include Runner/

# Let's try option 2: add "Runner/" prefix to paths
content = content.replace(
    'path = VideoDecoderPlugin.mm;',
    'path = Runner/VideoDecoderPlugin.mm;'
)

content = content.replace(
    'path = VideoDecoderPlugin.h;',
    'path = Runner/VideoDecoderPlugin.h;'
)

with open('macos/Runner.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print("\n✅ Fixed file reference paths")
print("Now run: flutter run -d macos")
