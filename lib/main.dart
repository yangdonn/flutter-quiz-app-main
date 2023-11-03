import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

void main() {
  runApp(const MaterialApp(home: QuizApp()));
}

class QuizApp extends StatefulWidget {
  const QuizApp({Key? key}) : super(key: key);

  @override
  _QuizAppState createState() => _QuizAppState();
}

class _QuizAppState extends State<QuizApp> {
  int currentQuestion = 0;
  int score = 0;
  List<Map<String, dynamic>> questions = [];
  String? selectedAnswer;
  bool quizEnded = false;

  @override
  void initState() {
    super.initState();
    loadQuestionsFromDatabase();
  }

  void loadQuestionsFromDatabase() async {
    final database = await QuizDatabaseHelper.database;
    final questionsList = await database.query(QuizDatabaseHelper.tableName);
    setState(() {
      questions = questionsList;
    });
  }

  void checkAnswer() {
    if (selectedAnswer == questions[currentQuestion]['correctAnswer']) {
      setState(() {
        score++;
      });
    }
    if (currentQuestion < questions.length - 1) {
      setState(() {
        currentQuestion++;
        selectedAnswer = null;
      });
    } else {
      // Quiz finished, display results
      setState(() {
        quizEnded = true;
      });
    }
  }

  void resetQuiz() {
    setState(() {
      currentQuestion = 0;
      score = 0;
      selectedAnswer = null;
      quizEnded = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Quiz App'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: <Widget>[
              if (quizEnded)
                Text(
                  'Quiz has ended. Your score: $score out of ${questions.length}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                )
              else if (questions.isNotEmpty && currentQuestion < questions.length)
                Column(
                  children: <Widget>[
                    Text(
                      questions[currentQuestion]['question'],
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Column(
                      children: (questions[currentQuestion]['options'].split(',')).map<Widget>((option) {
                        return RadioListTile<String>(
                          title: Text(option),
                          value: option,
                          groupValue: selectedAnswer,
                          onChanged: (value) {
                            setState(() {
                              selectedAnswer = value;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        checkAnswer();
                      },
                      child: const Text('Next'),
                    ),
                  ],
                )
            ],
          ),
        ),
      ),
    );
  }
}

class QuizDatabaseHelper {
  static Database? _database;
  static const String tableName = 'quiz';

  // Define your database schema here
  static const String createTableQuery = '''
    CREATE TABLE $tableName (
      id INTEGER PRIMARY KEY,
      question TEXT,
      options TEXT,
      correctAnswer TEXT
    )
  ''';

  // Initialize the database
  static Future<Database> get database async {
    if (_database != null) return _database!;

    // If the database does not exist, create it
    _database = await openDatabase(
      path.join(await getDatabasesPath(), 'quiz_database.db'),
      onCreate: (db, version) {
        return db.execute(createTableQuery);
      },
      version: 1,
    );

    // Insert example questions into the database
    await _insertExampleQuestions(_database!);

    return _database!;
  }

  // Insert example questions into the database
  static Future<void> _insertExampleQuestions(Database db) async {
    final batch = db.batch();
    final exampleQuestions = [
      {
        'question': 'What is the capital of France?',
        'options': 'London,Madrid,Paris,Berlin',
        'correctAnswer': 'Paris',
      },
      {
        'question': 'What is the largest planet in our solar system?',
        'options': 'Earth,Mars,Jupiter,Venus',
        'correctAnswer': 'Jupiter',
      },
      {
        'question': 'Who is the Cr of 3IT?',
        'options': 'Ankieth,Dorji,Pema,Tsheten',
        'correctAnswer': 'Ankieth',
      },
      {
        'question': 'Which language does Flutter use?',
        'options': 'Python,Dart,Sharpshop,English',
        'correctAnswer': 'Dart',
      },
    ];

    for (final question in exampleQuestions) {
      batch.insert(tableName, question);
    }

    await batch.commit();
  }
}
