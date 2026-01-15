import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roof_claim_progress_tracker_sqlite/screens/claims_list_screen.dart';
import 'package:roof_claim_progress_tracker_sqlite/viewmodels/claims_list_viewmodel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provide the ClaimsListViewModel at the app level
        // This ensures it persists across navigation
        ChangeNotifierProvider(create: (_) => ClaimsListViewModel()),
      ],
      child: MaterialApp(
        title: 'Roof Claim Progress Tracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        home: const ClaimsListScreen(),
      ),
    );
  }
}
