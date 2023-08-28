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
      ).then(
        (remotes) => remotes
            .map((remote) {
              final matches = remoteParse.allMatches(remote);
              if (matches.length != 1) return null;
              final match = matches.single;
              if (match.groupCount != 3) return null;
              if (match.group(3) == 'push') return null;
              print("${match.group(1)} | ${match.group(2)}");
              return (match.group(1), match.group(2));
            })
            .whereType<(String, String)>()
            .toList(),
      );

  Future<String> get branch => runGitCmdSingle(
        ['symbolic-ref', '--short', 'HEAD'],
        runAlways: true,
        cache: true,
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

  final _cache = <String, List<String>>{};

  Future<List<String>> runGitCmd(
    List<String> command, {
    bool runAlways = false,
    String? promptCommandName,
    bool cache = false,
    bool includeStdErr = false,
  }) async {
    final subcmd = command.join(' ');
    if (cache) {
      final cacheVal = _cache[subcmd];
      if (cacheVal != null) return cacheVal;
    }
    if (mode == CommandMode.printCommands) {
      print('git $subcmd');
    }
    promptCommandName ??= command.first;
    bool execute = runAlways || mode.execute;
    if (!runAlways || mode.confirm) {
      try {
        execute = Confirm(
          prompt: 'Run $promptCommandName on $name?',
          defaultValue: true, // this is optional
          waitForNewLine: true, // optional and will be false by default
        ).interact();
      } catch (e) {
        // Interrupting interact prompt could mess up console
        reset();
        rethrow;
      }
    }
    if (execute) {
      final result = DirStat.runGitCmd(
        command,
        workingDirectory: root.path,
        includeStdErr: includeStdErr,
      );
      if (cache) _cache[subcmd] = await result;
      return result;
    }
    return Future.value(['Dry-run']);
  }

  Future<String> runGitCmdSingle(
    List<String> command, {
    bool runAlways = false,
    String? promptCommandName,
    bool cache = false,
  }) =>
      runGitCmd(
        command,
        runAlways: runAlways,
        promptCommandName: promptCommandName,
        cache: cache,
      ).then(
        (value) => value.single.trim(),
      );
}
