use strict;
use warnings;
use utf8;

use FindBin;
use Test::More;
use File::Temp qw(tempfile);
use Capture::Tiny qw(capture);

my $release_sh = "$FindBin::Bin/../release.sh";

subtest 'Initialize' => sub {
    subtest 'Abort' => sub {
        subtest 'Missing project name' => sub {
            my $status;
            my ($stdout, $stderr, @result) = capture {
                $status = system("$release_sh --init");
            };
            ok $status > 0;
            like $stderr, qr/\[ERROR\] Failed to initialize because description is missing/;
        };

        subtest 'Missing change file path' => sub {
            my $status;
            my ($stdout, $stderr, @result) = capture {
                $status = system("$release_sh --init PROJECT");
            };
            ok $status > 0;
            like $stderr, qr/\[ERROR\] Failed to initialize because description is missing/;
        };
    };

    subtest 'Pass' => sub {
        my ($fh, $filename) = tempfile;

        my $status;
        my ($stdout, $stderr, @result) = capture {
            $status = system("$release_sh --init myproj $filename");
        };
        is $status, 0;
        like $stderr, qr/Initialized!/;

        open $fh, '<', $filename;
        my $contents = do { local $/; <$fh> };
        is $contents, <<'EOS'
Revision history for myproj

%%NEXT_VERSION%%

EOS
    };
};

done_testing;

