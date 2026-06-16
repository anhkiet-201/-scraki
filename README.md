# Scraki

Scraki is a powerful Flutter desktop application for mirroring and controlling Android devices with ultra-low latency. Built with **Feature-Clean Architecture**, **MobX** state management, and native FFmpeg decoding for maximum performance.

## ✨ Features

- **🚀 Ultra-low Latency**: Native FFmpeg decoding with Flutter Texture for near-instant response
- **⚡ High Performance**: Dedicated Isolates for video/audio processing, zero UI blocking
- **🎵 Audio Mirroring**: Cross-platform audio support (macOS & Windows)
- **🖥️ Cross-Platform**: Full support for macOS and Windows
- **🎮 Full Device Control**: Touch events, keyboard input, scrolling, clipboard sync
- **🪟 Floating Windows**: Double-tap devices to pop out into floating mode
- **📁 File Transfer**: Drag & drop files directly to device
- **📋 Clipboard Sync**: Seamless clipboard integration (Cmd+V support)
- **🏗️ Clean Architecture**: Feature-based structure for scalability
- **📱 Multi-Device**: Control multiple devices simultaneously in grid or floating mode
- **📂 Device Grouping**: Organize devices into groups with custom colors and horizontal filtering
- **✨ Premium UI**: Sophisticated glassmorphism aesthetic with specialized `BoxCard` and `BoxCardMenu` components
- **🎨 AI Recruitment Posters**: Built-in designer with 20+ templates (Modern, Glassmorphism, Retro...) and real-time text editing.
- **🖌️ Advanced Text Backgrounds**: Real-time brush art and rectangle background customization with granular control over opacity, radius, and brush properties.
- **📜 ADB Execution & Scripting Engine**: Parallel command execution across multiple devices with dynamic placeholders (`{I}`, `{SERIAL}`) and real-time monitoring.

## 🏛️ Architecture

Scraki follows **Feature-Based Clean Architecture** with strict **SOLID** principles. For detailed architecture documentation, see [ARCHITECTURE.md](ARCHITECTURE.md).

For the **Poster Designer** system architecture and template catalog, see [PosterDesign.md](PosterDesign.md).

### 📦 Tech Stack

| Category                   | Technology                         |
| -------------------------- | ---------------------------------- |
| **Framework**              | Flutter                            |
| **State Management**       | MobX (Global & Scoped Stores)      |
| **Dependency Injection**   | GetIt + Injectable                 |
| **Native Decoding**        | FFmpeg (via FFI)                   |
| **Concurrency**            | Isolates (dedicated video workers) |
| **Functional Programming** | fpdart (Either, Option)            |
| **Mirroring Protocol**     | scrcpy                             |
| **Rendering**             | CustomPainters (Brush art, etc.)   |

### 📂 Project Structure

```
lib/
├── core/               # Shared: DI, stores, utils, widgets
│   ├── di/
│   ├── stores/         # Global stores (DeviceManager, SessionManager)
│   └── mixins/
├── features/           # Feature modules
│   ├── device/         # Device mirroring & group management
│   ├── poster/         # AI poster creation
│   ├── script/         # ADB execution & scripting engine
│   └── dashboard/      # Main dashboard with horizontal group selector
└── main.dart
```

### 🔄 State Management Pattern

**No setState!** Everything is reactive with MobX:

