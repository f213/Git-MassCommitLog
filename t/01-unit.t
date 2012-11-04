#!/usr/bin/perl 


use Test::More;
use Class::Date qw /date/;
use Data::Dumper;
use Carp;

my $TESTS = 9;
plan tests => $TESTS;
SKIP: {
	skip 'For unit testing we need repository examples. Sorry for that, but i used my company live repositories for testing, so i cannot publish them.', $TESTS if not -d 't/repos';
	use Git::MassCommitLog;
	
	my $gl = Git::MassCommitLog->new(dir=>'t/repos', DEBUG=>1);

	my @repos=(
		'edcamp.ru',
		'intensor.ru',
		'shardostavka.ru',
	);
	is_deeply($gl->repos, \@repos, 'Test for getting repo list');

	my @c = (
		{'318cc6186eea04f2e274e4742eb0607338cd0b08' => {
			'author' => 'Fedor A Borshev <fedor@texas-faggott.shogo.ru>',
			'date' => date ("2012-08-28 13:01:43"),
			'message' => 'repo init',
			'repo'	=> 'edcamp.ru',
		}},
		{'07d9f87588402609f37cea16d7510b9ee9ff5935' => {
			'author' => 'karmanov <karmanov@shogo.ru>',
			'date' => date ("2012-08-28 14:26:13"),
			'message' => 'google',
			'repo'	=> 'edcamp.ru',
		}},
		{'c7080584f242a61cfa67b825476bfc322e475f59' => {
			'author' => 'skif <s@shogo.ru>',
			'date' => date ("2012-10-24 16:31:10"),
			'message' => "order - change year range refs #2476",
			'repo'	=> 'edcamp.ru',
		}},
	);
	my @res = $gl->repoCommits('edcamp.ru');
	is_deeply(\@res, \@c, 'Test fetching commits by repo');
	

	@c = (
		{'c7080584f242a61cfa67b825476bfc322e475f59' => {
			'author' => 'skif <s@shogo.ru>',
			'date' => date ("2012-10-24 16:31:10"),
			'message' => "order - change year range refs #2476",
			'repo'	=> 'edcamp.ru',
		}}
	);
	@res = $gl->repoCommits('edcamp.ru',1);
	is_deeply(\@res, \@c, 'Test fetching commits with limit');


	my @total_commits = $gl->commits();

	is($#total_commits, 67, 'Test fetching all commits in all repos');

	@c = (
		{'64a5ef982bd37a1b833a75a98845f8ccd747bbaf' => {
				author => 'skif <s@shogo.ru>',
				date => date("2012-11-02 17:54:27"),
				message => '+ search',
				repo => 'intensor.ru',
		}},
		{'e650ab89dd809ada3db496fc67a6a9bdd2d6c56d' => {
				author => 'skif <s@shogo.ru>',
				date => date("2012-11-02 17:57:19"),
				message => 'fix search',
				repo => 'intensor.ru',
		}},
	);
	
	@res = $gl->commits(2);
	is_deeply(\@res, \@c, 'Fetch last 2 commits from all repositories');
	

	$gl = Git::MassCommitLog->new(dir=>'t/repos', DEBUG=>1, 'ignoreMessagePattern' => ['^Merge branch', 'refs\ \#\d+',]);
	my @t = $gl->repoCommits('intensor.ru');
	is($#t, 54-23-5+1, 'Test ignoring commit messages'); #54 total commits, 23 commits with refs, 5 merges

	$gl = Git::MassCommitLog->new(dir=>'t/repos', DEBUG=>1, 'ignoreAuthorPattern' => ['skif',]);
	@t = $gl->repoCommits('intensor.ru');
	is($#t, 54-9, 'Test ignoring commit authors'); #54 total commits, 9 commits by author Skif


	$gl = Git::MassCommitLog->new(dir=>'t/repos', DEBUG=>1, 'ignoreReposPattern' => [ 'or\.ru$', 'avka.ru' ]);
	@t = $gl->commits();
	is($#t, 2, 'Test ignoring repos'); #must be 3 commits from edcamp.ru


	$gl = Git::MassCommitLog->new(dir=>'t/repos', DEBUG=>1, 'since' => '2012-11-01');
	@t = $gl->repoCommits('intensor.ru');
	is($#t, 5, 'Test fetching commits from some date');

}
