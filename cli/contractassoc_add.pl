#!/usr/bin/perl -w
use v5.14;
use autodie;
use Modern::Perl;

use lib './lib/';
use configuration ':all';
use encryption ':all';
use app;

if( @ARGV != 2 ) {
    say "usage : ./$0 contractid contractentryid";
    exit 1;
}

my $c = {(contractid => $ARGV[0], contractentryid => $ARGV[1])};

eval {
    my $app = app->new(get_cfg());
    $app->add_contract_assoc($c);
};

if( $@ ) {
    say q{Une erreur est survenue. } . $@;
}
