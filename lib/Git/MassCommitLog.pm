package Git::MassCommitLog;

use warnings;
use strict;
use base 'Badger::Base';

use Carp;
use IO::Dir;
use Class::Date qw /date/;
=head1 NAME

Git::MassCommitLog - The great new Git::MassCommitLog!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';
our $GITLOGFORMAT = q/format:"%H|%an <%ae>|%ai|%s"/;
our $GLOBAL_COMMIT_LIMIT = 50;
my @repos;
my $commits;

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Git::MassCommitLog;

    my $foo = Git::MassCommitLog->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=cut

sub init
{
	(my $self, my $p) = @_;

	$self->{config} = $p;
	$self->_getRepoList;
	$self->_getCommits;
	return $self;
}

sub repos
{
	my $self = shift;
	return $self->{@repos};
}
sub repoCommits
{
	(my $self, my $repo) = @_;
	return @{$self->{commits}{$repo}};
}
sub commits
{
	(my $self, my $limit) = @_;
	$limit=$GLOBAL_COMMIT_LIMIT*@{$self->repos} if not $limit;
	my @commits;
	foreach my $repo (@{$self->{@repos}})
	{
		push @commits, $_ foreach($self->repoCommits($repo));
	}
	@commits = sort { (my $aKey) = keys %{$a}; (my $bKey) = keys %{$b}; $a->{$aKey}{date} cmp $b->{$bKey}{date}; } @commits;

	return @commits if($limit>$#commits);
	return @commits[-$limit...-1];
}
sub _isGitRepo
{
	(my $self, my $path) = @_;
	if(system("git --git-dir=$self->{config}{dir}/$path show 2>/dev/null >/dev/null"))
	{
		return 0;
	}
	return 1;
}
sub _getRepoList
{
	my $self = shift;
	my %d;
	$self->debug("Searching for git repos in  $self->{config}{dir}");
	my $gitDir = IO::Dir->new($self->{config}{dir});
	while(my $dir = $gitDir->read)
	{
		next if $dir !~ m/\.git$/;
		next if not $self->_isGitRepo($dir);
		$dir =~ s/\.git$//;
		$d{$dir} = '';
		
	}
	push @{$self->{@repos}}, $_ foreach sort keys %d;
}
sub _getCommits
{
	my $self = shift;
	my $timeLimit = "6.months";
	$timeLimit = $self->{config}{since} if exists $self->{config}{since} and $self->{config}{since};

	foreach my $repo (@{$self->{@repos}}){
		$self->debug("Searching for commits in $repo...");
		open(my $gitO, "git --no-pager --git-dir=$self->{config}{dir}/$repo.git log --pretty=$GITLOGFORMAT  --reverse -$GLOBAL_COMMIT_LIMIT|") or confess $!;
		while(<$gitO>)
		{
			chomp;
			my @a = split /\|/, $_;
			#$self->{commits}{$repo}{$a[0]}{author}		= $a[1];
			#$self->{commits}{$repo}{$a[0]}{date}		= date ($a[2]);
			#$self->{commits}{$repo}{$a[0]}{message}		= $a[3];
			my %c;
			$c{$a[0]}{author}	= $a[1];
			$c{$a[0]}{date}		= date ($a[2]);
			$c{$a[0]}{message}	= $a[3];
			$c{$a[0]}{repo}		= $repo;
			push @{$self->{commits}{$repo}}, \%c;
		}
	}
}


=head1 AUTHOR

Fedor A Borshev, C<< <fedor at shogo.ru> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-git-masscommitlog at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Git-MassCommitLog>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Git::MassCommitLog


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Git-MassCommitLog>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Git-MassCommitLog>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Git-MassCommitLog>

=item * Search CPAN

L<http://search.cpan.org/dist/Git-MassCommitLog/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Fedor A Borshev.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Git::MassCommitLog
