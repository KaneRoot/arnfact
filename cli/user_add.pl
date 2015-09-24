#!/usr/bin/perl -w
use v5.18;
use utf8;
use autodie;
use Modern::Perl;

use warnings qw( FATAL utf8 );
use open qw( :encoding(UTF-8) :std );
use Data::Dump qw( dump );

use lib './lib/';
use configuration ':all';
use encryption ':all';
use app;

if( @ARGV != 10 ) {
    say "usage : ./$0 userid firstname secondname pseudo passwd "
    . "postalcode town address email admin";
    exit 1;
}

my $v = {(
        userid          => $ARGV[0]
        , firstname     => $ARGV[1]
        , secondname    => $ARGV[2]
        , pseudo        => $ARGV[3]
        , passwd        => encrypt($ARGV[4])
        , postalcode    => $ARGV[5]
        , town          => $ARGV[6]
        , address       => $ARGV[7]
        , email         => $ARGV[8]
        , admin         => $ARGV[9]
    )};

eval {
    my $app = app->new(get_cfg());
    $app->register_user($v);
};

if( $@ ) {
    say q{Une erreur est survenue. } . $@;
}
