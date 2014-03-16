package Owatter;
use strict;
use warnings;
use utf8;
use parent qw/Amon2/;
use 5.008001;

use Log::Minimal::Instance;

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

1;
