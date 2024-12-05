import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'create_project_page.dart';
import 'network_page.dart';
import 'notifications_page.dart';
import 'firebase_options.dart';
import 'project_grid_page.dart';
import 'project_detail_page.dart';
import 'profile_page.dart';
import 'splash_screen.dart'; // Importa el SplashScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InnoFund',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/', // Cambia la ruta inicial al SplashScreen
      onGenerateRoute: (settings) {
        if (settings.name == '/profile') {
          final String userId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) {
              return ProfilePage(userId: userId);
            },
          );
        }

        if (settings.name == '/project-detail') {
          final String postId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) {
              return ProjectDetailPage(postId: postId);
            },
          );
        }

        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
                builder: (context) => const SplashScreen()); // SplashScreen
          case '/login':
            return MaterialPageRoute(builder: (context) => const LoginPage());
          case '/register':
            return MaterialPageRoute(
                builder: (context) => const RegisterPage());
          case '/home':
            return MaterialPageRoute(builder: (context) => const HomePage());
          case '/create-project':
            return MaterialPageRoute(
                builder: (context) => const CreateProjectPage());
          case '/network':
            return MaterialPageRoute(builder: (context) => const NetworkPage());
          case '/notifications':
            return MaterialPageRoute(
                builder: (context) => const NotificationsPage());
          case '/projects':
            return MaterialPageRoute(
                builder: (context) => const ProjectGridPage());
          default:
            return null;
        }
      },
    );
  }
}
