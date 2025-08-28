import 'package:hive/hive.dart';

String gmnkey = (Hive.box('settingBox').get('geminiapikey') as String?) ?? '';
