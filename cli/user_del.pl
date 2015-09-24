#!/usr/bin/perl -w
use v5.14;
use autodie;
use Modern::Perl;

use Data::Dump qw( dump );

use lib './lib/';
use configuration ':all';
use app;

if( @ARGV != 1 ) {
    say "usage : ./$0 userid";
    exit 1;
}

my $login = $ARGV[0];

eval {
    my $app = app->new(get_cfg());
    $app->delete_user($login);
};

if( $@ ) {
    say q{Une erreur est survenue. } . $@;
}
