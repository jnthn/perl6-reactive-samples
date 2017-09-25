react {
    whenever Supply.interval(1) -> $i {
        done if $i == 10;
        say $i %% 2 ?? 'tick' !! 'tock';
    }
}
