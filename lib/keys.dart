import 'package:hive/hive.dart';

String gmnkey = Hive.box('settingBox').get('geminiapikey', defaultValue: "AIzaSyCR80a7Gb4kSGd5rX9ingZhJKSw9b9hQgQ");
