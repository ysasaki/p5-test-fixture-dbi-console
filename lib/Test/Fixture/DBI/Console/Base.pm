package Test::Fixture::DBI::Console::Base;
use strict;
use warnings;
use base qw/Class::Accessor::Fast/;
use IPC::Open3;
use AnyEvent;

__PACKAGE__->mk_accessors(
    qw/console_out server client_cmd client_in client_out args/);

sub new {
    my $class = shift;
    my %args  = @_;
    my $self  = bless {
        console_out => delete $args{console_out},
        server      => undef,
        client_cmd  => [],
        client_out  => undef,
        client_in   => undef,
        args        => \%args
    }, $class;

    $self->set_server();
    $self->set_client();

    $self;
}

# return server object like Test::mysqld
sub get_server { die 'Subclasses must be overload this method' }

sub set_server {
    my $self = shift;
    $self->server( $self->get_server );
}

# return client program name passed for IPC::Open3
sub get_client { die 'Subclasses must be overload this method' }

sub set_client {
    my $self         = shift;
    my $cmd_and_args = $self->get_client;
    $self->client_cmd($cmd_and_args);

    my $console_out = $self->console_out;
    my ( $in, $out );

    # TODO client in, out not worked
    # I wanna pass data from client's out to console's out
    my $pid = open3( $in, $out, 0, @$cmd_and_args );
    die "client cmd failed" unless defined $pid;
    print $console_out "Connecting " . join( ' ', @$cmd_and_args ) . "\n";

    my $w;
    $w = AnyEvent->io(
        fh   => $out,
        poll => 'r',
        cb   => sub {
            print $console_out "callbacked\n";
            while (<$out>) {
                print $console_out $_;
            }
        },
    );

    $self->client_in($in);
    $self->client_out($out);
}

# write data to client's STDIN
sub client_write {
    my $self = shift;
    my $cmd  = shift;
    my $in   = $self->client_in;
    print $in $cmd;
}
1;
