import 'package:stat_git_workspaces/src/git_remote.dart';

sealed class DirStat {
  DirStat({required this.name});

  final String name;
}

class NonGitRepo extends DirStat {
  NonGitRepo({required super.name});
}

class GitRepoInfo extends DirStat {
  GitRepoInfo({
    required super.name,
    this.origin,
    this.backup,
    this.upstream,
  });

  GitRemote? origin;
  GitRemote? backup;
  GitRemote? upstream;
}
