import 'package:flutter/material.dart';

class AppDimensions {
  AppDimensions._();

  // Margins & Paddings
  static const double marginHorizontal = 20.0;
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 20.0;
  static const double spaceXl = 24.0;
  static const double spaceXxl = 32.0;

  // Corner Radii
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusButton = 14.0;
  static const double radiusCallout = 16.0;
  static const double radiusCard = 20.0;
  static const double radiusModal = 24.0;
  static const double radiusFull = 999.0;

  // Component Heights
  static const double buttonHeight = 54.0;
  static const double headerBarHeight = 56.0;
  static const double mascotIconSize = 40.0;
  static const double timingBarHeight = 28.0;
  static const double timingBarNeedleHeight = 36.0;
  static const double timingBarNeedleWidth = 10.0;

  // Box Shadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.03),
      blurRadius: 20,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Color.fromRGBO(242, 106, 27, 0.25),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];
}
