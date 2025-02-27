import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'grading_page.dart';

class AnswerKeyPage extends StatefulWidget {
  final int numQuestions; // عدد الأسئلة
  final String quizId; // معرف الاختبار لتخزين الإجابات مع الاختبار
  final String userId; // معرف المستخدم

  AnswerKeyPage({
    required this.numQuestions,
    required this.quizId,
    required this.userId,
  });

  @override
  _AnswerKeyPageState createState() => _AnswerKeyPageState();
}

class _AnswerKeyPageState extends State<AnswerKeyPage> {
  late List<String?> _answers; // قائمة للإجابات
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _answers =
        List<String?>.filled(widget.numQuestions, null); // تهيئة قائمة الإجابات
  }

  // حفظ الإجابات في Firestore
  Future<void> _saveAnswers() async {
    if (_answers.contains(null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen tüm sorular için cevap giriniz.')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      List<int?> answerKeys = _answers.map((answer) {
        switch (answer) {
          case 'A':
            return 0;
          case 'B':
            return 1;
          case 'C':
            return 2;
          case 'D':
            return 3;
          default:
            return -1;
        }
      }).toList();

      await _firestore.collection('tests').doc(widget.quizId).update({
        'answerKey': answerKeys,
        'updatedBy': widget.userId, // تحديث بواسطة المستخدم الحالي
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cevap Anahtarı Başarıyla Kaydedildi.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cevap anahtarı kaydedilemedi: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // الانتقال إلى صفحة GradingPage مع الإجابات
  void _goToGradingPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GradingPage(
          quizId: widget.quizId,
          userId: widget.userId, // تمرير userId مع بيانات الاختبار
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cevap Anahtarı Oluşturma',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.purple,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: widget.numQuestions,
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(color: Colors.purple.shade100, width: 1),
                  ),
                  color: const Color.fromARGB(255, 245, 245, 245),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Soru ${index + 1}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: ['A', 'B', 'C', 'D'].map((option) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Radio<String>(
                                  value: option,
                                  groupValue: _answers[index],
                                  onChanged: (value) {
                                    setState(() {
                                      _answers[index] = value;
                                    });
                                  },
                                  activeColor: Colors.green,
                                ),
                                Text(
                                  option,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple[700],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: isLoading ? null : _saveAnswers,
              icon: Icon(Icons.save_alt_outlined, color: Colors.white),
              label: isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Cevapları Kaydet',
                      style: TextStyle(color: Colors.white),
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _goToGradingPage,
              icon: Icon(Icons.camera_alt_outlined, color: Colors.white),
              label: Text(
                'Kağıtları Tara',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
