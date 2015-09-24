package bdd::contract;
use v5.14;
use Moo;
use utf8;

use List::Util qw(max);

use Exporter 'import';
# what we want to export eventually
our @EXPORT_OK = qw/
add_contract
add_contractentry
add_contract_assoc

get_contract_entry 
get_contract
get_all_contracts
get_all_contractentries
get_entries_from_contract
get_contract_entries

get_next_contractentryid
get_next_contractid

delete_contract
delete_contract_entry
/;

# bundle of exports (tags)
our %EXPORT_TAGS = ( all => [qw/
        add_contract
        add_contractentry
        add_contract_assoc

        get_contract_entry 
        get_contract
        get_contract_entries
        get_all_contracts
        get_all_contractentries
        get_entries_from_contract

        get_next_contractentryid
        get_next_contractid

        delete_contract_entry
        delete_contract
        /] );

sub db_insert_ {
    my ($dbh, $table, $values) = @_;

    my $sth;

    my $str = "insert into $table ";

    my @k = keys %$values;
    $str .= "(". join(',', @k) . ")";

    $str .= " VALUES (";
    $str .= "?";
    my $nb = @k;
    while( --$nb ) { $str .= ',?'; }
    $str .= ')';

    say "REQUEST : $str";

    my @v;
    push @v, $$values{$_} for @k;

    $sth = $dbh->prepare($str);
    unless ($sth->execute(@v)) {
        $sth->finish();
        die qq{Can't add something in $table.};
    }

    $sth->finish();
}

# CONTRACTS
# varchar(100)  varchar(50) varchar(10)     varchar(20) varchar(20)
# contractid    userid      contracttype    payment     lastpaymentdate
sub add_contract {
    my ($dbh, $values) = @_;
    db_insert_ $dbh, "contract", $values;
}

# CONTRACTENTRY
# varchar(100)    varchar(15) varchar(15)     varchar(15)
# contractentryid startdate   duration        setupdate

sub add_contractentry {
    my ($dbh, $values) = @_;
    db_insert_ $dbh, "contractentry", $values;
}

sub add_contract_assoc {
    my ($dbh, $values) = @_;
    db_insert_ $dbh, "contract_assoc", $values;
}

sub delete_contract_entry {
    my ($dbh, $contractentryid) = @_;

    my $req = 'delete from contract_assoc where contractentryid=?';
    my $sth = $dbh->prepare($req);

    unless ( $sth->execute($contractentryid) ) {
        $sth->finish();
        die q{Unable to delete the contractentry }
       . qq{$contractentryid on contract_assoc table.};
    }
    $sth->finish();

    $req = 'delete from contractentry where contractentryid=?';
    $sth = $dbh->prepare($req);

    unless ( $sth->execute($contractentryid) ) {
        $sth->finish();
        die q{Unable to delete the contractentry }
       . qq{$contractentryid on contractentry table.};
    }

    $sth->finish();
}

sub get_contract_entry {
    my ($dbh, $contractentryid) = @_;

    my $entry;

    my $req = 'select * from contractentry where contractentryid=?';
    my $sth = $dbh->prepare($req);

    unless ( $sth->execute($contractentryid) ) {
        $sth->finish();
        die q{Unable to select the contract entry for contractentry }
        . qq{$contractentryid on contractentry table.};
    }

    if (my $ref = $sth->fetchrow_hashref) {
        $entry = $ref;
    }
    else {
        die q{No contract entry for contractentry }
        . qq{$contractentryid on contractentry table.};
    }
    $sth->finish();

    $entry;
}

sub get_contract_entries {
    my ($dbh, $contractid) = @_;

    my $entriesnumber = get_entries_from_contract($dbh, $contractid);
    my @ce;
    for(@$entriesnumber) {
        push @ce, get_contract_entry $dbh, $_;
    }

    [@ce];
}

sub get_all_contracts {
    my ($dbh) = @_;

    my $req = 'select contractid from contract';
    my $sth = $dbh->prepare($req);

    unless ( $sth->execute() ) {
        $sth->finish();
        die qq{Unable to list the contracts. }
    }

    my @contract_ids;
    while (my $ref = $sth->fetchrow_hashref) {
        push @contract_ids, $$ref{contractid};
    }

    my @contracts;
    for(@contract_ids)
    {
        push @contracts, get_contract($dbh, $_);
    }

    @contracts;
}

sub get_all_contractentries {
    my ($dbh) = @_;

    my $req = 'select contractentryid from contractentry';
    my $sth = $dbh->prepare($req);

    unless ( $sth->execute() ) {
        $sth->finish();
        die qq{Unable to list the contracts. }
    }

    my @contractentryids;
    while (my $ref = $sth->fetchrow_hashref) {
        push @contractentryids, $$ref{contractentryid};
    }

    my @contracts;
    for(@contractentryids)
    {
        push @contracts, get_contract_entry($dbh, $_);
    }

    @contracts;
}

sub get_contract {
    my ($dbh, $contractid) = @_;

    my $contract;

    my $req = 'select * from contract where contractid=?';
    my $sth = $dbh->prepare($req);

    unless ( $sth->execute($contractid) ) {
        $sth->finish();
        die qq{Unable to select the contract entries for contract $contractid }
       . q{on contract_assoc table.};
    }

    unless ($contract = $sth->fetchrow_hashref) {
        $sth->finish();
        die qq{Unable to get the contract.};
    }
    $sth->finish();

    my $entriesnumber = get_entries_from_contract($dbh, $contractid);
    $$contract{entries} = [];
    push @{$$contract{entries}}, get_contract_entry($dbh, $_)
    for (@$entriesnumber);

    $contract;
}

sub get_entries_from_contract {
    my ($dbh, $contractid) = @_;

    my $req = 'select contractentryid from contract_assoc where contractid=?';
    my $sth = $dbh->prepare($req);

    unless ( $sth->execute($contractid) ) {
        $sth->finish();
        die qq{Unable to select the contract entries for contract $contractid }
       . q{on contract_assoc table.};
    }

    my @entries;
    while (my $ref = $sth->fetchrow_hashref) {
        push @entries, $$ref{contractentryid};
    }
    $sth->finish();

    [@entries]
}

# delete a contract is to delete all its contract entries
sub delete_contract {
    my ($dbh, $contractid) = @_;

    # remove all the entries
    my $entries = get_entries_from_contract($dbh, $contractid);
    for(@$entries) {
        delete_contract_entry ($dbh, $_ );
    }

    # also remove the contract from the contract table
    my $req = 'delete from contract where contractid=?';
    my $sth = $dbh->prepare($req);

    unless ( $sth->execute($contractid) ) {
        $sth->finish();
        die
        qq{Unable to delete the contract $contractid on contract_assoc table.};
    }
    $sth->finish();
}

sub select_next_id {
    my ($dbh, $val, $table) = @_;

    my @entries;
    my $req = "select $val from $table";
    my $sth = $dbh->prepare($req);

    unless ( $sth->execute() ) {
        $sth->finish();
        die "Unable to select the $val. ";
    }

    while (my $ref = $sth->fetchrow_hashref) {
        push @entries, $$ref{$val}
    }
    $sth->finish();

    if(@entries == 0) {
        return 1;
    }

    my $max = max @entries;

    $max + 1
}

sub get_next_contractentryid {
    my ($dbh) = @_;
    select_next_id $dbh, "contractentryid", "contractentry";
}

sub get_next_contractid {
    my ($dbh) = @_;
    select_next_id $dbh, "contractid", "contract";
}

1;
