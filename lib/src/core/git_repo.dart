part of 'dir_stat.dart';

class GitRepo extends DirStat {
  GitRepo({
    required this.root,
    this.mode = CommandMode.batch,
    required super.args,
    required super.globalArgs,
  }) : super.fromDirectory(root);

  final Directory root;
  final CommandMode mode;

  // ['status', '--porcelain=v2', '--show-stash', '--untracked-files=normal']
  // git rev-list --count --left-right main...nas/main

  @override
  String get name => path.basename(root.path);

  final remoteParse = RegExp(r'(\S+)\s+(\S+)\s+\((fetch|push)\)');

  Future<List<(String, String)>> get remoteNames => runGitCmd(
        ['remote', '-v'],
        runAlways: true,
        cache: true,
      ).results.then(
            (remotes) => remotes
                .map((remote) {
                  final matches = remoteParse.allMatches(remote);
                  if (matches.length != 1) return null;
                  final match = matches.single;
                  if (match.groupCount != 3) return null;
                  if (match.group(3) == 'push') return null;
                  return (match.group(1), match.group(2));
                })
                .whereType<(String, String)>()
                .toList(),
          );

  Future<String> get branch => runGitCmd(
        ['symbolic-ref', '--short', 'HEAD'],
        runAlways: true,
        cache: true,
      ).stdout.then(
            (output) => output.trim(),
          );

  Future<GitRemote?> get origin => getRemoteInfo(getArg('origin-remote-name'));

  Future<GitRemote?> get backup => getRemoteInfo(getArg('backup-remote-name'));

  Future<GitRemote?> get upstream =>
      getRemoteInfo(getArg('upstream-remote-name'));

  // General commands

  Future<GitRemote?> getRemoteInfo(String remoteName) async {
    final remotes = await remoteNames;
    final remoteMatch = remotes.where(
      (element) => element.$1 == remoteName,
    );
    if (remoteMatch.isEmpty) return null;
    return GitRemote(
      name: remoteName,
      uri: RepositoryUrl(remoteMatch.first.$2),
      branch: 'TODO',
    );
  }

  // TODO: Move main git commands to separate object?

  final _cache = <String, GitCommand>{};

  GitCommand runGitCmd(
    List<String> command, {
    bool runAlways = false,
    String? promptCommandName,
    bool cache = false,
    bool includeStdErr = false,
  }) {
    final subcmd = command.join(' ');
    if (cache) {
      final cacheVal = _cache[subcmd];
      if (cacheVal != null) return cacheVal;
    }

    final cmd = GitCommand(
      command,
      workingDirectory: root.path,
      promptCommandName: promptCommandName,
      mode: mode,
      runAlways: runAlways,
      repoName: name,
    );
    if (cache) _cache[subcmd] = cmd;
    return cmd;
  }
}
