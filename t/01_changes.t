use strict;
use warnings;
use utf8;

use FindBin;
use Test::More;
use Capture::Tiny qw(capture);
use lib "$FindBin::Bin/lib";

use t::Util qw(setup_changes_file);

my $changes_sh = "$FindBin::Bin/../changes.sh";

subtest 'Abort' => sub {
    subtest 'When passed argument is missing' => sub {
        my $status;
        my ($stdout, $stderr, @result) = capture {
            $status = system("$changes_sh");
        };
        ok $status > 0;
        like $stderr, qr/\[ERROR\] CHANGES file is not given/;
    };

    subtest 'When passed argument is not existed on FS' => sub {
        my $status;
        my ($stdout, $stderr, @result) = capture {
            $status = system("$changes_sh __NOT_EXISTED_CHANGES__");
        };
        ok $status > 0;
        like $stderr, qr/\[ERROR\] Given CHANGES file is not found/;
    };

    subtest '$ENV{EDITOR} is not set' => sub {
        local $ENV{EDITOR} = undef;

        my ($fh, $filename) = setup_changes_file();

        my $status;
        my ($stdout, $stderr, @result) = capture {
            $status = system(qq{echo "\n\n" | $changes_sh $filename});
        };

        ok $status > 0;
        like $stderr, qr/\[ERROR\] Environment variable '\$EDITOR' is not set, abort/;
    };

    subtest 'Abort manually' => sub {
        my ($fh, $filename) = setup_changes_file();

        my $status;
        my ($stdout, $stderr, @result) = capture {
            $status = system(qq{echo "\nn\n" | $changes_sh $filename});
        };

        ok $status > 0;
        like $stderr, qr/Aborted/;
    };
};

subtest 'Pass' => sub {
    subtest 'Default version' => sub {
        local $ENV{EDITOR} = "$FindBin::Bin/script/replace.pl";

        my ($fh, $filename) = setup_changes_file();

        {
            my $status = system(qq{echo "\n\n" | $changes_sh $filename});
            is $status, 0;

            open my $fh, '<', $filename;
            my $content = do { local $/; <$fh> };
            like $content, qr/^0[.]0[.]1: [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$/m;
            unlike $content, qr/^0[.]0[.]2: [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$/m;
        }

        {
            my $status = system(qq{echo "\ny\n" | $changes_sh $filename});
            is $status, 0;

            open my $fh, '<', $filename;
            my $content = do { local $/; <$fh> };
            like $content, qr/^0[.]0[.]1: [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$/m;
            like $content, qr/^0[.]0[.]2: [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$/m;
        }
    };

    subtest 'Specified version' => sub {
        local $ENV{EDITOR} = "$FindBin::Bin/script/replace.pl";

        my ($fh, $filename) = setup_changes_file();

        {
            my $status = system(qq{echo "1.0.0\n\n" | $changes_sh $filename});
            is $status, 0;

            open my $fh, '<', $filename;
            my $content = do { local $/; <$fh> };
            like $content, qr/^1[.]0[.]0: [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$/m;
            unlike $content, qr/^1[.]1[.]0: [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$/m;
        }

        {
            my $status = system(qq{echo "1.1.0\nY\n" | $changes_sh $filename});
            is $status, 0;

            open my $fh, '<', $filename;
            my $content = do { local $/; <$fh> };
            like $content, qr/^1[.]0[.]0: [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$/m;
            like $content, qr/^1[.]1[.]0: [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$/m;
        }
    };

    subtest 'Specified version after default version' => sub {
        local $ENV{EDITOR} = "$FindBin::Bin/script/replace.pl";

        my ($fh, $filename) = setup_changes_file();

        {
            my $status = system(qq{echo "1.0.0\n\n" | $changes_sh $filename});
            is $status, 0;

            open my $fh, '<', $filename;
            my $content = do { local $/; <$fh> };
            like $content, qr/^1[.]0[.]0: [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$/m;
            unlike $content, qr/^1[.]0[.]1: [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$/m;
        }

        {
            my $status = system(qq{echo "\n\n" | $changes_sh $filename});
            is $status, 0;

            open my $fh, '<', $filename;
            my $content = do { local $/; <$fh> };
            like $content, qr/^1[.]0[.]0: [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$/m;
            like $content, qr/^1[.]0[.]1: [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$/m;
        }
    };

    subtest 'With invalid version at once' => sub {
        local $ENV{EDITOR} = "$FindBin::Bin/script/replace.pl";

        my ($fh, $filename) = setup_changes_file();

        my $status;
        my ($stdout, $stderr, @result) = capture {
            $status = system(qq{echo "__INVALID__\n1.0.0\n\n" | $changes_sh $filename});
        };
        is $status, 0;

        like $stderr, qr/Given next version does not conform to the version format: __INVALID__/;

        open $fh, '<', $filename;
        my $content = do { local $/; <$fh> };
        like $content, qr/^1[.]0[.]0: [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$/m;
    };

    subtest 'stochastic (in case of description empty)' => sub {
        local $ENV{EDITOR} = "$FindBin::Bin/script/stochastic_replace.pl";

        my ($fh, $filename) = setup_changes_file();

        my $status = system(qq{yes "" | $changes_sh $filename});
        is $status, 0;

        open $fh, '<', $filename;
        my $content = do { local $/; <$fh> };
        like $content, qr/^0[.]0[.]1: [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$/m;
    };

    subtest 'with next version via cmd argument' => sub {
        local $ENV{EDITOR} = "$FindBin::Bin/script/replace.pl";

        my ($fh, $filename) = setup_changes_file();

        my $status = system(qq{echo "\n" | $changes_sh $filename 2.3.4});
        is $status, 0;

        open $fh, '<', $filename;
        my $content = do { local $/; <$fh> };
        like $content, qr/^2[.]3[.]4: [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$/m;
    };
};

done_testing;

