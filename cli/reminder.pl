#!/usr/bin/perl -w
use v5.14;
use autodie;
use Modern::Perl;
use Time::Local;
use Date::Calc ':all';

use Data::Dump qw( dump );

use lib './lib/';
use configuration ':all';
use app;

if( @ARGV != 0 ) {
    say "usage : ./$0";
    exit 1;
}

sub end_date_ {
    my ($sd, $duration) = @_;
    my ($sd_y, $sd_m, $sd_d) = split /-/, $sd;
    my ($y, $m, $d) = Add_Delta_YM($sd_y, $sd_m, $sd_d, 0, $duration);

    Date_to_Time($y, $m, $d, 0, 0, 0);
}

sub reminder {
    my $contracts = shift;

    for(@$contracts)
    {
        say "contract id : " . $$_{contractid};
        for(@{$$_{entries}})
        {
            my $end_date = end_date_ $$_{startdate}, $$_{duration};

            my ($ey, $em, $ed) = Time_to_Date($end_date);
            my ($ty, $tm, $td) = Today();

            if( $ty > $ey
                || $ty == $ey && $tm > $em
                || $ty == $ey && $tm == $em && $td >= $ed)
            {
                print "\tentry " . $$_{contractentryid};
                my ($ny, $nm, $nd) = Time_to_Date($end_date);
                say ", $$_{startdate} + $$_{duration} = $ny-$nm-$nd";
            }
        }
    }

}

eval {
    my $app = app->new(get_cfg());

    my @contracts = $app->get_all_contracts();
    reminder [ @contracts ] ;
};

if( $@ ) {
    say q{Une erreur est survenue. } . $@;
}
