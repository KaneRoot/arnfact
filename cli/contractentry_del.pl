#!/usr/bin/perl -w
use v5.14;
use autodie;
use Modern::Perl;

use lib './lib/';
use configuration ':all';
use encryption ':all';
use app;

if( @ARGV != 1 ) {
    say "usage : ./$0 contractentryid";
    exit 1;
}

my $contractentryid = $ARGV[0];

eval {
    my $app = app->new(get_cfg());
    $app->delete_contract_entry($contractentryid);
};

if( $@ ) {
    say q{Une erreur est survenue. } . $@;
}
