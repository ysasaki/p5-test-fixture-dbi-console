package Test::Fixture::DBI::Console::Backend;
use strict;
use warnings;
use base qw/Class::Accessor::Fast/;

__PACKAGE__->mk_accessors(qw/server client_cmd args/);

sub new {
    my $class = shift;
    my %args  = @_;
    my $self  = bless {
        server      => undef,
        client_cmd  => [],
        args        => \%args
    }, $class;

    $self->set_server();
    $self;
}

# return server object like Test::mysqld
sub get_server { die 'Subclasses must be overload this method' }

sub set_server {
    my $self = shift;
    $self->server( $self->get_server );
}

sub connect_info {
    my $self = shift;
    return $self->server->dsn, $self->user, undef;
}

sub dsn {
    my $self = shift;
    $self->server->dsn;
}

sub user {
    my $self = shift;
    my ($user) = $self->server->dsn =~ /user=(\w+)/;
    return $user || 'root';
}

sub dbname {
    my $self = shift;
    my ($dbname) = $self->server->dsn =~ /dbname=(\w+)/;
    return $dbname || 'test';
}
1;
