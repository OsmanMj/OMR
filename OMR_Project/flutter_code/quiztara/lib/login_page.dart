import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart'; // استيراد مكتبة التشفير

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? errorMessage;
  bool isLoading = false;

  // دالة لتشفير كلمة المرور
  String _encryptPassword(String password) {
    final bytes = utf8.encode(password); // تحويل النص إلى بايت
    final hashed = sha256.convert(bytes); // تطبيق SHA-256
    return hashed.toString();
  }

  // وظيفة تسجيل الدخول
  Future<void> _loginUser() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        errorMessage = 'Lütfen tüm alanları doldurun.';
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      QuerySnapshot result = await _firestore
          .collection('users')
          .where('username', isEqualTo: _usernameController.text.trim())
          .get();

      if (result.docs.isNotEmpty) {
        var userDoc = result.docs.first.data() as Map<String, dynamic>;
        final encryptedInputPassword = _encryptPassword(
            _passwordController.text.trim()); // تشفير كلمة المرور المدخلة

        if (userDoc['password'] == encryptedInputPassword) {
          setState(() {
            errorMessage = null;
            isLoading = false;
          });

          // الانتقال إلى الصفحة الرئيسية مع تمرير userId
          Navigator.of(context).pushReplacementNamed(
            '/home',
            arguments: {'userId': _usernameController.text.trim()},
          );
        } else {
          setState(() {
            errorMessage = 'Şifre yanlış. Lütfen tekrar deneyin.';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Kullanıcı adı bulunamadı. Lütfen tekrar deneyin.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Giriş sırasında bir hata oluştu: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Giriş yap', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.purple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Kullanıcı adı',
                prefixIcon: Icon(Icons.person, color: Colors.purple),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Şifre',
                prefixIcon: Icon(Icons.lock, color: Colors.purple),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 16),
            if (errorMessage != null)
              Text(
                errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            SizedBox(height: 16),
            if (isLoading)
              CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _loginUser,
                child: Text('Giriş yap', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              ),
          ],
        ),
      ),
    );
  }
}
