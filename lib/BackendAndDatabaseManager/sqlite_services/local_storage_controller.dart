import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'package:generation/BackendAndDatabaseManager/Dataset/data_type.dart';

class LocalStorageHelper {
  // Database Columns
  final String _colMessages = "Messages";
  final String _colReferences = "Reference";
  final String _colMediaType = "Media";
  final String _colDate = "Date";
  final String _colTime = "Time";
  final String _colAbout = "About";
  final String _colProfileImageUrl = "DP_Url";
  final String _colEmail = "Email";
  final String _colToken = "Token";

  final String _colActivity = 'Status';
  final String _colTimeActivity = 'Status_Time';
  final String _colExtraText = 'ExtraActivityText';
  final String _colBgInformation = 'Bg_Information';

  final String _allImportantDataStore = '__ImportantDataTable__';
  final String _colAccountUserName = 'User_Name';
  final String _colAccountUserMail = 'User_Mail';

  final String _colActivitySpecial = 'ActivitySpecialOptions';

  final String _allRemainingLinksToDeleteFromFirebaseStorage =
      '__RemainingLinksToDelete__';
  final String _colLinks = 'New_Link';

  /// Create Singleton Objects(Only Created once in the whole application)
  static LocalStorageHelper _localStorageHelper;
  static Database _database;

  /// Instantiate the obj
  LocalStorageHelper._createInstance();

  /// For access Singleton object
  factory LocalStorageHelper() {
    if (_localStorageHelper == null)
      _localStorageHelper = LocalStorageHelper._createInstance();
    return _localStorageHelper;
  }

  Future<Database> get database async {
    if (_database == null) _database = await initializeDatabase();
    return _database;
  }

  /// For make a database
  Future<Database> initializeDatabase() async {
    /// Get the directory path to store the database

    final Directory directory = await getExternalStorageDirectory();
    print('Directory Path: ${directory.path}');

    final Directory newDirectory =
        await Directory(directory.path + '/.Databases/').create();
    final String path = newDirectory.path + '/generation_local_storage.db';

    // create the database
    final Database getDatabase = await openDatabase(path, version: 1);
    return getDatabase;
  }

  Future<void> createTableForStorePrimaryData() async {
    Database db = await this.database;
    try {
      await db.execute(
          "CREATE TABLE $_allImportantDataStore($_colAccountUserName TEXT PRIMARY KEY, $_colAccountUserMail TEXT, $_colToken TEXT)");
    } catch (e) {
      print(
          "Error in Local Storage Create Table For Store Primary Data: ${e.toString()}");
    }
  }

  Future<void> insertDataForThisAccount(
      {@required String userName,
      @required String userMail,
      @required String userToken}) async {
    Database db = await this.database;
    Map<String, dynamic> _accountData = Map<String, dynamic>();

    _accountData[_colAccountUserName] = userName;
    _accountData[_colAccountUserMail] = userMail;
    _accountData[_colToken] = userToken;

    await db.insert(_allImportantDataStore, _accountData);
  }

  Future<String> extractImportantDataFromThatAccount(
      {String userName = '', String userMail = ''}) async {
    Database db = await this.database;

    List<Map<String, Object>> result = [];

    if (userMail != '')
      result = await db.rawQuery(
          "SELECT $_colAccountUserName FROM $_allImportantDataStore WHERE $_colAccountUserMail = '$userMail'");
    else
      result = await db.rawQuery(
          "SELECT $_colAccountUserMail FROM $_allImportantDataStore WHERE $_colAccountUserName = '$userName'");

    return result[0].values.first;
  }

  Future<String> extractToken(
      {String userMail = '', String userName = ''}) async {
    final Database db = await this.database;

    List<Map<String, Object>> result;

    if (userMail != '')
      result = await db.rawQuery(
          "SELECT $_colToken FROM $_allImportantDataStore WHERE $_colAccountUserMail = '$userMail'");
    else
      result = await db.rawQuery(
          "SELECT $_colToken FROM $_allImportantDataStore WHERE $_colAccountUserName = '$userName'");

    return result[0].values.first;
  }

  Future<List<Map<String, Object>>> extractAllUsersName(
      {bool thisAccountAllowed = false}) async {
    Database db = await this.database;
    List<Map<String, Object>> result;

    if (!thisAccountAllowed)
      result = await db.rawQuery(
          "SELECT $_colAccountUserName FROM $_allImportantDataStore WHERE $_colAccountUserMail != '${FirebaseAuth.instance.currentUser.email}'");
    else
      result = await db
          .rawQuery("SELECT $_colAccountUserName FROM $_allImportantDataStore");
    return result;
  }

  /// For make a table
  Future<bool> createTableForUserName(String tableName) async {
    Database db = await this.database;
    try {
      await db.execute(
          "CREATE TABLE $tableName($_colMessages TEXT, $_colReferences INTEGER, $_colMediaType TEXT, $_colDate TEXT, $_colTime TEXT, $_colAbout TEXT, $_colProfileImageUrl TEXT, $_colEmail TEXT)");
      return true;
    } catch (e) {
      print(
          "Error in Local Storage Create Table For User Name: ${e.toString()}");
      return false;
    }
  }

