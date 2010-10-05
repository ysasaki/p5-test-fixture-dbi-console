package Test::Fixture::DBI::Console;
use strict;
use warnings;
use UNIVERSAL::require;
use IPC::Open3;
use IO::Select;
use Term::ReadLine;
use base qw/Class::Accessor::Fast/;

__PACKAGE__->mk_accessors(qw/database term console_out/);

our $VERSION = '0.01';

sub new {
    my $class = shift;
    my %args  = @_;
    unless ( $args{database} ) {
        die 'new must be passed database type';
    }

    my $self = bless {
        dbh           => undef,
        database      => undef,
        type          => $args{database},
        database_opts => $args{database_opts} || +{}
        },
        $class;

    $self->setup_term();
    $self->setup_db();
    $self;
}

sub setup_term {
    my $self = shift;
    my $term = Term::ReadLine->new('Test::Fixture::DBI::Console');
    $self->console_out( $term->OUT || \*STDOUT );
    $self->term($term);
}

sub setup_db {
    my $self = shift;

    my $db_class = __PACKAGE__ . '::' . lc $self->{type};
    {
        local $@;
        $db_class->use or die $@;
    }

    my $db = $db_class->new(
        console_out => $self->console_out,
        %{ $self->{database_opts} }
    );
    if ($db) {
        $self->database($db);
    }
    else {
        die "cannot start database $self->{type}";
    }
}

sub COMMAND_RE () {qr/^(?:make_database|make_fixture|exit)/}

sub run {
    my $self = shift;

    my $term   = $self->term;
    my $prompt = 'fixture> ';
    my $cmd_re = COMMAND_RE;
    while ( defined( $_ = $term->readline($prompt) ) ) {
        if (/$cmd_re/) {

            # TODO
        }
        else {
            print $self->database->client_write($_);
        }
    }
}

1;
__END__

=head1 NAME

Test::Fixture::DBI::Console -

=head1 SYNOPSIS

  use Test::Fixture::DBI::Console;

=head1 DESCRIPTION

Test::Fixture::DBI::Console is

=head1 AUTHOR

aloelight E<lt>aloelight {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
