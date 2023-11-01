import "dart:io";
import 'dart:math';
import 'package:nyxx_commands/nyxx_commands.dart';
import "package:nyxx_lavalink/nyxx_lavalink.dart";
import "package:nyxx/nyxx.dart";
import 'package:logging/logging.dart' show Level, Logger;
import 'package:nyxx_lavalink_testbot/commands.dart';
import 'package:nyxx_lavalink_testbot/lavalink_logger.dart';
import 'package:nyxx_lavalink_testbot/music_service.dart';

void main() async {
  final client = NyxxFactory.createNyxxWebsocket(
      "",
      GatewayIntents.all
  );
  final commands = CommandsPlugin(
    prefix: mentionOr((_) => "!"),
    options: CommandsOptions(
      type: CommandType.textOnly
    )
  );

  Logger.root.level = Level.ALL;

  commands.addCommand(group);

  client
    ..registerPlugin(CliIntegration())
    ..registerPlugin(IgnoreExceptions())
    ..registerPlugin(LavalinkLogger())
    ..registerPlugin(commands);

  MusicService.init(client);

  client.eventsWs.onReady.listen((_) {
    print('Ready');
  });

  await client.connect();
}
