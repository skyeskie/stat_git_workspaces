import 'dart:io';

import 'package:ansix/ansix.dart';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:repository_url/repository_url.dart';
import 'package:stat_git_workspaces/src/core/git_command.dart';

import 'git_remote.dart';
import 'multi_command.dart';

part 'git_repo.dart';

sealed class DirStat {
  DirStat({
    required this.name,
    required ArgResults? args,
    required ArgResults? globalArgs,
  })  : _args = args,
        _globalArgs = globalArgs;

  DirStat.fromDirectory(
    Directory dir, {
    required ArgResults? args,
    required ArgResults? globalArgs,
  })  : name = getNameFromDir(dir),
        _args = args,
        _globalArgs = globalArgs;

  getArg(String key) {
    final argKeys = _args?.options ?? [];
    return argKeys.contains(key) ? (_args?[key]) : (_globalArgs?[key]);
  }

  final String name;

  final ArgResults? _args;

  final ArgResults? _globalArgs;

  static String getNameFromDir(Directory dir) => path.basename(dir.path);

  static Future<bool> checkIfGitDir(String workingDirectory) async {
    final cmd = GitCommand(
      ['rev-parse', '--show-toplevel'],
      workingDirectory: workingDirectory,
    );

    final result = await cmd.run();

    if (result) {
      return path.equals(
        await cmd.stdout,
        workingDirectory,
      );
    }

    final errorMsg = await cmd.stderr;

    if (errorMsg.contains('not a git repository')) return false;

    return Future.error(errorMsg);
  }
}

class NonGitRepo extends DirStat {
  NonGitRepo({
    required super.name,
    required super.args,
    required super.globalArgs,
  });
}
