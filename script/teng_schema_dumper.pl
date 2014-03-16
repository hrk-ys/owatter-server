use strict;
use warnings;
use DBI;
use FindBin;
use File::Spec;
use Teng::Schema::Dumper;

use Owatter;
my $c = Owatter->bootstrap;

my @schema_list;
for my $dbh (( $c->db->dbh )) {
    my $tables = $dbh->selectcol_arrayref('show tables');

    my $schema = Teng::Schema::Dumper->dump(
        dbh       => $dbh,
        tables    => $tables,
        namespace => 'Owatter::DB'
    );

    push @schema_list, $schema;
}

my $schema_pm = <<PM;
package Owatter::DB::Schema;
use strict;
use warnings;
use Teng::Schema::Declare;
PM

$schema_pm .= join "\n", @schema_list, '1;';

my $dest =
  File::Spec->catfile( $FindBin::Bin, '..', 'lib', 'Owatter', 'DB', 'Schema.pm' );
open my $fh, '>', $dest or die "cannot open file '$dest': $!";
print {$fh} $schema_pm;
close;
