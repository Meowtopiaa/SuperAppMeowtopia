import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'features/auth/logic/auth_provider.dart';
import 'features/cat/logic/cat_provider.dart';
import 'features/cat_adoption/logic/adoption_provider.dart';
import 'features/cat_hunter/logic/cat_hunter_provider.dart';
import 'features/cat_identification/logic/identification_provider.dart';
import 'features/feeding_spot/logic/feeding_spot_provider.dart';
import 'features/incident_report/logic/incident_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CatProvider()),
        ChangeNotifierProvider(create: (_) => FeedingSpotProvider()),
        ChangeNotifierProvider(create: (_) => CatHunterProvider()),
        ChangeNotifierProvider(create: (_) => AdoptionProvider()),
        ChangeNotifierProvider(create: (_) => IncidentProvider()),
        ChangeNotifierProvider(create: (_) => IdentificationProvider()),
      ],
      child: const MeowtopiaApp(),
    ),
  );
}
