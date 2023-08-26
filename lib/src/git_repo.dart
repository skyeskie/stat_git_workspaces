import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:stat_git_workspaces/src/repo_info.dart';

import 'git_remote.dart';

class GitRepo {
  GitRepo({required this.root});

  final Directory root;

  void readGitCmd() {
    Process.start(
      'git',
      ['status', '--porcelain=v2', '--show-stash', '--untracked-files=normal'],
    );
  }

  Future<DirStat> getInfo() async {
    final isGit = await checkIfGitDir();
    if (!isGit) {
      return NonGitRepo(name: getRepoName());
    }
    return GitRepoInfo(
      name: getRepoName(),
      backup: await getRemoteInfo('nas'),
      origin: await getRemoteInfo('origin'),
      upstream: await getRemoteInfo('upstream'),
    );
  }

  String getRepoName() => path.basename(root.path);

  String? _gitTopLevel;

  Future<String> getRepoTopLevelPath() async {
    if (_gitTopLevel != null) return _gitTopLevel!;

    return runGitCmd(['rev-parse', '--show-toplevel']).then(
      (value) => _gitTopLevel = value.single,
    );
  }

  Future<bool> checkIfGitDir() async {
    return getRepoTopLevelPath().then(
      (topLevel) => path.equals(topLevel, root.path),
      onError: (error) => error.toString().contains('not a git repository')
          ? false
          : Future.error(error),
    );
  }

  List<String>? _remotes;

  Future<List<String>> getRemoteNames() async {
    _remotes ??= await runGitCmd(['remote']);
    return _remotes!;
  }

  Future<GitRemote?> getRemoteInfo(String remoteName) async {
    final remotes = await getRemoteNames();
    if (!remotes.contains(remoteName)) return null;
    return GitRemote(name: remoteName, branch: 'TODO');
  }

  Future<List<String>> runGitCmd(List<String> command) async {
    final cmd = await Process.start(
      'git',
      command,
      workingDirectory: root.path,
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
// Get current branch
// rev-log for current branch (even if not tracked)
// Check what tracked/upstream branch is ?
}

class NotGitRepository implements Exception {}