  /// For Make Table for Status
  Future<bool> createTableForUserActivity(String tableName) async {
    final Database db = await this.database;
    try {
      await db.execute(
          "CREATE TABLE ${tableName}_status($_colActivity TEXT, $_colTimeActivity TEXT, $_colMediaType TEXT, $_colExtraText TEXT, $_colBgInformation TEXT, $_colActivitySpecial TEXT)");
      return true;
    } catch (e) {
      print("Error in Local Storage Create Table For Status: ${e.toString()}");
      return false;
    }
  }

  /// Insert ActivityData to Activity Table
  Future<void> insertDataInUserActivityTable(
      {@required String tableName,
      @required String statusLinkOrString,
      MediaTypes mediaTypes,
      @required String activityTime,
      ActivitySpecialOptions activitySpecialOptions,
      String extraText = '',
      String bgInformation = ''}) async {
    final Database db = await this.database;
    final Map<String, dynamic> _activityStoreMap = Map<String, dynamic>();

    _activityStoreMap[_colActivity] = statusLinkOrString;
    _activityStoreMap[_colTimeActivity] = activityTime;
    _activityStoreMap[_colMediaType] =
        mediaTypes == null ? '' : mediaTypes.toString();
    _activityStoreMap[_colExtraText] = extraText;
    _activityStoreMap[_colBgInformation] = bgInformation;
    _activityStoreMap[_colActivitySpecial] =
        activitySpecialOptions == null ? '' : activitySpecialOptions.toString();

    /// Result Insert to DB
    await db.insert('${tableName}_status', _activityStoreMap);
  }

  /// Extract Status from Table Name
  Future<List<Map<String, dynamic>>> extractActivityForParticularUserName(
      String tableName) async {
    try {
      final Database db = await this.database;
      final List<Map<String, Object>> tables =
          await db.rawQuery("SELECT * FROM ${tableName}_status");
      return tables;
    } catch (e) {
      print('Extract USer Name Activity Exception: ${e.toString()}');
      return null;
    }
  }

  /// Delete Particular Activity record From Activity Container
  Future<void> deleteParticularActivity(
      {@required String tableName, @required String activity}) async {
    try {
      final Database db = await this.database;

      print('Here in Delete Particular Activity: $tableName   $activity');

      final int result = await db.rawDelete(
          "DELETE FROM ${tableName}_status WHERE $_colActivity = '$activity'");

      print('Deletion Result: $result');
    } catch (e) {
      print('Delete Activity From Database Error: ${e.toString()}');
    }
  }

  /// Update Particular Activity
  Future<void> updateTableActivity(
      {@required String tableName,
      @required String oldActivity,
      @required String newAddition}) async {
    try {
      final Database db = await this.database;

      final int _updateResult = await db.rawUpdate(
          "UPDATE ${tableName}_status SET $_colActivity = '$oldActivity[[[question]]]$newAddition' WHERE $_colActivity = '$oldActivity'");

      print('Update Result is: $_updateResult');
    } catch (e) {
      print('Update Table Activity Error: ${e.toString()}');
    }
  }

  /// For Debugging Purpose
  Future<void> showParticularUserAllActivity(
      {@required String tableName}) async {
    try {
      final Database db = await this.database;
      var take = await db.rawQuery("SELECT * FROM ${tableName}_status");

      print('All Activity: $take');
    } catch (e) {
      print('showParticularUserAllActivity Error: ${e.toString()}');
    }
  }

  /// Count Total Statuses for particular Table Name
  Future<int> countTotalActivitiesForParticularUserName(
      String tableName) async {
    final Database db = await this.database;
    final List<Map<String, Object>> countTotalStatus =
        await db.rawQuery('SELECT COUNT(*) FROM ${tableName}_status');

    return countTotalStatus[0].values.first;
  }

  /// Count total Messages for particular Table Name
  Future<int> _countTotalMessagesUnderATable(String _tableName) async {
    final Database db = await this.database;

    final List<Map<String, Object>> countTotalMessagesWithOneAdditionalData =
        await db.rawQuery('SELECT COUNT(*) FROM $_tableName');

    return countTotalMessagesWithOneAdditionalData[0].values.first;
  }

  /// Insert Use Additional Data to Table
  Future<int> insertAdditionalData(
      String _tableName, String _about, String _email) async {
    Database db = await this.database; // DB Reference
    Map<String, dynamic> _helperMap =
        Map<String, dynamic>(); // Map to insert data

    // Insert Data to Map
    _helperMap[_colMessages] = "";
    _helperMap[_colReferences] = -1;
    _helperMap[_colMediaType] = "";
    _helperMap[_colDate] = "";
    _helperMap[_colTime] = "";
    _helperMap[_colAbout] = _about;
    _helperMap[_colProfileImageUrl] = "";
    _helperMap[_colEmail] = _email;

    /// Result Insert to DB
    var result = await db.insert(_tableName, _helperMap);
    return result;
  }

