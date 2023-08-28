import 'package:ansix/ansix.dart';
import 'package:stat_git_workspaces/src/core/git_remote.dart';
import 'package:stat_git_workspaces/src/core/table_builder.dart';

import '../core/dir_stat.dart';

enum RemoteHeader implements TableHeaderEnum {
  repoName('Repository'),
  branch('Branch'),
  backupRepo('Backup'),
  originRepo('Origin'),
  upstreamRepo('Upstream'),
  // otherRemotes('Remotes'),
  ;

  const RemoteHeader(this.desc);

  @override
  final String desc;
}

typedef RemoteFormatCallback = AnsiText Function(
  GitRemote? remote, {
  AnsiColor noRemoteColoring,
});

class RemoteTableBuilder extends TableBuilder<RemoteHeader, void> {
  RemoteTableBuilder({this.formatRemote = formatRemoteStatus});

  @override
  List<RemoteHeader> get enumCols => RemoteHeader.values;

  final RemoteFormatCallback formatRemote;

  static const AnsiColor defaultNoRemoteColoring = AnsiColor.red;

  @override
  Future<AnsiText> addGitRow({
    required RemoteHeader header,
    required GitRepo gitRepo,
    void results,
  }) async =>
      switch (header) {
        RemoteHeader.repoName => AnsiText(gitRepo.name),
        RemoteHeader.branch => AnsiText(await gitRepo.branch,
            foregroundColor: switch (await gitRepo.branch) {
              'mainline' => AnsiColor.greenYellow,
              'master' => AnsiColor.orange1,
              'main' => AnsiColor.greenYellow,
              'dev' => AnsiColor.green,
              _ => AnsiColor.cyan2,
            }),
        RemoteHeader.backupRepo => formatRemote(await gitRepo.backup),
        RemoteHeader.originRepo => formatRemote(await gitRepo.origin),
        RemoteHeader.upstreamRepo => formatRemote(
            await gitRepo.upstream,
            noRemoteColoring: AnsiColor.grey,
          ),
        // StatHeader.otherRemotes => AnsiText(
        //     (await gitRepo.remoteNames)
        //         .where(
        //           (element) => !['origin', 'nas', 'upstream'].contains(element),
        //         )
        //         .join(', '),
        //   ).replaceEmptyWith(blank),
      };

  static AnsiText formatRemoteStatus(
    GitRemote? remote, {
    AnsiColor noRemoteColoring = defaultNoRemoteColoring,
  }) {
    if (remote == null) return getNoRemoteText(color: noRemoteColoring);

    if (remote.isSync) {
      return AnsiText(
        remote.name,
        foregroundColor: AnsiColor.green,
        alignment: AnsiTextAlignment.center,
      );
    }

    return AnsiText(
      '${remote.behind} | ${remote.ahead}',
      foregroundColor: AnsiColor.orange1,
      alignment: AnsiTextAlignment.center,
    );
  }

  static AnsiText getNoRemoteText({
    String text = 'x',
    AnsiColor color = defaultNoRemoteColoring,
  }) =>
      AnsiText(
        text,
        foregroundColor: color,
        alignment: AnsiTextAlignment.center,
      );
}

extension BlankReplace on AnsiText {
  AnsiText replaceEmptyWith(AnsiText value) => text.isEmpty ? value : this;
}
