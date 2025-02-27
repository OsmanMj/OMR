import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'answer_key_page.dart';

class TestDetailsPage extends StatefulWidget {
  final String userId;

  TestDetailsPage({required this.userId});

  @override
  _TestDetailsPageState createState() => _TestDetailsPageState();
}

class _TestDetailsPageState extends State<TestDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TextEditingController _searchController = TextEditingController();
  TextEditingController _editQuizNameController = TextEditingController();
  TextEditingController _editNumQuestionsController = TextEditingController();
  DateTime? _selectedEditDate;
  bool isLoading = false;

  String? _searchQuery;

  Future<bool> _isQuizNameExists(String newQuizName, String quizId) async {
    final querySnapshot = await _firestore
        .collection('tests')
        .where('quizname', isEqualTo: newQuizName)
        .get();
    return querySnapshot.docs.any((doc) => doc.id != quizId);
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quiz Ara',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Quiz adını giriniz...',
                    prefixIcon: Icon(Icons.search, color: Colors.purple),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.purple, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.purple, width: 2),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim();
                    });
                  },
                ),
                SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Kapat', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Quiz Detayları',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: _showSearchDialog,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('tests')
            .where('creatorId', isEqualTo: widget.userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          List<DocumentSnapshot> quizzes = snapshot.data!.docs;

          if (_searchQuery != null && _searchQuery!.isNotEmpty) {
            quizzes = quizzes.where((doc) {
              return doc['quizname']
                  .toString()
                  .toLowerCase()
                  .contains(_searchQuery!.toLowerCase());
            }).toList();
          }

          if (quizzes.isEmpty) {
            return Center(
              child: Text(
                'Henüz oluşturduğunuz bir quiz yok.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: quizzes.length,
            itemBuilder: (context, index) {
              var quiz = quizzes[index];
              var quizId = quiz.id;
              var quizName = quiz['quizname'];
              var quizDate = (quiz['quizdate'] as Timestamp).toDate();
              var numQuestions = quiz['questions'];

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 4,
                color: Color.fromARGB(255, 245, 245, 245),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(color: Colors.purple.shade100, width: 1),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  title: Text(
                    quizName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tarih: ${quizDate.toLocal()}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        'Sorular: $numQuestions',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AnswerKeyPage(
                          quizId: quizId,
                          numQuestions: numQuestions,
                          userId: widget.userId,
                        ),
                      ),
                    );
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.purple),
                        onPressed: () {
                          _showEditDialog(
                            context,
                            quizId,
                            quizName,
                            numQuestions,
                            quizDate,
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _confirmDeleteQuiz(quizId);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, String quizId,
      String quizName, int numQuestions, DateTime quizDate) async {
    _editQuizNameController.text = quizName;
    _editNumQuestionsController.text = numQuestions.toString();
    _selectedEditDate = quizDate;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Quiz Düzenle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _editQuizNameController,
                  decoration: InputDecoration(
                    labelText: 'Quiz adı',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _editNumQuestionsController,
                  decoration: InputDecoration(
                    labelText: 'Sorular Sayısı',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _selectedEditDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        _selectedEditDate = pickedDate;
                      });
                    }
                  },
                  child: Text(_selectedEditDate != null
                      ? 'Selected Date: ${_selectedEditDate!.toLocal()}'
                      : 'Select Date'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'İptal et',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final newQuizName = _editQuizNameController.text.trim();
                final newNumQuestions = _editNumQuestionsController.text.trim();

                if (newQuizName.isNotEmpty &&
                    newNumQuestions.isNotEmpty &&
                    _selectedEditDate != null) {
                  bool isDuplicate =
                      await _isQuizNameExists(newQuizName, quizId);
                  if (isDuplicate) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Bu isimde bir quiz zaten var. Lütfen farklı bir isim seçin.')),
                    );
                    return;
                  }

                  try {
                    await _firestore.collection('tests').doc(quizId).update({
                      'quizname': newQuizName,
                      'questions': int.parse(newNumQuestions),
                      'quizdate': _selectedEditDate,
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Quiz başarıyla güncellendi!')),
                    );
                    Navigator.of(context).pop();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Quiz güncellenirken hata oluştu.')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lütfen tüm alanları doldurun.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
              ),
              child: Text(
                'kaydet',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteQuiz(String quizId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Quiz sil'),
        content: Text('Bu quiz silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('İptal et', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteQuiz(quizId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              'Sil',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteQuiz(String quizId) async {
    setState(() {
      isLoading = true;
    });

    try {
      await _firestore.collection('tests').doc(quizId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quiz başarıyla silindi!')),
      );

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quiz silinemedi. Lütfen tekrar deneyin.')),
      );
    }
  }
}
