import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mis_lab_4/models/exceptions/http_exception.dart';

class Exam with ChangeNotifier {
  final String? id;
  final String subjectName;
  final DateTime date;

  Exam({
    this.id,
    required this.subjectName,
    required this.date,
  });
}

class ExamsProvider with ChangeNotifier {
  List<Exam> _exams = [];
  final String authToken;
  final String userId;

  ExamsProvider(
      [this.authToken = "", this.userId = "", this._exams = const []]);

  List<Exam> get exams {
    return [..._exams];
  }

  Future<void> fetchExams() async {
    final Uri url = Uri.https(
      'finki-mis-default-rtdb.europe-west1.firebasedatabase.app',
      '/userExams/$userId.json',
      {
        "auth": authToken,
      },
    );

    try {
      final examsResponse = await http.get(url);
      final examsData = json.decode(examsResponse.body);
      final List<Exam> loadedExams = [];

      if (examsData != null) {
        final examsMap = examsData as Map<String, dynamic>;
        examsMap.forEach((examId, examData) {
          loadedExams.add(
            Exam(
              id: examId,
              subjectName: examData['subjectName'],
              date: DateTime.parse(examData['date']),
            ),
          );
        });
      }

      _exams = loadedExams;
      notifyListeners();
    } catch (err) {
      rethrow;
    }
  }

  Future<void> addExam(Exam exam) async {
    final Uri url = Uri.https(
      'finki-mis-default-rtdb.europe-west1.firebasedatabase.app',
      '/userExams/$userId.json',
      {
        "auth": authToken,
      },
    );

    try {
      final examResponse = await http.post(
        url,
        body: json.encode({
          'subjectName': exam.subjectName,
          'date': exam.date.toIso8601String(),
        }),
      );

      var examData = json.decode(examResponse.body);

      final newExam = Exam(
        id: examData['name'],
        subjectName: exam.subjectName,
        date: exam.date,
      );

      _exams.add(newExam);
      notifyListeners();
    } catch (err) {
      rethrow;
    }
  }

  Future<void> updateExam(String id, Exam editedExam) async {
    final int examIndex = _exams.indexWhere((exam) => exam.id == id);
    if (examIndex < 0) {
      throw HttpException('Exam index not found');
    }

    try {
      final Uri url = Uri.https(
        'finki-mis-default-rtdb.europe-west1.firebasedatabase.app',
        '/userExams/$userId.json/$id.json',
        {
          "auth": authToken,
        },
      );

      await http.patch(
        url,
        body: json.encode({
          'subjectName': editedExam.subjectName,
          'date': editedExam.date,
        }),
      );

      _exams[examIndex] = editedExam;
      notifyListeners();
    } catch (err) {
      rethrow;
    }
  }

  Future<void> deleteExam(String id) async {
    final Uri url = Uri.https(
      'finki-mis-default-rtdb.europe-west1.firebasedatabase.app',
      '/userExams/$userId.json/$id.json',
      {
        "auth": authToken,
      },
    );

    final existingExamIndex = _exams.indexWhere((exam) => exam.id == id);
    var existingExam = _exams[existingExamIndex];

    _exams.removeAt(existingExamIndex);
    notifyListeners();

    final response = await http.delete(
      url,
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
    );

    if (response.statusCode >= 400) {
      _exams.insert(existingExamIndex, existingExam);
      notifyListeners();
      throw HttpException('Error occured: could not delete exam.');
    }
  }

  Exam findById(String id) {
    return _exams.firstWhere((exam) => exam.id == id);
  }
}
