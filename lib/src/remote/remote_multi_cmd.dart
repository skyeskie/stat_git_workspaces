import 'dart:async';

import 'package:ansix/ansix.dart';
import 'package:stat_git_workspaces/src/core/git_remote.dart';
import 'package:stat_git_workspaces/src/core/multi_command.dart';

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

abstract class RemoteMultiCmd<R> extends MultiCommand<RemoteHeader, R> {
  RemoteMultiCmd({super.addBatchOption, super.addDryRunOption});

  @override
  FutureOr<AnsiText> formatGitRepo({
    required RemoteHeader header,
    required GitRepo gitRepo,
    results,
  }) async =>
      switch (header) {
        RemoteHeader.repoName => formatRepoName(gitRepo.name),
        RemoteHeader.branch => formatBranchColumn(
            await gitRepo.branch,
            results,
          ),
        RemoteHeader.backupRepo => _formatRemote(
            await gitRepo.backup,
            results,
          ),
        RemoteHeader.originRepo => _formatRemote(
            await gitRepo.origin,
            results,
          ),
        RemoteHeader.upstreamRepo => _formatRemote(
            await gitRepo.upstream,
            results,
            noRemoteColoring: AnsiColor.grey,
          ),
      };

  @override
  List<RemoteHeader> get enumCols => RemoteHeader.values;

  AnsiText formatRepoName(String name) => AnsiText(name);

  FutureOr<AnsiText> formatBranchColumn(
    String branchName,
    R? results,
  ) async =>
      AnsiText(
        branchName,
        foregroundColor: switch (branchName) {
          'mainline' => AnsiColor.greenYellow,
          'master' => AnsiColor.orange1,
          'main' => AnsiColor.greenYellow,
          'dev' => AnsiColor.green,
          _ => AnsiColor.cyan2,
        },
      );

  FutureOr<AnsiText> _formatRemote(
    GitRemote? remote,
    R? results, {
    AnsiColor? noRemoteColoring,
    AnsiTextAlignment alignment = AnsiTextAlignment.center,
  }) {
    if (remote == null) {
      return AnsiText(
        '-',
        foregroundColor: noRemoteColoring ?? defaultNoRemoteColoring,
        alignment: alignment,
      );
    }

    if (remote.isError) {
      return AnsiText(
        remote.error ?? 'Unknown error',
        foregroundColor: AnsiColor.red,
        alignment: alignment,
      );
    }

    return formatRemoteColumn(remote, results);
  }

  AnsiColor get defaultNoRemoteColoring => AnsiColor.red;

  Future<AnsiText> formatRemoteColumn(GitRemote remote, R? results);
}
