# inter-commit sample application

This application demonstrates using file change watchers, on an individual and
also on a directory. It makes backup copies of files that are changed in a git
respository between commits, clearing the backup at the point a commit is
made. To keep the example straightforward, it only watches the directory it
is started in, rather than watching recursively. It should be started in the
top level of a git repository.

The subcommands are:

* `watch` - starts the watcher process
* `list` - lists the backups that were made
* `show n` - shows backup number `n`
