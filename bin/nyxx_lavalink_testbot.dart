import "dart:io";

import 'package:nyxx_commander/commander.dart';
import "package:nyxx_lavalink/lavalink.dart";
import "package:nyxx/nyxx.dart";
import 'package:logging/logging.dart' show Level;

void main() async {
  final clientId = Snowflake("YOUR_CLIENT_ID_HERE");
  final client = Nyxx(Platform.environment["DISCORD_TOKEN"]!, GatewayIntents.all);
  final cluster = Cluster(client, clientId);

  client.onReady.listen((event) {
    print("Ready and connected");
  });

  // Add the nodes, you can add as many as you want
  await cluster.addNode(NodeOptions());

  cluster.onTrackStart.listen((event) async {
    final player = event.node.players[event.guildId];

    if (player == null) return;

    final nowPlaying = player.nowPlaying;

    if(nowPlaying == null) return;

    final channel = await event.client.fetchChannel<TextGuildChannel>(nowPlaying.channelId!);

    final embed = EmbedBuilder();

    embed.title = "Track started";
    embed.description = "Playing ${nowPlaying.track.info?.title} [<@${nowPlaying.requester!}>]";

    await channel.sendMessage(MessageBuilder.embed(embed));
  });

  Commander(client, prefix: '!')
    ..registerCommand('play', (context, message) async {
      if (context.guild == null) return;

      final node = cluster.getOrCreatePlayerNode(context.guild!.id);

      final splitted = message.split(" ");
      splitted.removeAt(0);
      final query = splitted.join(" ");

      final results = await node.autoSearch(query);

      if(results.tracks.isEmpty) {
        await context.sendMessage(MessageBuilder.content("No matches with $query"));
        return;
      }

      node.play(
          Snowflake(context.guild!.id),
          results.tracks[0],
          requester: context.author.id,
          channelId: context.channel.id
      ).queue();
    })
    ..registerCommand('join', (context, message) async {
      if (context.guild == null) return;

      final state = context.guild!.voiceStates.findOne((item) => item.user.id == context.author.id);

      if(state == null || state.channel == null) {
        await context.sendMessage(MessageBuilder.content("You need to be connected to a vc to use this command"));

        return;
      }

      final channel = await client.fetchChannel<VoiceGuildChannel>(state.channel!.id);

      channel.connect(selfDeafen: true);

      cluster.getOrCreatePlayerNode(context.guild!.id);
    })
    ..registerCommand('skip', (context, message) async {
      if (context.guild == null) return;

      final node = cluster.getOrCreatePlayerNode(context.guild!.id);

      node.skip(context.guild!.id);
    })
    ..registerCommand('nodes', (context, message) => print('${cluster.connectedNodes.length} connected nodes'))
    ..registerCommand("queue", (context, message) {
      if (context.guild == null) return;

      final node = cluster.getOrCreatePlayerNode(context.guild!.id);

      final player = node.players[context.guild!.id];

      if (player == null) return;

      print(player.queue);
    })
    ..registerCommand("leave", (context, message) async {
      if (context.guild == null) return;

      final state = context.guild!.voiceStates.findOne((item) => item.user.id == clientId);

      if(state == null || state.channel == null) {
        await context.sendMessage(MessageBuilder.content("I'm not connected to any voice channel"));

        return;
      }

      final channel = await client.fetchChannel<VoiceGuildChannel>(state.channel!.id);

      channel.disconnect();

      cluster.getOrCreatePlayerNode(context.guild!.id).destroy(context.guild!.id);
    })
    ..registerCommand("np", (context, message) async {
      if (context.guild == null) return;

      final node = cluster.getOrCreatePlayerNode(context.guild!.id);

      final player = node.players[context.guild!.id];

      if (player == null) return;

      if(player.nowPlaying == null) {
        await context.sendMessage(MessageBuilder.content("Queue clear"));
        return;
      }

      await context.sendMessage(
        MessageBuilder.content("Currently playing ${player.nowPlaying!.track.info?.title}")
      );
    });
}