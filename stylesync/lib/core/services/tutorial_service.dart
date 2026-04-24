import 'package:shared_preferences/shared_preferences.dart';

class TutorialService{
  static const String _tutorialKey = 'hasSeenTutorial';
  Future<bool> hasSeenTutorial() async{
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tutorialKey) ?? false;
  }

  Future<void> markTutorialAsSeen() async{
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(_tutorialKey, true);
  }
}