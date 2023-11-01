import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:nyxx_lavalink_testbot/music_service.dart';

ChatGroup group = ChatGroup(
  'music',
  'juan',
  children: [
    ChatCommand(
      'play',
      'plays',
      id('music-play', (IChatContext pcx, String query) async {
        await connectIfNeeded(pcx);
        var cx = pcx as MessageChatContext;
        final node = MusicService.instance.cluster.getOrCreatePlayerNode(cx.guild!.id);

        final results = await node.autoSearch(query);

        if(results.tracks.isEmpty) {
          await cx.channel.sendMessage(MessageBuilder.content("No matches with $query"));
          return;
        }

        node.play(
            Snowflake(cx.guild!.id),
            results.tracks[0],
            requester: cx.member!.id,
            channelId: cx.channel.id
        ).queue();
      })
    )
  ]
);


Future<void> connectIfNeeded(IChatContext context) async {
  final selfMember = await context.guild!.selfMember.getOrDownload();

  if ((selfMember.voiceState == null ||
      selfMember.voiceState!.channel == null) &&
      (context.member!.voiceState != null &&
          context.member!.voiceState!.channel != null)) {
    context.guild!.shard.changeVoiceState(
        context.guild!.id, context.member!.voiceState!.channel!.id,
        selfDeafen: true);
  }
}