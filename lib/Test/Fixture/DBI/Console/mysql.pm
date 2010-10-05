package Test::Fixture::DBI::Console::mysql;
use strict;
use warnings;
use base qw/Test::Fixture::DBI::Console::Base/;
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

sub get_client {
    my $self = shift;

    # FIXME I would not like to call private method in Test::mysqld.
    my $prog = Test::mysqld::_find_program(qw/mysql/);
    unless ($prog) {
        die 'mysql client not found';
    }

    my @args;
    push @args, '-u', $self->_user();
    push @args, '-D', $self->_dbname();

    my $my_cnf = $self->server->my_cnf;
    if ( $my_cnf->{socket} ) {
        push @args, '-S', $my_cnf->{socket};
    }
    else {
        my $host = $my_cnf->{'bind-address'} || '127.0.0.1';
        push @args, '-h', $host;
        push @args, '-P', $my_cnf->{port} if $my_cnf->{port};
    }

    return [ $prog, @args ];
}

sub _user {
    my $self = shift;
    my ($user) = $self->server->dsn =~ /user=(\w+)/;
    return $user || 'root';
}

sub _dbname {
    my $self = shift;
    my ($dbname) = $self->server->dsn =~ /dbname=(\w+)/;
    return $dbname || 'test';
}
1;
