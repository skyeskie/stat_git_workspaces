import 'dart:io';

import 'package:path/path.dart' as path;

import 'git_remote.dart';
import 'multi_command.dart';
import 'repo_info.dart';

class GitRepo extends DirStat {
  GitRepo({
    required this.root,
    this.mode = CommandMode.batch,
  }) : super.fromDirectory(root);

  final Directory root;
  final CommandMode mode;

  // ['status', '--porcelain=v2', '--show-stash', '--untracked-files=normal']

  @override
  String get name => path.basename(root.path);

  List<String>? _remotes;

  Future<List<String>> get remoteNames async {
    _remotes ??= await runGitCmd(['remote']);
    return _remotes!;
  }

  Future<String> get branch async {
    return (await runGitCmd(
      ['symbolic-ref', '--short', 'HEAD'],
    ))
        .single;
  }

  Future<GitRemote?> get origin => getRemoteInfo('origin');

  Future<GitRemote?> get backup => getRemoteInfo('nas');

  Future<GitRemote?> get upstream => getRemoteInfo('upstream');

  // General commands

  Future<GitRemote?> getRemoteInfo(String remoteName) async {
    final remotes = await remoteNames;
    if (!remotes.contains(remoteName)) return null;
    return GitRemote(name: remoteName, branch: 'TODO');
  }

  Future<List<String>> runGitCmd(List<String> command) => DirStat.runGitCmd(
        command,
        workingDirectory: root.path,
      );

  Future<String> runGitCmdSingle(List<String> command) =>
      runGitCmd(command).then(
        (value) => value.single.trim(),
      );
}
