package t::Util;
use strict;
use warnings;
use utf8;

use File::Temp qw(tempfile);

use parent 'Exporter';
our @EXPORT_OK = qw(setup_changes_file);

sub setup_changes_file {
    my ($fh, $filename) = tempfile;
    print $fh "Test\n%%NEXT_VERSION%%";

    return ($fh, $filename);
}

1;

