package rt::contract;

use configuration ':all';
use app;
use v5.10;

use Exporter 'import';
# what we want to export eventually
our @EXPORT_OK = qw/
rt_contract_list
rt_contractentry_list
rt_contractentry_add
rt_contractentry_del
rt_contract_del
rt_contract_genpdf
rt_contract_add
/;

# bundle of exports (tags)
our %EXPORT_TAGS = ( all => [qw/
        rt_contract_list
        rt_contractentry_list
        rt_contractentry_add
        rt_contractentry_del
        rt_contract_del
        rt_contract_genpdf
        rt_contract_add
        /] ); 

sub rt_contract_list {
    my ($session, $param, $request) = @_;
    my $res;

    eval {
        my $app = app->new(get_cfg());
        my $user = $app->auth($$session{login}, $$session{passwd});

        unless ($user && $$user{admin}) {
            $$res{deferred}{errmsg} = q{Donnée privée, petit coquin. ;) };
            $$res{route} = '/';
            return $res;
        }

        my @contracts = $app->get_all_contracts();
        my $users = $app->get_all_users();

        my @userids;
        for(@$users) {
            push @userids, $$_{userid};
        }

        my @contracttypes = keys %{$$app{contracttypes}};

        $$res{template} = 'contracts'; 
        $$res{params} = {
            login => $$session{login}
            , admin => 1 # we know it, or we couldn't reach this
            , contracts => [ @contracts ]
            , contractid => $app->get_next_contractid()
            , users => [ @userids ]
            , contracttypes => [ @contracttypes ]
        };

        $app->disconnect();
    };

    $res
}

sub rt_contract_add {
    my ($session, $param, $request) = @_;
    my $res;

    my $app = app->new(get_cfg());
    my $user = $app->auth($$session{login}, $$session{passwd});

    unless ($user && $$user{admin}) {
        $$res{deferred}{errmsg} = q{Donnée privée, petit coquin. ;) };
        $$res{route} = '/';
        return $res;
    }

    $$res{route} = $$request{referer};

    my @elems = qw/contractid userid contracttype payment emissiondate 
    lastpaymentdate setupdate/;

    my @missingitems;

    for(@elems) {
        push @missingitems, $_ unless $$param{$_};
    }

    if(@missingitems) {
        $$res{deferred}{errmsg} = "Il manque : " . join ', ', @missingitems;
        return $res;
    }

    eval {
        $app->add_contract({
                contractid          => $$param{contractid}
                , userid            => $$param{userid}
                , contracttype      => $$param{contracttype}
                , payment           => $$param{payment}
                , setupdate         => $$param{setupdate}
                , emissiondate      => $$param{emissiondate}
                , lastpaymentdate   => $$param{lastpaymentdate}
            });
    };

    if( $@ ) {
        $$res{deferred}{errmsg} = q{Erreur à l'ajout d'un contrat. } . $@;
    }

    $app->disconnect();
    $res
}

sub rt_contract_del {
    my ($session, $param, $request) = @_;
    my $res;

    my $app = app->new(get_cfg());
    my $user = $app->auth($$session{login}, $$session{passwd});

    unless ($user && $$user{admin}) {
        $$res{deferred}{errmsg} = q{Donnée privée, petit coquin. ;) };
        $$res{route} = '/';
        return $res;
    }

    unless ($$param{contractid}) {
        $$res{deferred}{errmsg} = q{Pas de contractid. };
        $$res{route} = '/';
        return $res;
    }

    $app->delete_contract($$param{contractid});

    $$res{route} = '/contract/list'; 

    $app->disconnect();
    $res
}

sub rt_contract_genpdf {
    my ($session, $param, $request) = @_;
    my $res;

    my $app = app->new(get_cfg());
    my $user = $app->auth($$session{login}, $$session{passwd});

    unless ($user && $$user{admin}) {
        $$res{deferred}{errmsg} = q{Donnée privée, petit coquin. ;) };
        $$res{route} = '/';
        return $res;
    }

    unless ($$param{contractid}) {
        $$res{deferred}{errmsg} = q{Pas de contractid. };
        $$res{route} = '/';
        return $res;
    }

    eval {
        $app->genpdf($$param{contractid});
    };

    if($@) {
        $$res{deferred}{errmsg} = q{Generation de PDF ratée : } . $@;
    }

    $$res{route} = $$request{referer};

    $app->disconnect();
    $res
}

sub rt_contractentry_add {
    my ($session, $param, $request) = @_;
    my $res;

    my $app = app->new(get_cfg());
    my $user = $app->auth($$session{login}, $$session{passwd});

    unless ($user && $$user{admin}) {
        $$res{deferred}{errmsg} = q{Donnée privée, petit coquin. ;) };
        $$res{route} = '/';
        return $res;
    }

    unless ( $$param{contractid} ) {
        $$res{deferred}{errmsg} = q{Pas de contractid. };
        $$res{route} = '/';
        return $res;
    }

    $$res{route} = '/contractentry/list/' . $$param{contractid}; 

    my @missingitems;

    for(qw/contractentryid startdate duration nb/) {
        push @missingitems, $_ unless($$param{$_});
    }

    if(@missingitems != 0) {
        $$res{deferred}{errmsg} = "Il manque : " . join ', ', @missingitems;
        return $res;
    }

    eval {
        $app->add_contractentry({
                contractentryid     => $$param{contractentryid}
                , startdate         => $$param{startdate}
                , duration          => $$param{duration}
                , nb                => $$param{nb}
            });

        $app->add_contract_assoc({(contractid => $$param{contractid}
                    , contractentryid => $$param{contractentryid})});
    };

    if( $@ ) {
        $$res{deferred}{errmsg} = q{Erreur à l'ajout d'un contrat. } . $@;
    }

    $app->disconnect();
    $res
}

sub rt_contractentry_del {
    my ($session, $param, $request) = @_;
    my $res;

    my $app = app->new(get_cfg());
    my $user = $app->auth($$session{login}, $$session{passwd});

    unless ($user && $$user{admin}) {
        $$res{deferred}{errmsg} = q{Donnée privée, petit coquin. ;) };
        $$res{route} = '/';
        return $res;
    }

    eval {
        $app->delete_contract_entry($$param{contractentryid});
    };

    if( $@ ) {
        $$res{deferred}{errmsg} = q{Erreur à l'ajout d'un contrat. } . $@;
    }

    $$res{route} = $$request{referer};
    $app->disconnect();
    $res
}

sub rt_contractentry_list {
    my ($session, $param, $request) = @_;
    my $res;

    my $app = app->new(get_cfg());
    my $user = $app->auth($$session{login}, $$session{passwd});

    unless ($user && $$user{admin}) {
        $$res{deferred}{errmsg} = q{Donnée privée, petit coquin. ;) };
        $$res{route} = '/';
        return $res;
    }

    unless ( $$param{contractid} ) {
        $$res{deferred}{errmsg} = q{Pas de contractid. };
        $$res{route} = '/';
        return $res;
    }

    my $contractentries = $app->get_contract_entries($$param{contractid});

    $$res{template} = 'contractentries'; 
    $$res{params} = {
        login => $$session{login}
        , admin => 1 # we know it, or we couldn't reach this
        , contractid => $$param{contractid}
        , contractentryid => $app->get_next_contractentryid()
        , contractentries => $contractentries
    };

    $app->disconnect();
    $res
}

1;
