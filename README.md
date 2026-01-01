# Scraki

Scraki is a powerful and lightweight Flutter application for mirroring and controlling Android devices with ultra-low latency. It leverages the robust `scrcpy` protocol and native FFmpeg decoding for high-performance screen sharing.

## Features

- **Ultra-low Latency**: Uses native FFmpeg decoding and Flutter Texture for near-instant response.
- **High Performance**: Optimized data flow using local TCP proxies.
- **Full Control**: Support for touch events, keyboard input, and scrolling.
- **Floating Window**: Double-tap to pop out devices into floating windows.
- **File Transfer**: Drag & drop files directly to your device.
- **Clipboard Sync**: Seamless clipboard integration with Cmd+V support.
- **Clean Architecture**: Built with maintainability and scalability in mind.
- **State Management**: Robust state handling with MobX.
- **Dependency Injection**: Seamless service management with GetIt and Injectable.

## Architecture

Scraki follows **Clean Architecture** principles with a feature-based folder structure. For a detailed overview, please see [ARCHITECTURE.md](ARCHITECTURE.md).

### Tech Stack

- **Flutter**: UI Framework
- **MobX**: State Management (Global Stores pattern)
- **GetIt & Injectable**: Dependency Injection
- **FFmpeg**: Native video decoding
- **fpdart**: Functional programming primitives (Either, Option)

### Key Components

- **Global Stores**:
  - `DeviceStore`: Manages device discovery and connections
  - `MirroringStore`: Handles mirroring lifecycle and all input events
- **Pure UI Components**: Complete separation of UI and business logic
- **Reusable Widgets**: Modular components for common UI patterns

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [ADB (Android Debug Bridge)](https://developer.android.com/tools/adb)
- FFmpeg libraries installed on the host system (for native decoding).

### Installation

1.  Clone the repository:

    ```bash
    git clone https://github.com/yourusername/scraki.git
    cd scraki
    ```

2.  Install dependencies:

    ```bash
    flutter pub get
    ```

3.  Generate code for MobX and Injectable:

    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```

4.  Run the application:
    ```bash
    flutter run
    ```

## Development

To watch for changes and automatically regenerate code:

```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
