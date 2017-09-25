use GTK::Simple;
use GTK::Simple::App;
use MONKEY-SEE-NO-EVAL;

my $app = GTK::Simple::App.new(title => 'Code Golf Assistant!');
$app.set-content(GTK::Simple::VBox.new(
    my $source  = GTK::Simple::TextView.new(),
    my $chars   = GTK::Simple::Label.new(text => 'Characters: 0'),
    my $elapsed = GTK::Simple::Label.new(),
    my $results = GTK::Simple::TextView.new(),
));

supply {
    # We need to react to certain events on the UI thread; this uses the
    # GTK::Simple::Scheduler object to ensure they end up there.
    sub on-ui(Supply $s --> Supply) {
        return $s.schedule-on(GTK::Simple::Scheduler);
    }

    whenever $source.changed {
        $chars.text = "Characters: $source.text.chars()";
    }

    whenever on-ui(Supply.interval(1)) -> $secs {
        $elapsed.text = "Elapsed: $secs seconds";
    }

    # Runs the provided code by spawing a Perl 6 process. Kills it if the
    # Supply returned here is closed.
    sub run-perl6($source) {
        supply {
            my $perl6 = Proc::Async.new($*EXECUTABLE, '-e', $source.text);
            my $output = '';
            whenever $perl6.stdout {
                $output ~= $_;
            }
            whenever $perl6.stderr {
                $output ~= $_;
            }
            whenever $perl6.start {
                emit $output;
                done;
            }
            whenever Promise.in(10) {
                $output ~= 'Timeout; killed after 10s';
                emit $output;
                done;
            }
            CLOSE $perl6.?kill;
        }
    }

    whenever on-ui($source.changed.stable(1).map(&run-perl6).migrate) -> $output {
        $results.text = $output
    }
}.tap;

$app.run();
