package db;
use v5.14;
use Moo;

use Modern::Perl;
use autodie;
use DBI;
use utf8;

use bdd::contract ':all';

# db handler
has dbh => ( is => 'rw', builder => '_void');

sub _void { my $x = ''; \$x; }

# reference to the application
has data => qw/is ro required 1/;

sub BUILD {
    my $self = shift;

    my $db = $$self{data}{database};

    my $dsn = "DBI:$$db{sgbd}:database=$$db{name};"
    . "host=$$db{host};port=$$db{port}";

    $$self{dbh} = DBI->connect($dsn, $$db{user}, $$db{passwd}) 
    || die "Could not connect to database: $DBI::errstr"; 

    # TODO this is only for mysql
    $$self{dbh}->{'mysql_enable_utf8'} = 1;
    $$self{dbh}->do('SET NAMES utf8') || die "set names utf8";
}

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

# USER

sub auth {
    my ($self, $userid, $passwd) = @_;
    my $sth;

    $sth = $self->dbh->prepare('SELECT * FROM user WHERE userid=? and passwd=?');
    unless ($sth->execute($userid, $passwd)) {
        $sth->finish();
        die q{Can't authenticate.};
    }

    # if we can't find the user with this password
    unless (my $ref = $sth->fetchrow_arrayref) {
        $sth->finish();
        die "The user $userid (mdp : $passwd) can't be authenticated.";
    }
    $sth->finish();

    # if this user exists and is auth
    $self->get_user($userid)
}

sub register_user {
    my ($self, $v) = @_;

    my $sth = $self->dbh->prepare('select * from user where userid=?');
    unless ( $sth->execute($$v{userid}) ) {
        $sth->finish();
        die "Impossible to check if the user $$v{userid} exists.";
    }

    # if an user already exists
    if (my $ref = $sth->fetchrow_arrayref) {
        $sth->finish();
        die "The user $$v{userid} already exists.";
    }

    db_insert_ $$self{dbh}, "user", $v;
}

sub delete_user {
    my ($self, $userid) = @_;
    my $sth;
    # TODO : vérifier que ça renvoie la bonne valeur
    $sth = $self->dbh->prepare('delete from user where userid=?');
    unless ( $sth->execute($userid) ) {
        $sth->finish();
        die "Impossible to delete the user $userid.";
    }
    $sth->finish()
}

sub get_user {
    my ($self, $userid) = @_;
    my ($sth, $user);

    $sth = $self->dbh->prepare('SELECT * FROM user WHERE userid=?');
    unless ( $sth->execute($userid)) {
        $sth->finish();
        die "Impossible to check if the user $userid exists.";
    }

    unless ($user = $sth->fetchrow_hashref) {
        $sth->finish();
        die "User $userid doesn't exist.";
    }
    $sth->finish();

    $user
}

sub get_all_users {
    my ($self) = @_; 
    my ($sth, $users);

    $sth = $self->dbh->prepare('SELECT * FROM user');
    unless ( $sth->execute()) {
        $sth->finish();
        die q{Impossible to list the users.};
    }

    while( my $ref = $sth->fetchrow_hashref) {
        push @$users, $ref;
    }

    $sth->finish();
    $users
}

sub toggle_admin {
    my ($self, $userid) = @_;

    my $user = $self->get_user($userid);
    my $val = ($$user{admin}) ? 0 : 1;

    my $sth = $self->dbh->prepare('update user set admin=? where userid=?');
    unless ( $sth->execute( $val, $userid ) ) {
        $sth->finish();
        die "Impossible to toggle admin the user $userid.";
    }

    $sth->finish()
}

sub update_passwd {
    my ($self, $userid, $new) = @_;
    my $sth;
    $sth = $self->dbh->prepare('update user set passwd=? where userid=?');
    unless ( $sth->execute($new, $userid) ) {
        $sth->finish();
        die q{The password can't be updated.};
    }
    $sth->finish()
}

# contract

sub db_get_all_contracts {
    my ($self) = @_;
    get_all_contracts($$self{dbh});
}

sub db_get_all_contractentries {
    my ($self) = @_;
    get_all_contractentries($$self{dbh});
}

sub db_get_contract {
    my ($self, @v) = @_;
    get_contract($$self{dbh}, @v);
}

sub db_add_contract {
    my ($self, @v) = @_;
    add_contract($$self{dbh}, @v);
}

sub db_add_contractentry {
    my ($self, @v) = @_;
    add_contractentry($$self{dbh}, @v);
}

sub db_add_contract_assoc {
    my ($self, @v) = @_;
    add_contract_assoc($$self{dbh}, @v);
}

sub db_delete_contract {
    my ($self, @v) = @_;
    delete_contract($$self{dbh}, @v);
}

sub db_delete_contract_entry {
    my ($self, @v) = @_;
    delete_contract_entry($$self{dbh}, @v);
}

sub db_get_contract_entries {
    my ($self, @v) = @_;
    get_contract_entries($$self{dbh}, @v);
}

sub db_get_next_contractentryid {
    my ($self, @v) = @_;
    get_next_contractentryid($$self{dbh}, @v);
}

sub db_get_next_contractid {
    my ($self, @v) = @_;
    get_next_contractid($$self{dbh}, @v);
}

sub disconnect {
    my ($self) = @_;
    $$self{dbh}->disconnect()
}

1;
