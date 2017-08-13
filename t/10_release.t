use strict;
use warnings;
use utf8;

use t::Util qw(setup_changes_file);
use FindBin;
use Test::More;
use Capture::Tiny qw(capture);

my $release_sh = "$FindBin::Bin/../release.sh";

subtest 'Abort' => sub {
    subtest 'Argument is missing' => sub {
        local $ENV{PATH} = "$FindBin::Bin/script/mock_echo_git:" . $ENV{PATH}; # mock git

        my $status;
        my ($stdout, $stderr, @result) = capture {
            $status = system("$release_sh");
        };
        ok $status > 0;
        like $stderr, qr/\[ERROR\] CHANGES file is not given/;
    };

    subtest 'When passed argument is not existed on FS' => sub {
        local $ENV{PATH} = "$FindBin::Bin/script/mock_echo_git:" . $ENV{PATH}; # mock git

        my $status;
        my ($stdout, $stderr, @result) = capture {
            $status = system("$release_sh __NOT_EXISTED_CHANGES__");
        };
        ok $status > 0;
        like $stderr, qr/\[ERROR\] Given CHANGES file is not found/;
    };

    subtest 'When $ENV{GITHUB_TOKEN} is missing' => sub {
        local $ENV{PATH} = "$FindBin::Bin/script/mock_echo_git:" . $ENV{PATH}; # mock git

        my ($fh, $filename) = setup_changes_file();

        my $status;
        my ($stdout, $stderr, @result) = capture {
            $status = system("$release_sh $filename");
        };
        ok $status > 0;
        like $stderr, qr/\[ERROR\] Environment variable '\$GITHUB_TOKEN' is not set, abort/;
    };

    subtest 'When uncommitted files are existed' => sub {
        local $ENV{PATH} = "$FindBin::Bin/script/mock_echo_git:" . $ENV{PATH}; # mock git
        local $ENV{GITHUB_TOKEN} = 'github-token';

        my ($fh, $filename) = setup_changes_file();

        my $status;
        my ($stdout, $stderr, @result) = capture {
            $status = system("$release_sh $filename");
        };
        ok $status > 0;
        like $stderr, qr/\[ERROR\] Uncommitted files of git exists/;
    };
};

subtest 'Pass' => sub {
    local $ENV{EDITOR} = "$FindBin::Bin/script/replace.pl";
    local $ENV{PATH} = "$FindBin::Bin/script/mock_git:$FindBin::Bin/script/mock_curl:" . $ENV{PATH}; # mock commands
    local $ENV{GITHUB_TOKEN} = 'github-token';

    my ($fh, $filename) = setup_changes_file();

    my $status;
    my ($stdout, $stderr, @result) = capture {
        $status = system(qq{echo "\n\n" | $release_sh $filename});
    };

    is $status, 0;

    my $expected = <<'EOS';

This is test
-XPOST
-H
Authorization: token github-token
-d
{
  "tag_name": "0.0.1",
  "target_commitish": "master",
  "name": "0.0.1",
  "body": "\nThis is test\n",
  "draft": false,
  "prerelease": false
}
https://api.github.com/repos/moznion/releng.sh/releases
EOS
    is $stdout, $expected;
};

done_testing;

