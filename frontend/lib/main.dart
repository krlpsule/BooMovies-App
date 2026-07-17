import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import '../services/user_manager.dart';
import '../screens/login_screen.dart';

void main() async {
 
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");


  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => UserManager())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kitap ve Film Uygulaması',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Uygulamanın başlangıç ekranı
      home: LoginScreen(),
    );
  }
}
