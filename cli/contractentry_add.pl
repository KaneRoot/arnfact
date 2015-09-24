#!/usr/bin/perl -w
use v5.14;
use autodie;
use Modern::Perl;

use lib './lib/';
use configuration ':all';
use encryption ':all';
use app;

if( @ARGV != 4 ) {
    say "usage : ./$0 contractentryid startdate duration nb";
    exit 1;
}

my $c = {(
    contractentryid => $ARGV[0]
    , startdate     => $ARGV[1]
    , duration      => $ARGV[2]
    , nb            => $ARGV[3]
    )};

eval {
    my $app = app->new(get_cfg());
    $app->add_contractentry($c);
};

if( $@ ) {
    say q{Une erreur est survenue. } . $@;
}
