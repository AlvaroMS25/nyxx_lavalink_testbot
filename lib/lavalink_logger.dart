import 'dart:async';

import 'package:logging/logging.dart';
import 'package:nyxx/src/nyxx.dart';
import 'package:nyxx/src/plugin/plugin.dart';

class LavalinkLogger extends BasePlugin {
  @override
  FutureOr<void> onRegister(INyxx nyxx, Logger logger) {
    Logger.root.onRecord.listen((LogRecord rec) {
      if (rec.loggerName == "Lavalink") {
        print("[${rec.time}] [${rec.level.name}] [${rec.loggerName}] ${rec.message}");
      }
    });
  }
}