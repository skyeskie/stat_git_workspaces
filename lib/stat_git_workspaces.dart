

import 'package:stat_git_workspaces/src/workspace.dart';

void statOnWorkdir() async {
  final ws = Workspace();
  await ws.displayListing();
}
