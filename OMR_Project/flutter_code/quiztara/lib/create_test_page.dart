import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'test_details_page.dart';

class CreateTestPage extends StatefulWidget {
  final String userId; 

  CreateTestPage({required this.userId});

  @override
  _CreateTestPageState createState() => _CreateTestPageState();
}

class _CreateTestPageState extends State<CreateTestPage> {
  final TextEditingController _testNameController = TextEditingController();
  String? _selectedQuestionCount;
  DateTime? _selectedDate;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? errorMessage;
  bool isLoading = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<bool> _isTestNameExists(String testName) async {
    final querySnapshot = await _firestore
        .collection('tests')
        .where('quizname', isEqualTo: testName)
        .where('creatorId',
            isEqualTo:
                widget.userId) 
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  Future<void> _saveTestDetails() async {
    if (_testNameController.text.isEmpty ||
        _selectedDate == null ||
        _selectedQuestionCount == null) {
      setState(() {
        errorMessage = 'Lütfen tüm alanları doldurun.';
      });
      return;
    }

    bool testExists = await _isTestNameExists(_testNameController.text.trim());
    if (testExists) {
      setState(() {
        errorMessage = 'Quiz adı zaten mevcut. Lütfen başka bir ad seçin.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await _firestore.collection('tests').add({
        'quizname': _testNameController.text.trim(),
        'quizdate': _selectedDate,
        'questions': int.parse(_selectedQuestionCount!),
        'created_at': Timestamp.now(),
        'creatorId': widget.userId, 
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quiz Başarıyla Oluşturuldu!')),
      );

      setState(() {
        isLoading = false;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TestDetailsPage(userId: widget.userId),
        ),
      );
    } catch (e) {
      setState(() {
        errorMessage = 'Quiz oluşturulamadı. Lütfen tekrar deneyin.';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz Oluştur', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.purple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _testNameController,
              decoration: InputDecoration(
                labelText: 'Quiz Adı giriniz',
                prefixIcon: Icon(Icons.title, color: Colors.purple),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              _selectedDate == null
                  ? 'Quiz Tarihini Seçiniz'
                  : 'Quiz Date: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _selectDate(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(19),
                ),
              ),
              child:
                  Text('Tarih Seçiniz', style: TextStyle(color: Colors.white)),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Sorular Sayısı',
                prefixIcon: Icon(Icons.question_answer, color: Colors.purple),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: ['5', '10', '20'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              value: _selectedQuestionCount,
              onChanged: (value) {
                setState(() {
                  _selectedQuestionCount = value;
                });
              },
            ),
            SizedBox(height: 20),
            if (errorMessage != null)
              Text(
                errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            SizedBox(height: 20),
            if (isLoading)
              Center(child: CircularProgressIndicator())
            else
              ElevatedButton.icon(
                onPressed: _saveTestDetails,
                icon: Icon(Icons.add, color: Colors.white),
                label:
                    Text('Quiz Oluştur', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
