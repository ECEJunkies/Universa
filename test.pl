#!/usr/bin/env perl

use lib 'lib';
use Universa::FORTH;

my $session = Universa::FORTH->new;
use Data::Dumper;
print Dumper $session;

exit;
