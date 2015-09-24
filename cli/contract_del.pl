#!/usr/bin/perl -w
use v5.14;
use autodie;
use Modern::Perl;

use lib './lib/';
use configuration ':all';
use encryption ':all';
use app;

if( @ARGV != 1 ) {
    say "usage : ./$0 contractid";
    exit 1;
}

my $contractid = $ARGV[0];

eval {
    my $app = app->new(get_cfg());
    $app->delete_contract($contractid);
};

if( $@ ) {
    say q{Une erreur est survenue. } . $@;
}
