package Git::MassCommitLog;

use warnings;
use strict;
use base 'Badger::Base';

use Carp;
use IO::Dir;
use Class::Date qw /date/;
=head1 NAME

Git::MassCommitLog - Perl extension for fetching commit info from directory with bunch of git repositories.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';
our $GITLOGFORMAT = q/format:"%H|%an <%ae>|%ai|%s"/;
our $GLOBAL_COMMIT_LIMIT = 100;
my @repos;
my $commits;

=head1 SYNOPSIS

	use Git::MassCommitLog;

	my $gitLog = Git::MassCommitLog(
		dir			=> 'your_dir_with_repositories',
		ignoreMessagePattern'	=> [ 'pattern1$', 'p[ae]ttern2', ],
		ignoreAuthorPattren'	=> [ 'bad_author_name1$', 'bad_author_name2', ],
		ignoreReposPattern	=> [ 'repo_name1$', 'repo_name2', ],
		since			=> '2012-10-01', #must be understanded by git (man 1 git-log)
	);

	my @commits		= $gitLog->repoCommits ('repoName');
	my @last_5_commits	= $gitLog->repoCommits ('repoName', 5);

	my @all_commits		= $gitLog->commits ();
	my @last_5_all_commits	= $gitlog->commits (5);

=head1 DESCRIPTION

This module is designed for geathering commit statistics from multiple GIT repositories, located in one folder. It searches for repository  subfolders (/\.git$/) in the folder, given by the 'dir' parameter. 

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
	(my $self, my $repo, my $limit) = @_;
	$limit=$GLOBAL_COMMIT_LIMIT if not $limit;
	return @{$self->{commits}{$repo}} if $limit > $#{$self->{commits}{$repo}};
	return @{$self->{commits}{$repo}}[-$limit...-1];

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
	@commits = sort { (my $aKey) = keys %{$a}; (my $bKey) = keys %{$b}; $a->{$aKey}{date} cmp $b->{$bKey}{date}; } @commits; #Гыгы. вопщем при сравнении мы берем первый попавшийся ключ (а он там один, и является хешем коммита), и получаем из него значение. Значение является экземпляром Class::Date, которое поддерживает сравнивание.

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
		next if not $self->_testRepoForIgnoring($dir);
		$d{$dir} = '';
		
	}
	push @{$self->{@repos}}, $_ foreach sort keys %d; #пущай все репозитории хранятся в алфавитном порядке
}
sub _getCommits
{
	my $self = shift;
	my $timeLimit = "6.months";
	$timeLimit = $self->{config}{since} if exists $self->{config}{since} and $self->{config}{since};

	foreach my $repo (@{$self->{@repos}}){
		$self->debug("Searching for commits in $repo...");
		open(my $gitO, "git --no-pager --git-dir=$self->{config}{dir}/$repo.git log --since=$timeLimit --pretty=$GITLOGFORMAT  --reverse -$GLOBAL_COMMIT_LIMIT|") or confess $!;
		while(<$gitO>)
		{
			chomp;
			my @a = split /\|/, $_;
			next if not $self->_testCommitForIgnoring(@a);
			my %c;
			$c{$a[0]}{author}	= $a[1];
			$c{$a[0]}{date}		= date ($a[2]);
			$c{$a[0]}{message}	= $a[3];
			$c{$a[0]}{repo}		= $repo;
			push @{$self->{commits}{$repo}}, \%c;
		}
	}
}
sub _testRepoForIgnoring
{
	(my $self, my $repo) = @_;

	if(exists $self->{config}{ignoreReposPattern})
	{
		foreach my $regex (@{$self->{config}{ignoreReposPattern}})
		{
			if($repo =~ /$regex/)
			{
				return 0;
			}
		}
	}
	return 1;
}

sub _testCommitForIgnoring
{
	my $self = shift;
	my @commit = @_;

	if(exists $self->{config}{ignoreMessagePattern})
	{
		foreach my $regex (@{$self->{config}{ignoreMessagePattern}})
		{
			if($commit[3] =~ /$regex/)
			{
				return 0;
			}
		}
	}
	if(exists($self->{config}{ignoreAuthorPattern}))
	{
		foreach my $regex (@{$self->{config}{ignoreAuthorPattern}})
		{
			if($commit[1] =~ /$regex/)
			{
				return 0;
			}
		}
	}

	return 1;
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
