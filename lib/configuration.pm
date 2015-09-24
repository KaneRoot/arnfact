package configuration;
use YAML::XS;
use URI;

use fileutil ':all';
use Exporter 'import';
# what we want to export eventually
our @EXPORT_OK = qw/get_cfg/;

# bundle of exports (tags)
our %EXPORT_TAGS = ( all => [qw/get_cfg/] );

sub is_conf_file {
    my $f = shift;

    unless(-f $f) {
        die "$f : not a file";
    }

    unless(-r $f) {
        die "$f : not readable";
    }

    unless(-T $f) {
        die "$f : not plain text";
    }
}

sub get_cfg {
    my ($cfgdir) = @_;

    $cfgdir //= './conf/';
    my $f = "$cfgdir/config.yml";

    is_conf_file $f;
    YAML::XS::LoadFile($f);
}

1;
