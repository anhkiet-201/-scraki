import 'dart:ui';

/// UI Constants for the Scraki application.
///
/// Contains all hardcoded values used in the UI layer to ensure
/// consistency and easy customization.
class UIConstants {
  UIConstants._();

  // === TIMING ===

  /// Timeout for detecting double taps
  static const doubleTapTimeout = Duration(milliseconds: 300);

  /// Delay between keydown and keyup for navigation buttons
  static const navButtonPressDelay = Duration(milliseconds: 50);

  /// Animation duration for hover effects
  static const hoverAnimationDuration = Duration(milliseconds: 200);

  // === DIMENSIONS ===

  /// Height of the Android navigation bar at bottom of PhoneView
  static const double gridNavigationBarHeight = 30.0;

  /// Navigation button icon size (regular)
  static const double gridNavButtonIconSize = 12.0;

  /// Navigation button icon size (primary)
  static const double gridNavButtonIconSizePrimary = 12.0;

  // === PADDING & SPACING ===

  /// Horizontal padding for navigation buttons
  static const double gridNavButtonPaddingHorizontal = 8.0;

  /// Vertical padding for navigation buttons
  static const double gridNavButtonPaddingVertical = 4.0;

    /// Height of the Android navigation bar at bottom of PhoneView
  static const double floatingNavigationBarHeight = 140.0;

  /// Navigation button icon size (regular)
  static const double floatingNavButtonIconSize = 48.0;

  /// Navigation button icon size (primary)
  static const double floatingNavButtonIconSizePrimary = 48.0;

  // === PADDING & SPACING ===

  /// Horizontal padding for navigation buttons
  static const double floatingNavButtonPaddingHorizontal = 24.0;

  /// Vertical padding for navigation buttons
  static const double floatingNavButtonPaddingVertical = 16.0;

  /// Border radius for device cards
  static const double deviceCardBorderRadius = 20.0;

  /// Border radius for general components
  static const double componentBorderRadius = 16.0;

  /// Border radius for buttons
  static const double buttonBorderRadius = 40.0;

  /// Minimum size for floating phone window
  static const Size floatingWindowMinSize = Size(300, 600);

  // === VISIBILITY & THRESHOLDS ===

  /// Minimum visible fraction to consider widget visible
  static const double visibilityThreshold = 0.05;

  // === TOUCH & INPUT ===

  /// Default button mask for touch events (primary button)
  static const int defaultTouchButtons = 1;

  // === DRAG & DROP ===

  /// Icon size for drag overlay
  static const double dragOverlayIconSize = 20.0;

  /// Font size for drag overlay title
  static const double dragOverlayTitleSize = 18.0;

  /// Font size for drag overlay subtitle
  static const double dragOverlaySubtitleSize = 14.0;

  // === LOADING & PROGRESS ===

  /// Size of progress indicators
  static const double progressIndicatorSize = 4.0;

  /// Stroke width for progress indicators
  static const double progressIndicatorStroke = 2.0;
}
