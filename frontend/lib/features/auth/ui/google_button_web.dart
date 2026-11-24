import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as google;

Widget buildGoogleWebButton(double width) => google.renderButton(
      configuration: google.GSIButtonConfiguration(
        theme: google.GSIButtonTheme.outline,
        size: google.GSIButtonSize.large,
        text: google.GSIButtonText.continueWith,
        shape: google.GSIButtonShape.rectangular,
        logoAlignment: google.GSIButtonLogoAlignment.center,
        minimumWidth: width.clamp(1.0, 400.0).toDouble(),
        locale: 'id',
      ),
    );
