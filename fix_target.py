#!/usr/bin/env python3
"""
Fix: Move VideoDecoderPlugin.mm from RunnerTests to Runner target
"""

with open('macos/Runner.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# Remove from RunnerTests sources (331C80D1294CF70F00263BE5)
# Find the line and remove it
content = content.replace(
    '\t\t\t\t69ECDB21F8954815916E9936 /* VideoDecoderPlugin.mm in Sources */,\n',
    ''
)

# Add to Runner sources (33CC10E92044A3C60003C045)
# Find Runner's Sources build phase
runner_sources_marker = '33CC10E92044A3C60003C045 /* Sources */ = {'
runner_sources_start = content.find(runner_sources_marker)

if runner_sources_start != -1:
    # Find files array in Runner Sources
    files_start = content.find('files = (', runner_sources_start)
    if files_start != -1:
        # Insert after "files = ("
        insert_pos = files_start + len('files = (') + 1
        content = content[:insert_pos] + '\t\t\t\t69ECDB21F8954815916E9936 /* VideoDecoderPlugin.mm in Sources */,\n' + content[insert_pos:]
        
        with open('macos/Runner.xcodeproj/project.pbxproj', 'w') as f:
            f.write(content)
        
        print("✅ Moved VideoDecoderPlugin.mm to Runner target")
        print("Now run: flutter run -d macos")
    else:
        print("❌ Could not find files array in Runner Sources")
else:
    print("❌ Could not find Runner Sources build phase")
