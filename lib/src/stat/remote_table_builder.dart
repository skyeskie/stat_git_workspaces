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

typedef RemoteFormatCallback<T> = AnsiText Function(
  GitRemote? remote,
  T? results, {
  AnsiColor noRemoteColoring,
});

class RemoteTableBuilder<T> extends TableBuilder<RemoteHeader, T> {
  RemoteTableBuilder({this.formatRemote = formatRemoteStatus});

  @override
  List<RemoteHeader> get enumCols => RemoteHeader.values;

  final RemoteFormatCallback<T> formatRemote;

  static const AnsiColor defaultNoRemoteColoring = AnsiColor.red;

  @override
  Future<AnsiText> addGitRow({
    required RemoteHeader header,
    required GitRepo gitRepo,
    T? results,
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
        RemoteHeader.backupRepo => formatRemote(await gitRepo.backup, results),
        RemoteHeader.originRepo => formatRemote(await gitRepo.origin, results),
        RemoteHeader.upstreamRepo => formatRemote(
            await gitRepo.upstream,
            results,
            noRemoteColoring: AnsiColor.grey,
          ),
      };

  static AnsiText formatRemoteStatus(
    GitRemote? remote,
    void results, {
    AnsiColor noRemoteColoring = defaultNoRemoteColoring,
  }) {
    final errorOut = formatRemoteErrorConditions(
      remote,
      noRemoteColoring: noRemoteColoring,
    );
    if (errorOut != null) return errorOut;
    assert(remote != null); //Handled in errorOut

    return AnsiText(
      remote!.name,
      foregroundColor: AnsiColor.green,
    );
  }

  static AnsiText? formatRemoteErrorConditions(
    GitRemote? remote, {
    AnsiColor noRemoteColoring = defaultNoRemoteColoring,
    bool alignCenter = false,
  }) {
    if (remote == null) return getNoRemoteText(color: noRemoteColoring);

    if (remote.isError) {
      return AnsiText(
        remote.error ?? 'Unknown error',
        foregroundColor: AnsiColor.red,
        alignment:
            alignCenter ? AnsiTextAlignment.center : AnsiTextAlignment.left,
      );
    }

    return null;
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
