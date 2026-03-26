import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/transaction_model.dart';
import 'screens/main_shell.dart';
import 'theme/app_theme.dart';

final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier(ThemeMode.light);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(TransactionModelAdapter());
  await Hive.openBox<TransactionModel>('transactions');
  final settingsBox = await Hive.openBox('settings');
  final isDark = settingsBox.get('darkMode', defaultValue: false) as bool;
  themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Church Finance',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: AppTheme.light().copyWith(
            textTheme:
                GoogleFonts.interTextTheme(AppTheme.light().textTheme),
          ),
          darkTheme: AppTheme.dark().copyWith(
            textTheme:
                GoogleFonts.interTextTheme(AppTheme.dark().textTheme),
          ),
          home: const MainShell(),
        );
      },
    );
  }
}