multi sub MAIN('watch') {
    unless '.git/HEAD'.IO.e {
        note "Can only use inter-commit in a Git repository";
        exit(1);
    }

    mkdir '.inter-commit';

    react {
        my $change-id = 0;

        whenever '.git/logs/HEAD'.IO.watch {
            for dir('.inter-commit') {
                unlink($_);
            }
            $change-id = 0;
            say "HEAD moved; cleared backups";
        }

        whenever '.'.IO.watch.unique(:as(*.path), :expires(1)) {
            my $path = .path;
            next if $path eq '.inter-commit' | '.git';
            $change-id++;
            spurt '.inter-commit/index', :append,
                "$change-id $path\n";
            copy $path, ".inter-commit/$change-id";
            say "Backed up $path";
            CATCH {
                default {
                    note "ERROR: could not back up $path: {.message}";
                }
            }
        }
    }
}

multi sub MAIN('list') {
    try print slurp '.inter-commit/index';
}

multi sub MAIN('show', Int $entry) {
    print slurp '.inter-commit/' ~ $entry;
    CATCH {
        default {
            note "No such entry";
            exit 1;
        }
    }
}
