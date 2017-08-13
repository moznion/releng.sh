#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

my $file = shift or die;

my $contents;
{
    open my $fh, '<', $file;
    $contents = do { local $/; <$fh> };
}

$contents =~ s/%%NEXT_VERSION%%/%%NEXT_VERSION%%\n\nThis is test/;

{
    open my $fh, '>', $file;
    print $fh $contents;
}

