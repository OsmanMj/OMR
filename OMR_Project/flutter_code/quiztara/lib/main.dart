import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'register_page.dart';
import 'login_page.dart';
import 'home_screen.dart';
import 'grading_page.dart';
import 'answer_key_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(OMRGradingApp());
}

class OMRGradingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OMR Scan App',
      theme: ThemeData(primarySwatch: Colors.purple),
      initialRoute: '/register',
      routes: {
        '/register': (context) => RegisterPage(),
        '/login': (context) => LoginPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/home') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => HomeScreen(userId: args['userId']),
          );
        } else if (settings.name == '/grading_page') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => GradingPage(
              quizId: args['quizId'],
              userId: args['userId'],
            ),
          );
        } else if (settings.name == '/answer_key') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => AnswerKeyPage(
              numQuestions: args['numQuestions'],
              quizId: args['quizId'],
              userId: args['userId'],
            ),
          );
        }
        return null;
      },
    );
  }
}
