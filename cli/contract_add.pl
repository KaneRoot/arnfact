#!/usr/bin/perl -w
use v5.14;
use autodie;
use Modern::Perl;

use lib './lib/';
use configuration ':all';
use encryption ':all';
use app;

if( @ARGV != 7 ) {
    say "usage : ./$0 contractid userid contracttype payment "
    . "lastpaymentdate emissiondate setupdate";
    exit 1;
}

my $c = {(
    contractid          => $ARGV[0]
    , userid            => $ARGV[1]
    , contracttype      => $ARGV[2]
    , payment           => $ARGV[3]
    , lastpaymentdate   => $ARGV[4]
    , emissiondate      => $ARGV[5]
    , setupate          => $ARGV[6]
    )};

eval {
    my $app = app->new(get_cfg());
    $app->add_contract($c);
};

if( $@ ) {
    say q{Une erreur est survenue. } . $@;
}
