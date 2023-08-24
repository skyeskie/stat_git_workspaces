A command line helper to show status for a group of git workspaces.

## Intent

I have projects organized in a workspaces folder. In addition to main GitHub, I run a local git instance for additional
backup purposes (or for some things I don't necessarily want on GitHub)

I wanted a command (`stat-ws`) that would for each workspace:
- Make sure it is a Git repository
- Indicate basic status (ahead, behind, modified)
- Assist setup of backup git repository
- Indicate status of backup git repository
- Push to back up git repo

TODO: Add screenshot

## Potential Additions

- Details about current repo
- Handling origin, upstream, and backup/nas
- Bulk operations (ie change repository)
- Assist in cleaning up worktree
