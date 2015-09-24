package util;

use strict;
use warnings;
use v5.14;

use Exporter 'import';
# what we want to export eventually
our @EXPORT_OK = qw/ read_file write_file get_next_fact_num /;

# bundle of exports (tags)
our %EXPORT_TAGS = ( all => [qw/ read_file write_file get_next_fact_num /] );

sub read_file {
    my ($filename) = @_;

    open my $entree, '<', $filename or 
    die "Impossible d'ouvrir '$filename' en lecture : $!";
    local $/ = undef;
    my $tout = <$entree>;
    close $entree;

    $tout
}

sub write_file {
    my ($filename, $data) = @_;

    open my $outputfile, '>', $filename or 
    die "Can't open '$filename' : $!";
    print $outputfile $data;
    close $outputfile;
}

sub get_next_fact_num {
    my ($rep) = @_;

    my @files = split "\n", `ls $rep/vp*/*`;
    my @nums;

    for(@files) {
        chomp;
        next if(m/^$/);

        m/-([0-9]+)\.\w+$/;

        if($1) {
            push @nums, int $1;
        }
    }

    my @sorted = sort { $b <=> $a } @nums;

    die q/Impossible de trouver les factures !/ unless(@sorted);
    
    my $numfact = $sorted[0] +1;
    my $nb0 = 6 - length $numfact;
    my $ret = "0" x $nb0;
    $ret . $numfact;
}

1;
