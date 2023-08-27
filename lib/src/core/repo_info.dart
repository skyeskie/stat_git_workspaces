import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:stat_git_workspaces/src/core/git_remote.dart';

sealed class DirStat {
  DirStat({required this.name});

  final String name;

  static Future<List<String>> runGitCmd(
    List<String> command, {
    required String workingDirectory,
  }) async {
    final cmd = await Process.start(
      'git',
      command,
      workingDirectory: workingDirectory,
    );

    final exitCode = await cmd.exitCode;

    if (exitCode != 0) {
      final error = await cmd.stderr
          .transform(
            const SystemEncoding().decoder,
          )
          .join();
      return Future.error(error);
    }

    final result = await cmd.stdout
        .transform(
          const SystemEncoding().decoder,
        )
        .join();
    return result.trim().split('\r?\n');
  }

  static Future<bool> checkIfGitDir(String workingDirectory) async {
    return runGitCmd(
      ['rev-parse', '--show-toplevel'],
      workingDirectory: workingDirectory,
    ).then(
      (topLevel) => path.equals(
        topLevel.single.trim(),
        workingDirectory,
      ),
      onError: (error) => error.toString().contains('not a git repository')
          ? false
          : Future.error(error),
    );
  }
}

class NonGitRepo extends DirStat {
  NonGitRepo({required super.name});
}

@Deprecated('Use GitRepo')
class GitRepoInfo extends DirStat {
  GitRepoInfo({
    required super.name,
    required this.branch,
    this.origin,
    this.backup,
    this.upstream,
    this.remoteNames = const [],
  });

  String branch;
  GitRemote? origin;
  GitRemote? backup;
  GitRemote? upstream;
  List<String> remoteNames;
}
