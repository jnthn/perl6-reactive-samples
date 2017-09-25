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

    sub run-code($source) {
        (try EVAL $source.text) // $!.message
    }

    whenever on-ui($source.changed.stable(1).start(&run-code).migrate) -> $output {
        $results.text = $output
    }
}.tap;

$app.run();
