#!/usr/bin/perl -w
use v5.14;
use autodie;
use Modern::Perl;
use Time::Local;
use Date::Calc ':all';

#my $time = timelocal($sec,$min,$hour,$mday,$mon,$year);
# localtime = mois débute en 0, jours aussi
my $time = timelocal(0,0,0,13,0,2015);

#my $time = Date_to_Time($year,$month,$day, $hour,$min,$sec);

# Time_to_Date = mois et jours commencent à 1
my ($year,$month,$day,$hour,$min,$sec) = Time_to_Date($time);

# say "time : $time";

#$time = timegm($sec,$min,$hour,$mday,$mon,$year);

# my ($oldyear, $oldmonth, $oldday) = qw/2015 8 13/;
#-- add 60 days to November 4th, 1985
# my ($year, $month, $day) = Add_Delta_Days($oldyear, $oldmonth, $oldday, 7);

say "year $year, month $month, day $day";
