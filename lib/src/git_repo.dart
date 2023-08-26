import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:stat_git_workspaces/src/repo_info.dart';

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
    if (!await checkIfGitDir()) {
      return NonGitRepo(name: getRepoName());
    }

    return GitRepoInfo(
      name: getRepoName(),
    );
  }

  String getRepoName() => path.basename(root.path);

  String? _gitTopLevel;

  Future<String> getRepoTopLevelPath() async {
    if (_gitTopLevel != null) return _gitTopLevel!;

    final cmd = await Process.start(
      'git',
      ['rev-parse', '--show-toplevel'],
      workingDirectory: root.path,
    );

    final exitCode = await cmd.exitCode;

    if (exitCode != 0) {
      final error =
          await cmd.stderr.transform(const SystemEncoding().decoder).join();
      if (error.contains('not a git repository')) {
        throw NotGitRepository();
      }
      throw Exception(error);
    }

    final gitTopLevel = await cmd.stdout
        .transform(
          const SystemEncoding().decoder,
        )
        .join();
    _gitTopLevel = gitTopLevel.trim();
    return _gitTopLevel!;
  }

  Future<bool> checkIfGitDir() async {
    try {
      final topLevel = await getRepoTopLevelPath();
      return path.equals(topLevel, root.path);
    } on NotGitRepository {
      return false;
    }
  }
// Get current branch
// rev-log for current branch (even if not tracked)
// Check what tracked/upstream branch is ?
}

class NotGitRepository implements Exception {}
