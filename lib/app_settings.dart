import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AppSettings extends ChangeNotifier {
  // singleton
  static final AppSettings _singleton = AppSettings._internal();
  factory AppSettings() => _singleton;
  AppSettings._internal();
  static AppSettings get instance => _singleton;

  //
  // Properties
  //
  var onBoardingCompleted = false;
  var collectCrashReports = true;

  int version = 0;

  String _pseudoId;
  String get pseudoId => _pseudoId;

  var debugLogLevel = 'v';

  void load(SharedPreferences pref) {
    onBoardingCompleted = pref.getBool("onBoardingCompleted") ?? false;

    collectCrashReports =
        pref.getBool("collectCrashReports") ?? collectCrashReports;

    version = pref.getInt("appSettingsVersion") ?? version;

    _pseudoId = pref.getString("pseudoId");
    if (_pseudoId == null) {
      _pseudoId = Uuid().v4();
      pref.setString("pseudoId", _pseudoId);
    }

    debugLogLevel = pref.getString("debugLogLevel") ?? debugLogLevel;
  }

  Future<void> save() async {
    var pref = await SharedPreferences.getInstance();
    var defaultSet = AppSettings._internal();

    pref.setBool("onBoardingCompleted", onBoardingCompleted);

    _setBool(pref, "collectCrashReports", collectCrashReports,
        defaultSet.collectCrashReports);

    _setString(pref, "debugLogLevel", debugLogLevel, defaultSet.debugLogLevel);

    pref.setInt("appSettingsVersion", version);

    notifyListeners();
  }

  Map<String, String> toMap() {
    return {
      "onBoardingCompleted": onBoardingCompleted.toString(),
      "collectCrashReports": collectCrashReports.toString(),
      "version": version.toString(),
      'pseudoId': pseudoId,
      'debugLogLevel': debugLogLevel,
    };
  }

  Future<void> _setString(
    SharedPreferences pref,
    String key,
    String value,
    String defaultValue,
  ) async {
    if (value == defaultValue) {
      await pref.remove(key);
    } else {
      await pref.setString(key, value);
    }
  }

  Future<void> _setBool(
    SharedPreferences pref,
    String key,
    bool value,
    bool defaultValue,
  ) async {
    if (value == defaultValue) {
      await pref.remove(key);
    } else {
      await pref.setBool(key, value);
    }
  }
}
