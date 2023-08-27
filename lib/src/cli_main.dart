import 'package:args/args.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:stat_git_workspaces/src/stat/stat_command.dart';

class CliMain extends CompletionCommandRunner<int> {
  CliMain(super.executableName, super.description);

  @override
  ArgResults parse(Iterable<String> args) {
    if (args.isEmpty) {
      return super.parse([StatCommand.command]);
    }
    return super.parse(args);
  }
}
