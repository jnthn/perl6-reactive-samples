my $ticker   = Supply.interval(1);
my $ticktock = $ticker.map({ $_ % 2 ?? 'tock' !! 'tick' });
$ticktock.tap(&say);
sleep 5;
