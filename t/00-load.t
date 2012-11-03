#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Git::MassCommitLog' ) || print "Bail out!
";
}

diag( "Testing Git::MassCommitLog $Git::MassCommitLog::VERSION, Perl $], $^X" );
