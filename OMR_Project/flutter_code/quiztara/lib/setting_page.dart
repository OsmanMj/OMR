import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingPage extends StatefulWidget {
  final String userId; 

  SettingPage({required this.userId});

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _logout() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Çıkış'),
          content: Text('Çıkış yapmak istediğinize emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); 
              },
              child: Text('iptal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false, 
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Başarıyla çıkış yapıldı.')),
                );
              },
              child: Text(
                'Çıkış',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Hakkında'),
          content: Text(
            'Bu uygulama OMR kağıtlarını tarayıp değerlendirmenizi sağlar. '
            '\nGeliştirici: OSMAN MOHAMED',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Tamam'),
            ),
          ],
        );
      },
    );
  }

  void _showInstructionsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Kullanım Talimatları'),
          content: Text(
            '1. Kamerayı kullanırken odanın yeterince aydınlık olduğundan emin olun.\n'
            '2. Fotoğraf çekerken kağıdı düz ve net bir şekilde hizalayın.\n'
            '3. Cevapların olduğu bölgedeki kareye odaklanmaya dikkat edin.\n'
            '4. Cevapları tararken kağıdı sabit tutmaya çalışın.\n'
            '5. Doğru bir tarama için uygulamanın yönergelerini takip edin.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Tamam'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ayarları',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.purple,
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          ListTile(
            title: Text('Çıkış'),
            leading: Icon(
              Icons.logout,
              color: Colors.red,
            ),
            onTap: _logout,
          ),
          Divider(),

          ListTile(
            title: Text('Hakkında'),
            leading: Icon(
              Icons.info,
              color: Colors.blue,
            ),
            onTap: _showAboutDialog,
          ),
          Divider(),

          ListTile(
            title: Text('Kullanım Talimatları'),
            leading: Icon(
              Icons.help_outline,
              color: Colors.green,
            ),
            onTap: _showInstructionsDialog,
          ),
          Divider(),

          ListTile(
            title: Text('Kullanıcı ID'),
            subtitle: Text(widget.userId),
            leading: Icon(
              Icons.person,
              color: Colors.purple,
            ),
          ),
        ],
      ),
    );
  }
}
