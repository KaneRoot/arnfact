package facturation;
use strict;
use warnings;

use Date::Calc ':all';
use v5.14;
use utf8;

use fileutil ':all';

use Exporter 'import';
# what we want to export eventually
our @EXPORT_OK = qw/
make_line
gen_fact
/;

# bundle of exports (tags)
our %EXPORT_TAGS = ( all => [qw/
        make_line
        gen_fact
        /] );

sub make_line_brique {
    my ($type, $nb_mois, $debut, $fin, $nb, $prix_unit) = @_;
    my $montant_tot = $nb * $prix_unit;
    $type = uc $type;
    "$type & $prix_unit & $nb & $montant_tot" . '\\\\ \hline' . "\n";
}

sub make_line_vpnvps {
    my ($type, $nb_mois, $debut, $fin, $nb, $prix_unit) = @_;

    my $montant_tot = $nb * $nb_mois * $prix_unit;
    $type = uc $type;
    "$nb_mois mois de service $type du $debut au $fin & " 
    . ($prix_unit * $nb_mois)
    . " & $nb & $montant_tot " . '\\\\ \hline' . "\n";
}

sub make_line {
    my ($type) = @_;

    if($type =~ m/brique/i) {
        return make_line_brique @_ ;
    }
    elsif($type =~ m/vp[ns]/i) {
        return make_line_vpnvps @_ ;
    }

    die "Fact type $type doesn't exists.";
}

sub montant_tot_ {
    my ($type, $nb, $duration, $price) = @_;

    if($type =~ m/brique/i) {
        return $nb * $price;
    }
    elsif($type =~ m/vp[ns]/i) {
        return $nb * $price * $duration;
    }
}

sub make_pdf_ {
    my $tmpdir = shift;
    my $cwd = `pwd`;
    chomp $cwd;
    chdir $tmpdir;
    qx/make/;
    chdir $cwd;
}

sub end_date_ {
    my ($sd, $duration) = @_;
    my ($sd_y, $sd_m, $sd_d) = split /-/, $sd;
    my ($y, $m, $d) = Add_Delta_YMD($sd_y, $sd_m, $sd_d, 0, $duration, -1);
    Date_to_Time($y, $m, $d, 0, 0, 0);
}

sub gen_fact {
    my ($user, $c, $price, $tmpdir, $tpldir, $factdir) = @_;

    my $type = $$c{contracttype};

    die "gen_fact user" unless $user;
    die "gen_fact contract" unless $c;
    die "gen_fact price" unless $price;
    die "gen_fact type" unless $type;
    die "gen_fact tmpdir" unless $tmpdir;
    die "gen_fact tpldir" unless $tpldir;
    die "gen_fact factdir" unless $factdir;

    say "gen_fact user : $user";
    say "gen_fact contract : $c";
    say "gen_fact price : $price";
    say "gen_fact type : $type";
    say "gen_fact tmpdir : $tmpdir";
    say "gen_fact tpldir : $tpldir";
    say "gen_fact factdir : $factdir";

    $tmpdir .= "/$$c{contractid}";

    my $dateemission = join '/', reverse(split('-', $$c{emissiondate}));
    my $dateemission_nonformat = join '', (split('-', $$c{emissiondate}));

    my $setupdate = join '/', reverse(split('-', $$c{setupdate}));

    my $ce = $$c{entries};

    my $num_fact = "0" x (10 - length $$c{contractid}) . $$c{contractid};

    my $val = {
        TPL_IDENTIFIANT                 => $$user{userid}
        , TPL_PRENOM                    => $$user{firstname}
        , TPL_NOM                       => $$user{secondname}
        , TPL_ADRESSE                   => $$user{address}
        , TPL_CODE_POSTAL               => $$user{postalcode}
        , TPL_VILLE                     => $$user{town}
        , TPL_DATE_EMISSION_NONFORMAT   => $dateemission_nonformat
        , TPL_DATE_EMISSION_FORMAT      => $dateemission
        , TPL_NUMERO_FACTURE            => $num_fact
        , TPL_TYPE_REGLEMENT            => $$c{payment}
        , TPL_DATE_DEBUT_PRESTAT        => $setupdate
    };

    my $real_montant_tot;

    $$val{TPL_LINES} = '';
    for(@$ce) {
        my $start = join '/', reverse (split '-', $$_{startdate});
        my $end_date = end_date_ $$_{startdate}, $$_{duration};
        my ($y, $m, $d) = Time_to_Date($end_date);
        my $end = join '/', ($d, $m, $y);

        $$val{TPL_LINES} .= make_line $type, $$_{duration}, $start, $end
        , $$_{nb}, $price;

        $real_montant_tot += montant_tot_ $type, $$_{nb}, $$_{duration}, $price;
    }

    $$val{TPL_MONTANT_TOT} = $real_montant_tot;

    my $factfile = "facture.tex";
    my $data = read_file("$tpldir/$factfile");

    for(keys %$val) {
        say "FACT : $_ : $$val{$_}";
        $data =~ s/$_/$$val{$_}/g;
    }

    mkdir $tmpdir;
    qx{cp -r $tpldir/* $tmpdir};

    write_file "$tmpdir/$factfile", $data;

    make_pdf_ $tmpdir;

    $type = uc $type;

    my $pdffilename = "$type$$val{TPL_DATE_EMISSION_NONFORMAT}"
    . "-$$val{TPL_IDENTIFIANT}-$$val{TPL_NUMERO_FACTURE}";

    say "pdf file name : $pdffilename";
    qx{mv $tmpdir/facture.pdf $factdir/$pdffilename.pdf};
}

1;
