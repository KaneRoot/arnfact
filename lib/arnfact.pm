package arnfact;
use Dancer2;
use Dancer2::Plugin::Deferred;
use File::Basename;
use v5.14;

use strict;
use warnings;

our $VERSION = '0.1';

use YAML::XS;
use configuration ':all';
use rt::root ':all';
use rt::user ':all';
use rt::admin ':all';
use rt::contract ':all';
use app;

use Data::Dump qw( dump );

sub what_is_next {
    my ($res) = @_;

    #debug(Dump $res);

    if($$res{sessiondestroy}) {
        app->destroy_session;
    }

    for(keys %{$$res{deferred}}) {
        deferred $_ => $$res{deferred}{$_};
    }

    for(keys %{$$res{addsession}}) {
        #debug( "HERE : $_ => $$res{addsession}{$_}");
        session $_ => $$res{addsession}{$_};
    }

    for(keys %{$$res{delsession}}) {
        session $_ => undef;
    }

    if(exists $$res{route}) {
        redirect $$res{route};
    }
    elsif(exists $$res{template}) {
        debug(Dump $res);
        template $$res{template} => $$res{params};
    } else {
        redirect '/';
    }
}

sub get_param {
    my $param_values;
    for(@_) {
        $$param_values{$_} = param "$_";
    }
    $param_values;
}

sub get_request {
    my $request_values;
    for(@_) {
        if(/^address$/)     { $$request_values{$_} = request->address; }
        elsif(/^referer$/)  { $$request_values{$_} = request->referer; }
    }
    $request_values;
}

sub get_session {
    my $session_values;
    for(@_) {
        $$session_values{$_} = session "$_";
    }
    $session_values;
}

get '/' => sub { 
    what_is_next rt_root 
    get_session( qw/login passwd/ );
};

any ['get', 'post'] => '/admin' => sub {
    what_is_next rt_admin
    get_session( qw/login passwd/ );
};

prefix '/user' => sub {

    get '/home' => sub {
        what_is_next rt_user_home
        get_session( qw/login passwd/ )
        , get_param( qw// )
        , get_request( qw// );
    };

    get '/logout' => sub {
        app->destroy_session;
        redirect '/';
    };

    get '/del/:user' => sub {
        what_is_next rt_user_del
        get_session( qw/login passwd/ )
        , get_param( qw/user/ )
        , get_request( qw/referer/ );
    };

    # add a user => registration
    post '/add' => sub {
        what_is_next rt_user_add
        get_session( qw// )
        , get_param( qw/userid firstname secondname pseudo passwd address admin
            town postalcode email/)
        , get_request( qw/referer/ );
    };

    get '/toggleadmin/:user' => sub {
        what_is_next rt_user_toggleadmin
        get_session( qw/login passwd/ )
        , get_param( qw/user/ )
        , get_request( qw/referer/ );
    };

    post '/login' => sub {
        what_is_next rt_user_login
        get_session( qw/login/ )
        , get_param( qw/login password/ )
        , get_request( qw/referer/ );
    };
};

prefix '/contractentry' => sub {
    get '/list/:contractid' => sub {
        what_is_next rt_contractentry_list
        get_session( qw/login passwd/ )
        , get_param( qw/contractid/ )
        , get_request( qw// );
    };

    any '/add/:contractid' => sub {
        what_is_next rt_contractentry_add
        get_session( qw/login passwd/ )
        , get_param(qw/contractid contractentryid startdate duration nb/)
        , get_request( qw// );
    };

    get '/del/:contractentryid' => sub {
        what_is_next rt_contractentry_del
        get_session( qw/login passwd/ )
        , get_param(qw/contractentryid/)
        , get_request( qw/referer/ );
    };

};

prefix '/contract' => sub {

    get '/list' => sub {
        what_is_next rt_contract_list
        get_session( qw/login passwd/ )
        , get_param( qw// )
        , get_request( qw// );
    };

    get '/genpdf/:contractid' => sub {
        what_is_next rt_contract_genpdf
        get_session( qw/login passwd/ )
        , get_param( qw/contractid/ )
        , get_request( qw/referer/ );
    };

    get '/del/:contractid' => sub {
        what_is_next rt_contract_del
        get_session( qw/login passwd/ )
        , get_param( qw/contractid/ )
        , get_request( qw// );
    };

    any '/add' => sub {
        what_is_next rt_contract_add
        get_session( qw/login passwd/ )
        , get_param(qw/contractid userid contracttype payment lastpaymentdate
            setupdate emissiondate/)
        , get_request(qw/referer/);
    };
};

true;
