#!/usr/bin/env ruby

require 'xcodeproj'

# Open the Xcode project
project_path = 'macos/Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the Runner target
target = project.targets.find { |t| t.name == 'Runner' }

# Get the Runner group
runner_group = project.main_group.find_subpath('Runner')

# Add VideoDecoderPlugin files to the project
plugin_mm = runner_group.new_file('VideoDecoderPlugin.mm')
plugin_h = runner_group.new_file('VideoDecoderPlugin.h')

# Add .mm file to compile sources
target.source_build_phase.add_file_reference(plugin_mm)

# Add .h file to headers (optional, usually not needed for bridging)
# target.headers_build_phase.add_file_reference(plugin_h)

# Save the project
project.save

puts "✅ Added VideoDecoderPlugin.mm to Xcode project"
puts "✅ Added VideoDecoderPlugin.h to Xcode project"
puts "Now run: flutter run -d macos"
