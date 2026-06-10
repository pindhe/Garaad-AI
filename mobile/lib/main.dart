import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/auth_provider.dart';
import 'core/router/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MacallinApp());
}

class MacallinApp extends StatelessWidget {
  const MacallinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider()..init(),
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.loading) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              home: const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          return MaterialApp(
            title: 'MacallinAI',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ThemeMode.system,
            onGenerateRoute: AppRouter.generateRoute,
            initialRoute: auth.isAuthenticated ? '/home' : '/',
          );
        },
      ),
    );
  }
}
