package Test::Fixture::DBI::Console;
use strict;
use warnings;
use File::Temp;
use Term::ReadLine;
use UNIVERSAL::require;
use Text::TabularDisplay;
use Test::Fixture::DBI;
use Test::Fixture::DBI::Util;
use Test::Fixture::DBI::Console::SQL;
use DBI;
use YAML::Syck;
use base qw/Class::Accessor::Fast/;

__PACKAGE__->mk_accessors(qw/database sql/);

our $VERSION = '0.01_01';
our $DEBUG = $ENV{FIXTURE_DEBUG} ? 1 : 0;

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
        database_opts => $args{database_opts} || +{},
        sql           => Test::Fixture::Console::SQL->new,
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

sub connect {
    my $self = shift;
    my $dbh  = DBI->connect( $self->database->connect_info,
        { RaiseError => 0, PrintError => 1, AutoCommit => 1 } )
        or die $DBI::errstr;
    return $dbh;
}

sub get_term {
    my $self   = shift;
    my $term   = Term::ReadLine->new(__PACKAGE__);
    my $prompt = 'fixture> ';
    return $term, $prompt;
}

sub run {
    my $self = shift;

    # avoid buffering
    local $| = 1;

    my $dbh = $self->connect();
    my ( $term, $prompt ) = $self->get_term();

    my $sth;
    my $sql_delimiter = ';';

LOOP:
    while ( defined( my $input = $term->readline($prompt) ) ) {
        if ( $input =~ qr/^\s*(?:quit|exit)/ ) {
            last;
        }
        elsif ( $input =~ qr/^\s*make_database/ ) {
            my ( $cmd, $file ) = split /\s/, $input;
            $file ||= _new_file('database');
            make_database_yaml( $dbh, $file );
            printf "Dump database schema to file: %s\n", $file;

            $self->sql->reset;
        }
        elsif ( $input =~ qr/^\s*make_fixture/ ) {

            # FIXME I would like to take more arguments for tables and ids.
            my ( $cmd, $file ) = split /\s/, $input;
            $file ||= _new_file('fixture');

            my $tables = $dbh->selectcol_arrayref('SHOW TABLES');
            my $data;

            # TODO use return value of make_fixture_yaml
            for my $table (@$tables) {
                make_fixture_yaml( $dbh, $table, [qw/id/],
                    "SELECT * FROM $table", $file );
                push @$data, _slurp($file);
            }
            _dump( $file, $data );

            printf "Create fixture file: %s\n", $file;

            $self->sql->reset;
        }
        elsif ( $input =~ qr/^\s*construct_database/ ) {
            my ( $cmd, $file ) = split /\s/, $input;
            unless ( -e $file and -r _ ) {
                print "file does not exists or not readable: $file\n";
            }
            else {
                local $dbh->{AutoCommit} = 0;
                construct_database(
                    dbh      => $dbh,
                    database => $file,
                );

                print "Load database schema from $file\n";
            }

            $self->sql->reset;
        }
        elsif ( $input =~ qr/^\s*construct_fixture/ ) {
            my ( $cmd, $file ) = split /\s/, $input;
            unless ( -e $file and -r _ ) {
                print "file does not exists or not readable: $file\n";
            }
            else {
                local $dbh->{AutoCommit} = 0;
                construct_fixture(
                    dbh     => $dbh,
                    fixture => $file,
                );

                print "Load fixture from $file\n";
            }

            $self->sql->reset;
        }
        elsif ( $input =~ /^\s*delimiter\s+(.+)/i ) {

            # TODO This code was not tested yet
            $sql_delimiter = $1;
            $dbh->do($input);

        }
        elsif ( $input =~ /$sql_delimiter/ ) {

            # TODO I must add some code for @rest.
            my ( $chunk, @rest ) = split /$sql_delimiter/, $input;

            $self->sql->push($chunk);
            my $sql = $self->sql->fetch;
            warn "Exec SQL: $sql" if $DEBUG;

            my $show_table = _can_show_table($sql);
            unless ( $sth = $dbh->prepare($sql) ) {
                next;
            }

            my $rv;
            unless ( $rv = $sth->execute ) {
                next;
            }

            if ($show_table) {

                # TODO Text::TD has a bug related columns length.
                # So avoid it, we create object in this scope.
                my $table = Text::TabularDisplay->new;
                $table->columns( @{ $sth->{'NAME'} } );

                while ( my $row = $sth->fetchrow_arrayref ) {
                    $table->add($row);
                }

                printf "%s\n", $table->render;
            }

            $sth->finish;
            if ($rv) {
                printf "%d rows%s\n", $rv,
                    (
                      $sql =~ /^insert/i ? 'rows inserted'
                    : $sql =~ /^update/i ? 'rows affected'
                    : ''
                    );
            }

            if (@rest) {
                $input = join ' ', @rest;
                goto LOOP;
            }
        }
        else {
			$self->sql->push($input);
        }
    }

    $dbh->disconnect or die $dbh->errstr;
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

sub _slurp {
    my $file = shift;

    my $data = YAML::Syck::LoadFile($file);
    return @$data;
}

sub _dump {
    my ( $file, $data ) = @_;
    YAML::Syck::DumpFile( $file, $data );
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

Yoshihiro Sasaki E<lt>ysasaki {at} cpan.orgE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
