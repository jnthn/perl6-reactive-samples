class InterCommitWatcher {
    has $.log;

    submethod BUILD(:$base) {
        $!log = Supply.new;
        self!watch_HEAD();
        self!watch_dir($base);
    }

    method !watch_HEAD() {
        IO::Notification.watch_path('.git/logs/HEAD').act({
            for dir('.inter-commit') {
                unlink($_);
            }
            $!log.more("HEAD moved; cleared backups");
        });
    }

    method !watch_dir($dir) {
        IO::Notification.watch_path($dir)\
            .uniq(:as(*.path), :expires(1))\
            .map(*.path)\
            .grep(* ne '.inter-commit')\
            .grep(* ne '.git')\
            .act(-> $backup {
                ++state $change_id;
                spurt '.inter-commit/index', :append,
                    "$change_id $backup\n";
                copy $backup, ".inter-commit/$change_id";
                $!log.more("Backed up $backup");
                CATCH {
                    default {
                        $!log.more("ERROR: could not back up $backup: $!.message()");
                    }
                }
            });
    }
}

multi sub MAIN('watch') {
    unless '.git/HEAD'.IO.e {
        note "Can only use inter-commit in a Git repository";
        exit(1);
    }

    mkdir '.inter-commit';

    my $icw = InterCommitWatcher.new(base => '.');
    $icw.log.tap(&say);
    sleep;
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
