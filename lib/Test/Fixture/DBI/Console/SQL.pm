package Test::Fixture::Console::SQL;

use strict;
use warnings;

sub new {
    my $class = shift;
    $class = ref $class || $class;
    bless [], $class;
}

sub push {
    my $self = shift;
	for my $chunk ( @_ ) {
		push @$self, _trim($chunk);
	}
}

sub fetch {
    my $self = shift;
    my $stmt = join ' ', @$self;
    $self->reset;
    return $stmt;
}

sub reset {
    my $self = shift;
    $self = $self->new;
}

sub _trim {
    my $chunk = shift;
    $chunk =~ s/^\s+$//;
    $chunk =~ s/(?:\r)?\n$/ /;
    $chunk;
}

1;

__END__

=head1 NAME

Test::Fixture::DBI::Console::SQL - store chunk of sql and join them

=head1 SYNOPSIS

  use Test::Fixture::DBI::Console::SQL;
  my $sql = Test::Fixture::DBI::Console::SQL->new;
  $sql->push($chunk);

  my $stmt = $sql->fetch;
  $dbh->do($stmt);

=head1 METHOD

=over 4

=item $sql = Test::Fixture::DBI::Console::SQL->new()

Create Test::Fixture::DBI::Console::SQL object and return it.

=item $sql->push($chunk)

Store $chunk in SQL objecct.

=item $stmt = $sql->fetch($chunk)

Return SQL statement stored in object. If this method called, reset sql data in object.

=item $sql->reset()

clear sql data in object.

=back

=head1 AUTHOR

Yoshihiro Sasaki E<lt>ysasaki {at} cpan.orgE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
