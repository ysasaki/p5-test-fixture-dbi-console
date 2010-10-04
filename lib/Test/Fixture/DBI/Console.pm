package Test::Fixture::DBI::Console;
use strict;
use warnings;
use DBI;
use UNIVERSAL::require;
use base qw/Class::Accessor::Fast/;

__PACKAGE__->mk_accessors(qw/database dbh/);

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

    $self->setup_db();
    $self;
}

sub setup_db {
    my $self = shift;

    my $db_class = __PACKAGE__ . '::' . lc $self->{type};
    {
        local $@;
        $db_class->use or die $@;
    }

    my $db = $db_class->new( %{ $self->{database_opts} } );
    if ($db) {
        $self->database($db);

        my $dbh = DBI->connect( dsn => $db->dsn ) or die $DBI::errstr;
        $self->dbh($dbh);
    }
    else {
        die "cannot start database $self->{type}";
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
