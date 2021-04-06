import 'dart:collection';

import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

class LocalStorageHelper {
  // Database Columns
  String _colMessages = "Messages";
  String _colReferences = "Reference";
  String _colDate = "Date";
  String _colTime = "Time";
  String _colNickName = "Nick_Name";
  String _colAbout = "About";
  String _colProfileImageUrl = "DP_Url";

  // Create Singleton Objects(Only Created once in the whole application)
  static LocalStorageHelper _localStorageHelper;
  static Database _database;

  // Instantiate the obj
  LocalStorageHelper._createInstance();

  // For access Singleton object
  factory LocalStorageHelper() {
    if (_localStorageHelper == null)
      _localStorageHelper = LocalStorageHelper._createInstance();
    return _localStorageHelper;
  }

  Future<Database> get database async {
    if (_database == null) _database = await initializeDatabase();
    return _database;
  }

  // For make a database
  Future<Database> initializeDatabase() async {
    // Get the directory path to store the database
    final String dbPath = await getDatabasesPath();
    final String path = dbPath + '/generation_local_storage.db';

    // create the database
    final Database getDatabase = await openDatabase(path, version: 1);
    return getDatabase;
  }

  // For make a table
  void createTable(String tableName) async {
    Database db = await this.database;
    try {
      await db.execute(
          "CREATE TABLE $tableName($_colMessages TEXT, $_colReferences INTEGER, $_colDate TEXT, $_colTime TEXT, $_colNickName TEXT, $_colAbout TEXT, $_colProfileImageUrl TEXT)");
    } catch (e) {
      print("Error in Local Storage: ${e.toString()}");
    }
  }

  // Insert Use Additional Data to Table
  Future<int> insertAdditionalData(
      String _tableName, String _nickName, String _about) async {
    Database db = await this.database; // DB Reference
    Map<String, dynamic> _helperMap =
        Map<String, dynamic>(); // Map to insert data

    // Current Date
    DateTime now = DateTime.now();
    DateFormat formatter = DateFormat('yyyy-MM-dd');
    String _dateIS = formatter.format(now);

    // Insert Data to Map
    _helperMap[_colMessages] = "";
    _helperMap[_colReferences] = -1;
    _helperMap[_colDate] = "";
    _helperMap[_colTime] = "";
    _helperMap[_colNickName] = _nickName;
    _helperMap[_colAbout] = _about;
    _helperMap[_colProfileImageUrl] = "";

    // Result Insert to DB
    var result = await db.insert(_tableName, _helperMap);
    return result;
  }

  // Insert New Messages to Table
  Future<int> insertNewMessages(
      String _tableName, String _newMessage, int _ref) async {
    Database db = await this.database; // DB Reference
    Map<String, dynamic> _helperMap =
        Map<String, dynamic>(); // Map to insert data

    // Current Date
    DateTime now = DateTime.now();
    DateFormat formatter = DateFormat('yyyy-MM-dd');
    String _dateIS = formatter.format(now);

    // Insert Data to Map
    _helperMap[_colMessages] = _newMessage;
    _helperMap[_colReferences] = _ref;
    _helperMap[_colDate] = _dateIS;
    _helperMap[_colTime] = '${DateTime.now().hour}: ${DateTime.now().minute}';
    _helperMap[_colNickName] = "";
    _helperMap[_colAbout] = "";
    _helperMap[_colProfileImageUrl] = "";

    // Result Insert to DB
    var result = await db.insert(_tableName, _helperMap);
    return result;
  }

  // Extract Connection Name from Table
  Future<List<Map<String, Object>>> extractAllTablesName() async {
    Database db = await this.database; // DB Reference
    List<Map<String, Object>> tables = await db.rawQuery(
        "SELECT tbl_name FROM sqlite_master WHERE tbl_name != 'android_metadata';");
    return tables;
  }

  // Extract Message from table
  Future<List<Map<String, dynamic>>> extractMessageData(
      String _tableName) async {
    Database db = await this.database; // DB Reference

    var result = db.rawQuery(
        'SELECT $_colMessages, $_colReferences, $_colTime FROM $_tableName');
    return result;
  }

  Stream<List<String>> extractTables() async* {
    Queue<String> allData = Queue<String>();

    List<Map<String, Object>> allTables =
        await LocalStorageHelper().extractAllTablesName();

    if (allTables.isNotEmpty) {
      allTables.forEach((element) {
        allData.addFirst(element.values.toList()[0].toString());
      });
    } else
      print("No Data Present");

    yield allData.toList();
  }
}