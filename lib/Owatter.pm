package Owatter;
use strict;
use warnings;
use utf8;
use parent qw/Amon2/;
use 5.008001;

use Log::Minimal::Instance;
use JSON::XS;

__PACKAGE__->load_plugin(qw/DBI/);

# initialize database
use DBI;

sub setup_schema {
    my $self        = shift;
    my $dbh         = $self->dbh();
    my $driver_name = $dbh->{Driver}->{Name};
    my $fname       = lc("sql/${driver_name}.sql");
    open my $fh, '<:encoding(UTF-8)', $fname or die "$fname: $!";
    my $source = do { local $/; <$fh> };
    for my $stmt ( split /;/, $source ) {
        next unless $stmt =~ /\S/;
        $dbh->do($stmt) or die $dbh->errstr();
    }
}

use Teng;
use Teng::Schema::Loader;
use Owatter::DB;
use Owatter::DB::Schema;
my $schema;

sub db {
    my $self = shift;
    if ( !defined $self->{db} ) {
        my $conf = $self->config->{'DBI'}
          or die "missing configuration for 'DBI'";
        my $dbh = DBI->connect( @{$conf} );
        $self->{db} = Owatter::DB->new(
            dbh    => $dbh,
            schema => Owatter::DB::Schema->instance(),
        );
    }
    return $self->{db};
}

my $log;

sub debug {
    my ( $self, @args ) = @_;

    local $Log::Minimal::AUTODUMP = 1;
    $log = Log::Minimal::Instance->new(
        base_dir => 'var/log',
        pattern  => 'debug.log.%Y%m%d',    # File::Stamped style
    );
    $log->debugf(@args);
}

my $json;
sub json {
	$json ||= JSON::XS->new()->utf8(1);
	return $json;
}

sub twitter {
    my ( $self, %args ) = @_;
    return Net::Twitter->new(
        traits          => [qw/API::RESTv1_1/],
        consumer_key    => "srBnYjoP1D3YvladL7tQovqqo",
        consumer_secret => "bImKBeLRdMi4E3TzEVMZ3vBUjTfVbEvh2flsgVJI70wq1ut5nD",
        ssl             => 1,
        %args
    );
}

1;
