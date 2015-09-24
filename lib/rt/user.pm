package rt::user;

use utf8;
use warnings qw( FATAL utf8 );
use open qw( :encoding(UTF-8) :std );

use configuration ':all';
use encryption ':all';
use app;

use YAML::XS;

use Exporter 'import';
# what we want to export eventually
our @EXPORT_OK = qw/
rt_user_login
rt_user_del
rt_user_toggleadmin
rt_user_add
rt_user_home
/;

# bundle of exports (tags)
our %EXPORT_TAGS = ( all => [qw/
        rt_user_login
        rt_user_del
        rt_user_toggleadmin
        rt_user_add
        rt_user_home
        /] ); 

sub rt_user_login {
    my ($session, $param, $request) = @_;
    my $res;

    # Check if user is already logged
    if ( exists $$session{login} && length $$session{login} > 0 ) {
        $$res{deferred}{errmsg} = q{Vous êtes déjà connecté.};
        $$res{route} = '/';
        return $res;
    }

    # Check user login and password
    unless ( exists $$param{login} 
        && exists $$param{password} 
        && length $$param{login} > 0
        && length $$param{password} > 0 ) {
        $$res{deferred}{errmsg} = q{Il manque des paramètres.};
        $$res{route} = '/';
        return $res;
    }

    eval {
        my $app = app->new(get_cfg());
        my $pass = encrypt($$param{password});
        my $user = $app->auth($$param{login}, $pass);

        unless( $user ) {
            $$res{deferred}{errmsg} = 
            q{Impossible de se connecter (login ou mot de passe incorrect).};
            $$res{route} = '/';
            return $res;
        }

        $$res{addsession}{login}  = $$param{login};
        $$res{addsession}{passwd} = $pass;
        # TODO adds a freeze feature, not used for now
        # $$res{addsession}{user}     = freeze( $user );

        if( $$user{admin} ) {
            $$res{route} = '/admin';
        }
        else {
            $$res{route} = '/user/home';
        }

        $app->disconnect();
    };

    if( $@ ) {
        $$res{deferred}{errmsg} = q{Impossible de se connecter ! } . $@;
        $$res{sessiondestroy} = 1;
        $$res{route} = '/';
    }

    $res
}

sub rt_user_del {
    my ($session, $param, $request) = @_;
    my $res;

    unless ( $$param{user} ) {
        $$res{deferred}{errmsg} = q{Le nom d'utilisateur n'est pas renseigné.};
        return $res;
    }

    eval {
        my $app = app->new(get_cfg());

        my $user = $app->auth($$session{login}, $$session{passwd});

        if ( $user && $$user{admin} || $$session{login} eq $$param{user} ) {
            $app->delete_user($$param{user});
        }
        $app->disconnect();
    };

    if ( $@ ) {
        $$res{deferred}{errmsg} = 
        "L'utilisateur $$res{user} n'a pas pu être supprimé. $@";
    }

    if( $$request{referer} ) {
        $$res{route} = $$request{referer};
    }
    else {
        $$res{route} = '/';
    }

    $res
}

sub rt_user_toggleadmin {
    my ($session, $param, $request) = @_;
    my $res;

    unless( $$param{user} ) {
        $$res{deferred}{errmsg} = q{L'utilisateur n'est pas défini.};
        $$res{route} = $$request{referer};
        return $res;
    }

    eval {
        my $app = app->new(get_cfg());
        my $user = $app->auth($$session{login}, $$session{passwd});

        unless ( $user && $$user{admin} ) {
            $$res{deferred}{errmsg} = q{Vous n'êtes pas administrateur.};
            return $res;
        }

        $app->toggle_admin($$param{user});
        $app->disconnect();
    };

    if( $$request{referer} =~ '/admin' ) {
        $$res{route} = $$request{referer};
    }
    else {
        $$res{route} = '/';
    }

    $res
}

sub rt_user_add {
    my ($session, $param, $request) = @_;
    my $res;

    $$res{route} = $$request{referer};

    my @elems = qw/userid firstname secondname pseudo passwd address admin town
    postalcode email/;

    my @missingitems;

    for(@elems) {
        unless ($$param{$_}) {
            next if ($_ eq "admin" && exists $$param{admin});
            push @missingitems, $_ unless $$param{$_};
        }
    }

    if(@missingitems) {
        $$res{deferred}{errmsg} = "Il manque : " . join ', ', @missingitems;
        return $res;
    }

    my $pass = encrypt($$param{passwd});

    # values
    my $v = {(
        userid          => $$param{userid}
        , firstname     => $$param{firstname}
        , secondname    => $$param{secondname}
        , pseudo        => $$param{pseudo}
        , email         => $$param{email}
        , address       => $$param{address}
        , town          => $$param{town}
        , postalcode    => $$param{postalcode}
        , passwd        => $pass
        , admin         => $$param{admin}
        )};

    eval {
        my $app = app->new(get_cfg());
        $app->register_user($v);
        $app->disconnect();

        $$res{deferred}{succmsg} = 
        "Enregistrement de l'utilisateur $$param{userid}, mdp : $pass .";
    };

    if($@) {
        $$res{deferred}{errmsg} = q{Enregistrement mal passé. } . $@;
        $$res{route} = '/admin';
        return $res;
    }

    $res
}

sub rt_user_home {
    my ($session, $param, $request) = @_;
    my $res;

    $$res{template} = 'home';

    eval {
        my $app = app->new(get_cfg());

        my $user = $app->auth($$session{login}, $$session{passwd});

        unless( $user ) {
            $$res{deferred}{errmsg} = q{Problème de connexion à votre compte.};
            $$res{sessiondestroy} = 1;
            $$res{route} = '/';
            return $res;
        }

        $$res{params} = {
            login               => $$session{login}
            , admin             => $$user{admin}
        };
        $app->disconnect();
    };

    if( $@ ) {
        $$res{sessiondestroy} = 1;
        $$res{deferred}{errmsg} = q{On a chié quelque-part. } . $@;
        $$res{route} = '/';
    }

    $res
}

1;
