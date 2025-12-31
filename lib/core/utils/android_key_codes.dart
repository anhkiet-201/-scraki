import 'package:flutter/services.dart';

class AndroidKeyCodes {
  // Key codes from Android KeyEvent.java
  static const int kUnknown = 0;
  static const int kSoftLeft = 1;
  static const int kSoftRight = 2;
  static const int kHome = 3;
  static const int kBack = 4;
  static const int kCall = 5;
  static const int kEndCall = 6;
  static const int k0 = 7;
  static const int k1 = 8;
  static const int k2 = 9;
  static const int k3 = 10;
  static const int k4 = 11;
  static const int k5 = 12;
  static const int k6 = 13;
  static const int k7 = 14;
  static const int k8 = 15;
  static const int k9 = 16;
  static const int kStar = 17;
  static const int kPound = 18;
  static const int kDpadUp = 19;
  static const int kDpadDown = 20;
  static const int kDpadLeft = 21;
  static const int kDpadRight = 22;
  static const int kDpadCenter = 23;
  static const int kVolumeUp = 24;
  static const int kVolumeDown = 25;
  static const int kPower = 26;
  static const int kCamera = 27;
  static const int kClear = 28;
  static const int kA = 29;
  static const int kB = 30;
  static const int kC = 31;
  static const int kD = 32;
  static const int kE = 33;
  static const int kF = 34;
  static const int kG = 35;
  static const int kH = 36;
  static const int kI = 37;
  static const int kJ = 38;
  static const int kK = 39;
  static const int kL = 40;
  static const int kM = 41;
  static const int kN = 42;
  static const int kO = 43;
  static const int kP = 44;
  static const int kQ = 45;
  static const int kR = 46;
  static const int kS = 47;
  static const int kT = 48;
  static const int kU = 49;
  static const int kV = 50;
  static const int kW = 51;
  static const int kX = 52;
  static const int kY = 53;
  static const int kZ = 54;
  static const int kComma = 55;
  static const int kPeriod = 56;
  static const int kAltLeft = 57;
  static const int kAltRight = 58;
  static const int kShiftLeft = 59;
  static const int kShiftRight = 60;
  static const int kTab = 61;
  static const int kSpace = 62;
  static const int kSym = 63;
  static const int kExplorer = 64;
  static const int kEnvelope = 65;
  static const int kEnter = 66;
  static const int kDel = 67; // Backspace
  static const int kGrave = 68;
  static const int kMinus = 69;
  static const int kEquals = 70;
  static const int kLeftBracket = 71;
  static const int kRightBracket = 72;
  static const int kBackslash = 73;
  static const int kSemicolon = 74;
  static const int kApostrophe = 75;
  static const int kSlash = 76;
  static const int kAt = 77;
  static const int kNum = 78;
  static const int kHeadsethook = 79;
  static const int kFocus = 80;
  static const int kPlus = 81;
  static const int kMenu = 82;
  static const int kNotification = 83;
  static const int kSearch = 84;
  static const int kPageUp = 92;
  static const int kPageDown = 93;
  static const int kEscape = 111;
  static const int kForwardDel = 112;
  static const int kCtrlLeft = 113;
  static const int kCtrlRight = 114;
  static const int kCapsLock = 115;
  static const int kScrollLock = 116;
  static const int kMetaLeft = 117;
  static const int kMetaRight = 118;
  static const int kFunction = 119;
  static const int kSysRq = 120;
  static const int kBreak = 121;
  static const int kMoveHome = 122;
  static const int kMoveEnd = 123;
  static const int kInsert = 124;
  static const int kForward = 125;
  static const int kMediaPlay = 126;
  static const int kMediaPause = 127;

  // Meta States (from Android KeyEvent.java)
  static const int kMetaAltOn = 0x02;
  static const int kMetaAltLeftOn = 0x10;
  static const int kMetaAltRightOn = 0x20;
  static const int kMetaShiftOn = 0x01;
  static const int kMetaShiftLeftOn = 0x40;
  static const int kMetaShiftRightOn = 0x80;
  static const int kMetaCtrlOn = 0x1000;
  static const int kMetaCtrlLeftOn = 0x2000;
  static const int kMetaCtrlRightOn = 0x4000;
  static const int kMetaMetaOn = 0x10000;
  static const int kMetaMetaLeftOn = 0x20000;
  static const int kMetaMetaRightOn = 0x40000;

  static int getKeyCode(LogicalKeyboardKey key) {
    // Map basic alphanumerics
    if (key.keyId >= LogicalKeyboardKey.keyA.keyId &&
        key.keyId <= LogicalKeyboardKey.keyZ.keyId) {
      return kA + (key.keyId - LogicalKeyboardKey.keyA.keyId).toInt();
    }
    if (key.keyId >= LogicalKeyboardKey.digit1.keyId &&
        key.keyId <= LogicalKeyboardKey.digit9.keyId) {
      return k1 + (key.keyId - LogicalKeyboardKey.digit1.keyId).toInt();
    }
    if (key == LogicalKeyboardKey.digit0) return k0;

    // Map special keys
    if (key == LogicalKeyboardKey.enter) return kEnter;
    if (key == LogicalKeyboardKey.space) return kSpace;
    if (key == LogicalKeyboardKey.backspace) return kDel;
    if (key == LogicalKeyboardKey.delete) return kForwardDel;
    if (key == LogicalKeyboardKey.escape) return kEscape;
    if (key == LogicalKeyboardKey.tab) return kTab;

    // Navigation
    if (key == LogicalKeyboardKey.arrowUp) return kDpadUp;
    if (key == LogicalKeyboardKey.arrowDown) return kDpadDown;
    if (key == LogicalKeyboardKey.arrowLeft) return kDpadLeft;
    if (key == LogicalKeyboardKey.arrowRight) return kDpadRight;
    if (key == LogicalKeyboardKey.home) return kMoveHome;
    if (key == LogicalKeyboardKey.end) return kMoveEnd;
    if (key == LogicalKeyboardKey.pageUp) return kPageUp;
    if (key == LogicalKeyboardKey.pageDown) return kPageDown;

    // Modifiers
    if (key == LogicalKeyboardKey.shiftLeft) return kShiftLeft;
    if (key == LogicalKeyboardKey.shiftRight) return kShiftRight;
    if (key == LogicalKeyboardKey.controlLeft) return kCtrlLeft;
    if (key == LogicalKeyboardKey.controlRight) return kCtrlRight;
    if (key == LogicalKeyboardKey.altLeft) return kAltLeft;
    if (key == LogicalKeyboardKey.altRight) return kAltRight;
    if (key == LogicalKeyboardKey.metaLeft) return kMetaLeft;
    if (key == LogicalKeyboardKey.metaRight) return kMetaRight;

    // Symbols
    if (key == LogicalKeyboardKey.minus) return kMinus;
    if (key == LogicalKeyboardKey.equal) return kEquals;
    if (key == LogicalKeyboardKey.bracketLeft) return kLeftBracket;
    if (key == LogicalKeyboardKey.bracketRight) return kRightBracket;
    if (key == LogicalKeyboardKey.backslash) return kBackslash;
    if (key == LogicalKeyboardKey.semicolon) return kSemicolon;
    if (key == LogicalKeyboardKey.quote) return kApostrophe; // '
    if (key == LogicalKeyboardKey.comma) return kComma;
    if (key == LogicalKeyboardKey.period) return kPeriod;
    if (key == LogicalKeyboardKey.slash) return kSlash;
    if (key == LogicalKeyboardKey.backquote) return kGrave; // `

    return kUnknown;
  }
}
