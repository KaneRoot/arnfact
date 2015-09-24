package app;
use v5.14;
use Moo;

use db;
use facturation ':all';

has [qw/db/] => ( is => 'rw', builder => '_void');

has [qw/tmpdir database contracttypes/] 
=> qw/is ro required 1/;

sub _void { my $x = ''; \$x; }

sub BUILD {
    my ($self) = @_;
    $$self{db} = db->new(data => $self);

    my $db = $$self{database};
    unless(exists $$db{sgbd} && exists $$db{name}
        && exists $$db{host} && exists $$db{port}
        && exists $$db{user} && exists $$db{passwd})
    {
        die "Unable to connect to the database.\n"
        . "Check the existance of theses parameters in the config file :\n"
        . "\tsgbd name host port user passwd";
    }
}

### users

sub auth {
    my ($self, $login, $passwd) = @_;
    $self->db->auth($login, $passwd)
}

sub update_passwd {
    my ($self, $userid, $newpass) = @_;
    $self->db->update_passwd($userid, $newpass)
}

sub register_user {
    my ($self, @v) = @_;
    $self->db->register_user(@v)
}

sub toggle_admin {
    my ($self, $login) = @_;
    $self->db->toggle_admin($login)
}

sub delete_user {
    my ($self, $login) = @_;
    $self->db->delete_user($login)
}

sub get_all_users {
    my ($self) = @_; 
    $self->db->get_all_users
}

# contract

sub get_all_contractentries {
    my ($self, @v) = @_; 
    $self->db->db_get_all_contractentries();
}

sub get_all_contracts {
    my ($self, @v) = @_; 
    $self->db->db_get_all_contracts();
}

sub get_contract {
    my ($self, @v) = @_; 
    $self->db->db_get_contract(@v);
}

sub add_contract {
    my ($self, @v) = @_; 
    $self->db->db_add_contract(@v);
}

sub add_contract_assoc {
    my ($self, @v) = @_; 
    $self->db->db_add_contract_assoc(@v);
}

sub add_contractentry {
    my ($self, @v) = @_; 
    $self->db->db_add_contractentry(@v);
}

sub delete_contract {
    my ($self, @v) = @_; 
    $self->db->db_delete_contract(@v);
}

sub delete_contract_entry {
    my ($self, @v) = @_; 
    $self->db->db_delete_contract_entry(@v);
}

sub get_contract_entries {
    my ($self, @v) = @_; 
    $self->db->db_get_contract_entries(@v);
}

# CONFORT

sub get_next_contractentryid {
    my ($self, @v) = @_; 
    $self->db->db_get_next_contractentryid(@v);
}

sub get_next_contractid {
    my ($self, @v) = @_; 
    $self->db->db_get_next_contractid(@v);
}

# GEN PDF

sub genpdf {
    my ($self, $contractid) = @_; 

    my $contract = $self->get_contract($contractid);

    eval {
        my $tpldir = $$self{contracttypes}{$$contract{contracttype}}{tpldir};
        my $factdir = $$self{contracttypes}{$$contract{contracttype}}{factdir};
        my $user = $self->db->get_user($$contract{userid});
        my $price = $$self{contracttypes}{$$contract{contracttype}}{price};

        gen_fact($user, $contract, $price, $$self{tmpdir}, $tpldir, $factdir);
    };

    if($@) {
        die "genpdf : " . $@;
    }

}

sub disconnect {
    my ($self) = @_; 
    $self->db->disconnect();
}

1;
