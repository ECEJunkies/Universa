#!/usr/bin/env perl

use Moose;


has 'car' => (
    isa => 'Str',
    is  => 'rw',
    );


sub foo {
    my $self = shift;

    
}