  /// Insert New Messages to Table
  Future<int> insertNewMessages(String _tableName, String _newMessage,
      MediaTypes _currMediaType, int _ref, String _time) async {
    Database db = await this.database; // DB Reference
    Map<String, dynamic> _helperMap =
        Map<String, dynamic>(); // Map to insert data

    /// Current Date
    DateTime now = DateTime.now();
    DateFormat formatter = DateFormat('yyyy-MM-dd');
    String _dateIS = formatter.format(now);

    /// Insert Data to Map
    _helperMap[_colMessages] = _newMessage;
    _helperMap[_colReferences] = _ref;
    _helperMap[_colMediaType] = _currMediaType.toString();
    _helperMap[_colDate] = _dateIS;
    _helperMap[_colTime] = _time;
    _helperMap[_colAbout] = "";
    _helperMap[_colProfileImageUrl] = "";
    _helperMap[_colEmail] = "";

    /// Result Insert to DB
    var result = await db.insert(_tableName, _helperMap);
    print(result);

    return result;
  }

  /// Extract Message from table
  Future<List<Map<String, dynamic>>> extractMessageData(
      String _tableName) async {
    Database db = await this.database; // DB Reference

    final List<Map<String, Object>> result = await db.rawQuery(
        'SELECT $_colMessages, $_colTime, $_colReferences, $_colMediaType FROM $_tableName WHERE $_colReferences != -1');

    return result;
  }

  /// Delete Particular Message
  Future<bool> deleteChatMessage(String _tableName,
      {@required String message,
      @required String time,
      @required int reference,
      @required String mediaType}) async {
    try {
      final Database db = await this.database;

      print('Message: $message');
      print('Time: $time');
      print('Reference: $reference');
      print('MediaType: $mediaType');

      final int result = await db.rawDelete(
          "DELETE FROM $_tableName WHERE $_colMessages = '$message' AND $_colTime = '$time' AND $_colReferences = $reference AND $_colMediaType = '$mediaType'");

      if (result == 0) {
        var take = await extractMessageData(_tableName);
        print('Messages: $take');
        return false;
      } else {
        print('Delete From Chat Message Result: $result');
        return true;
      }
    } catch (e) {
      print('Delete From Chat Message Error: ${e.toString()}');
      return false;
    }
  }

  /// Fetch Latest Message
  Future<Map<String, String>> fetchLatestMessage(String _tableName) async {
    final Database db = await this.database;

    final int totalMessages = await _countTotalMessagesUnderATable(_tableName);

    if (totalMessages == 1) return null;

    final List<Map<String, Object>> result =
        await db.transaction<List<Map<String, Object>>>((txn) {
      print('txn: $txn');
      return txn.rawQuery(
          "SELECT $_colMessages, $_colMediaType, $_colTime FROM $_tableName LIMIT 1 OFFSET ${totalMessages - 1}");
    });

    final String _time = result[0][_colTime].toString().split('+')[0];

    final Map<String, String> map = Map<String, String>();

    map.addAll({
      result[0][_colMessages]: '$_time+${result[0][_colMediaType]}+localDb',
    });

    print('Map is: $map');

    return map;
  }

  Future<void> createTableForRemainingLinks() async {
    final Database db = await this.database;

    await db.transaction((txn) async {
      return await txn.rawQuery(
          'CREATE TABLE $_allRemainingLinksToDeleteFromFirebaseStorage($_colLinks TEXT, $_colTime TEXT)');
    });
  }

  Future<void> insertNewLinkInLinkRemainingTable(
      {@required String link}) async {
    try {
      final Database db = await this.database;

      final Map<String, String> map = Map<String, String>();
      map[_colLinks] = link;
      map[_colTime] = DateTime.now().toString();

      await db.transaction((txn) async {
        return await txn.insert(
            _allRemainingLinksToDeleteFromFirebaseStorage, map);
      });
    } catch (e) {
      print('Insert Remaining Links Error: ${e.toString()}');
      await createTableForRemainingLinks();
      await insertNewLinkInLinkRemainingTable(link: link);
    }
  }

  Future<Map<String, String>> extractRemainingLinks() async {
    try {
      final Database db = await this.database;

      final List<Map<String, Object>> result = await db.rawQuery(
          'SELECT * FROM $_allRemainingLinksToDeleteFromFirebaseStorage');

      final Map<String, String> map = Map<String, String>();

      result.forEach((everyResult) {
        map.addAll({
          everyResult[_colLinks].toString(): everyResult[_colTime].toString(),
        });
      });

      return map;
    } catch (e) {
      print('Extract Links Error: ${e.toString()}');
      return Map<String, String>();
    }
  }

  Future<void> deleteRemainingLinksFromLocalStore(
      {@required String link}) async {
    try {
      final Database db = await this.database;

      await db.rawDelete(
          "DELETE FROM $_allRemainingLinksToDeleteFromFirebaseStorage WHERE $_colLinks = '$link'");
    } catch (e) {
      print('Remaining Links Deletion Exception: ${e.toString()}');
    }
  }
}
