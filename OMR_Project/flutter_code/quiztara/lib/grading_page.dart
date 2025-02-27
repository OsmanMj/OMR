import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';

class GradingPage extends StatefulWidget {
  final String quizId;
  final String userId;

  GradingPage({
    required this.quizId,
    required this.userId,
  });

  @override
  _GradingPageState createState() => _GradingPageState();
}

class _GradingPageState extends State<GradingPage> {
  late CameraController _cameraController;
  bool _isCameraInitialized = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _results = [];
  List<int>? _correctAnswers;
  final String _serverUrl = "http://192.168.43.74:8000/process_image";
  TextEditingController _studentNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _fetchCorrectAnswers();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      _cameraController = CameraController(cameras[0], ResolutionPreset.medium);
      await _cameraController.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No camera found!')),
      );
    }
  }

  Future<void> _fetchCorrectAnswers() async {
    try {
      final quizDoc =
          await _firestore.collection('tests').doc(widget.quizId).get();
      if (quizDoc.exists) {
        setState(() {
          _correctAnswers = List<int>.from(quizDoc['answerKey']);
        });
      } else {
        print("Quiz data not found!");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching correct answers: $e')),
      );
    }
  }

  Future<void> _captureAndSend() async {
    if (!_isCameraInitialized ||
        _correctAnswers == null ||
        _studentNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Lütfen öğrenci adını girin ve kamerayı başlatın!')),
      );
      return;
    }

    try {
      final XFile image = await _cameraController.takePicture();
      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}/graded_sheet_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await image.saveTo(filePath);

      final uri = Uri.parse(_serverUrl);
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('image', filePath));
      request.fields['answer_key'] = _correctAnswers!.join(',');
      request.fields['num_questions'] = _correctAnswers!.length.toString();

      final response = await request.send();

      if (response.statusCode == 200) {
        final jsonResponse = await response.stream.bytesToString();
        final resultData = jsonDecode(jsonResponse);

        if (resultData != null &&
            resultData.containsKey('selectedAnswers') &&
            resultData['selectedAnswers'] != null) {
          setState(() {
            _results.add({
              'studentName': _studentNameController.text.trim(),
              'score': resultData['score'],
              'totalQuestions': resultData['totalQuestions'],
              'imagePath': filePath,
              'markedImage': resultData['imageBase64'],
            });
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Puanlam Tamamlandı!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: Invalid response format')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing or sending image: $e')),
      );
    }
  }

  Future<void> exportToPDF() async {
    try {
      final pdf = pw.Document();

      double totalScore = 0;
      for (var result in _results) {
        totalScore += result['score'] / result['totalQuestions'] * 100;
      }
      double average = totalScore / _results.length;

      pdf.addPage(
        pw.Page(
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Text('Ögrenci adi soyadi',
                          style: pw.TextStyle(
                              fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Puan',
                          style: pw.TextStyle(
                              fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Yüzde',
                          style: pw.TextStyle(
                              fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  ..._results.map(
                    (result) => pw.TableRow(
                      children: [
                        pw.Text(result['studentName']),
                        pw.Text(
                            '${result['score']} / ${result['totalQuestions']}'),
                        pw.Text(
                          '%${(result['score'] / result['totalQuestions'] * 100).toStringAsFixed(2)}',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Align(
                alignment: pw.Alignment.bottomRight,
                child: pw.Text(
                  'Ortalama: %${average.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      final directory = await getExternalStorageDirectory();
      final filePath = '${directory!.path}/Souclar.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF başarıyla oluşturuldu: $filePath')),
      );

      OpenFile.open(filePath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF oluşturulurken hata: $e')),
      );
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Puanlama', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.purple,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _studentNameController,
                decoration: InputDecoration(
                  labelText: 'Öğrenci adı giriniz',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person, color: Colors.purple),
                ),
              ),
            ),
            if (_isCameraInitialized)
              AspectRatio(
                aspectRatio: _cameraController.value.aspectRatio,
                child: CameraPreview(_cameraController),
              )
            else
              Center(child: CircularProgressIndicator()),
            ElevatedButton(
              onPressed: _isCameraInitialized && _correctAnswers != null
                  ? _captureAndSend
                  : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              child: Text(
                "Çek ve Puanlandır",
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton.icon(
              onPressed: exportToPDF,
              icon: Icon(Icons.picture_as_pdf, color: Colors.white),
              label: Text(
                'Sonuçları PDF olarak aktar',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final result = _results[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      children: [
                        Text(
                          'Öğrenci: ${result['studentName']}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        Text(
                          'Alınan Puan: ${result['score']} / ${result['totalQuestions']}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        Text(
                          'Yüzde: ${(result['score'] / result['totalQuestions'] * 100).toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        if (result['markedImage'] != null)
                          Image.memory(
                            base64Decode(result['markedImage']),
                            height: 150,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
