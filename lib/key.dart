import 'package:hive/hive.dart';

String gmnkey = Hive.box<String>('settingBox').get('geminiapikey') ?? '';