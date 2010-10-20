package Test::Fixture::DBI::Console::mysql;
use strict;
use warnings;
use base qw/Test::Fixture::DBI::Console::Backend/;
use Test::mysqld;

my %DEFAULT_OPTIONS = ( 'skip-networking' => '' );

sub get_server {
    my $self = shift;
    my $mysqld
        = Test::mysqld->new(
        my_cnf => { %DEFAULT_OPTIONS, %{ $self->args } } )
        or die $Test::mysqld::errstr;

    return $mysqld;
}

1;
