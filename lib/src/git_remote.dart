class GitRemote {
  final String name;
  final String branch;
  final int ahead;
  final int behind;

  GitRemote({
    required this.name,
    required this.branch,
    this.ahead = 0,
    this.behind = 0,
  });

  bool get isSync => ahead == 0 && behind == 0;
}
