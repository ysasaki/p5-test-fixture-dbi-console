package Test::Fixture::DBI::Console::mysql;
use strict;
use warnings;
use Test::mysqld;

my %DEFAULT_OPTIONS = ( 'skip-networking' => '' );

sub new {
    my $class  = shift;
    my %args   = ( %DEFAULT_OPTIONS, @_ );
    my $mysqld = Test::mysqld->new( my_cnf => {%args} )
        or die $Test::mysqld::errstr;
    return $mysqld;
}

1;