```dart
// Store
@observable
ObservableList<Device> devices = ObservableList();

// Widget
class MyWidget extends StatelessWidget with DeviceManagerStoreMixin {
  Widget build(context) => Observer(
    builder: (_) => Text('Devices: ${deviceManagerStore.devices.length}'),
  );
}
```

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.0+)
- [ADB (Android Debug Bridge)](https://developer.android.com/tools/adb)
- FFmpeg libraries (installed on host system)

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/yourusername/scraki.git
   cd scraki
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Generate code** (MobX + Injectable)

   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the application**
   ```bash
   flutter run -d macos  # or -d windows
   ```

## 🛠️ Development

### Watch mode (auto-regenerate code)

```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

### Run tests

```bash
flutter test
```

### Analyze code

```bash
flutter analyze
```

## 📖 Key Concepts

### Global vs Scoped Stores

**Global Stores** (`lib/core/stores/`)

- `DeviceManagerStore`: Manages device list and ADB connections
- `SessionManagerStore`: Manages mirroring sessions (grid/floating modes)

**Scoped Stores** (`lib/features/*/presentation/stores/`)

- Created/disposed with widget lifecycle
- Example: `PhoneViewStore`, `FloatingPhoneViewStore`

### Performance Profiles

- **Grid Mode**: 1 Mbps, 10 FPS (low bandwidth)
- **Floating Mode**: 8 Mbps, 60 FPS (high quality)

Sessions automatically switch profiles based on viewing mode.

### 📱 Internal scrcpy Integration

Scraki leverages a customized implementation of the `scrcpy` protocol:

- **Server Lifecycle**: Scraki automatically pushes and manages the `scrcpy-server.jar` on the Android device via ADB.
- **Port Management**: Dynamic port forwarding and TCP proxying enable multiple simultaneous mirroring sessions.
- **Protocol Support**:
  - **Video**: H.264/H.265 encoded via hardware on device, decoded via FFmpeg on host.
  - **Audio**: Raw/AAC/Opus support depending on device capabilities.
  - **Control**: Direct binary protocol for injecting input events (touch, keys, mouse).
- **Customizations**: Optimized server parameters for specific Scraki performance profiles.

- **Customizations**: Optimized server parameters for specific Scraki performance profiles.

### 📜 ADB Execution & Scripting Engine

Scraki includes a high-performance engine for executing ADB commands and scripts across multiple devices simultaneously:

- **Parallel Execution**: Smart batching (default: 10 devices/batch) with a 50ms pulse delay between device initialization to maintain ADB server stability.
- **Dynamic Placeholders**:
  - `{I}`: Replaced by the **3rd Octet** of the device's IP address (e.g., `192.168.x.10` -> `x`). Essential for network-segment-specific commands.
  - `{SERIAL}`: Replaced by the full device serial or IP:Port.
- **Script Management**: Full CRUD support for saving and executing complex multi-command sequences.
- **Script Modularization (#import & #import client)**:
  - **`#import <script_name>`**: Imports and flattens a child script's commands directly. Only compatible between identical environments (e.g., PowerShell within `#bash server`, or Android within `#bash`).
  - **`#import client <script_name> [arg1 arg2 "arg 3" ...]`**: Imports an Android script (Android bash/single commands) inside a `#bash server` (PowerShell) block. 
    - Supports positional parameters: The child script uses standard Unix positional parameters like `$1`, `$2`, etc.
    - Arguments passed are forwarded directly to the Android shell using `sh -s`.
    - Commands are automatically wrapped in a PowerShell Here-String wrapper to execute on the Android device via ADB:
      ```powershell
      @'
      # Child commands executed on device (using $1, $2...)
      '@ | adb -s {SERIAL} shell "sh -s 'arg1' 'arg2'"
      ```
    - **Context Protection**: Throws compilation exceptions when mixing incompatible environments (e.g., importing PowerShell into Android bash, or using normal `#import` for Android commands in a server block) to prevent silent execution failures.
- **Advanced Filtering**: Quickly select devices by group assignment or specific IP segment ranges (3rd octet).
- **Real-time Monitoring**:
  - **Global Console**: Centralized terminal for aggregated logs across all devices (up to 5000 lines).
  - **Tiled Log View**: Grid-based UI for monitoring individual real-time terminal outputs for each device (optimized with a 500-line buffer per device).

## 🤝 Contributing

Contributions are welcome! Please:

1. Follow the existing architecture patterns
2. Use MobX for state (no `setState`)
3. Write tests for new features
4. Run `flutter analyze` before committing

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [scrcpy](https://github.com/Genymobile/scrcpy) - The amazing Android mirroring protocol
- Flutter team for the cross-platform framework
- MobX community for reactive state management
