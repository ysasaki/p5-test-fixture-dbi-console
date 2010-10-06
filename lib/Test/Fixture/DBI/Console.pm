package Test::Fixture::DBI::Console;
use strict;
use warnings;
use File::Temp;
use Term::ReadLine;
use UNIVERSAL::require;
use Text::TabularDisplay;
use Test::Fixture::DBI::Util;
use DBI;
use base qw/Class::Accessor::Fast/;

__PACKAGE__->mk_accessors(qw/database/);

our $VERSION = '0.01';
our $DEBUG   = $ENV{FIXTURE_DEBUG} ? 1 : 0;

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
    }
    else {
        die "cannot start database $self->{type}";
    }
}

sub run {
    my $self = shift;

    my $dbh = DBI->connect( $self->database->connect_info,
        { RaiseError => 0, PrintError => 1, AutoCommit => 1 } )
        or die $DBI::errstr;

    my $term   = Term::ReadLine->new(__PACKAGE__);
    my $prompt = 'fixture> ';

    my $sql;
    my $sql_delimiter = ';';
    my $sth;

    while ( defined( my $input = $term->readline($prompt) ) ) {
        if ( $input =~ qr/^\s*(?:quit|exit)/ ) {
            last;
        }
        elsif ( $input =~ qr/^\s*make_database/ ) {
            my ( $cmd, $file ) = split /\s/, $input;
            $file ||= _new_file('database');
            make_database_yaml( $dbh, $file );
            printf "Create database schema file: %s\n", $file;
        }
        elsif ( $input =~ qr/^\s*make_fixture/ ) {

            # FIXME I would like to take more arguments for tables and ids.
            my ( $cmd, $file ) = split /\s/, $input;
            $file ||= _new_file('fixture');

            my $tables = $dbh->selectcol_arrayref('SHOW TABLES');
            for my $table (@$tables) {
                make_fixture_yaml( $dbh, $table, [qw/id/],
                    "SELECT * FROM $table", $file );
            }

            printf "Create fixture file: %s\n", $file;
        }
        elsif ( !$sql and $input =~ /^\s*delimiter\s+(.+)/i ) {

            # TODO change delemiter
            $sql_delimiter = $1;
            $dbh->do($input);

        }
        elsif ( $input =~ /$sql_delimiter/ ) {

            # TODO @rest don't use yet
            my ( $hunk, @rest ) = split /$sql_delimiter/, $input;

            $sql .= _trim($hunk);

            warn "Exec SQL: $sql" if $DEBUG;

            my $show_table = _can_show_table($sql);
            unless ( $sth = $dbh->prepare($sql) ) {
                next;
            }

            my $rv;
            unless ( $rv = $sth->execute ) {
                next;
            }

            if ( $show_table ) {
                # TODO Text::TD has a bug related columns length.
                # so we create object in this scope.
                my $table = Text::TabularDisplay->new;
                $table->columns( @{ $sth->{'NAME'} } );

                while ( my $row = $sth->fetchrow_arrayref ) {
                    $table->add($row);
                }

                printf "%s\n", $table->render;
            }

            $sth->finish;
            printf "Affected %d rows\n", $rv if $rv;

            # reset sql
            $sql = '';
        }
        else {
            $sql .= _trim($input);
        }
    }

    $dbh->disconnect or die $dbh->errstr;
}

sub _trim {
    my $hunk = shift;
    $hunk =~ s/^\s+$//;
    $hunk =~ s/(?:\r)?\n$/ /;
    $hunk;
}

sub _new_file {
    my $cmd = shift;
    File::Temp->new(
        TEMPLATE => $cmd . '_XXXX',
        SUFFIX   => '.yaml',
        UNLINK   => 0
    );
}

my $CAN_SHOW_TABLE = qr/^(?:select|show|desc)/i;
sub _can_show_table {
    my $sql = shift;
    return $sql =~ $CAN_SHOW_TABLE;
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
