package Universa::DataStore;
# Pretty much a superpowered Redis clone (as of the date this was
# written). It runs on top of Universa::FORTH.

use warnings;
use strict;

use Universa::FORTH;
use Universa::FORTH::DataDict;

use base 'Universa::FORTH::Plugin';


# The construction operations for Universa::FORTH inherited objects are sort of
# non-traditional, but they seem to work ok:
sub new {
    my ($class, %params) = @_;
    my $forth = __PACKAGE__->_new;

    # We squeeze our own little selfies here:
    $forth->{'__ds__'}->{'heap'}  = $params{'Heap'} || {};
    $forth->{'__ds__'}->{'allow_save'} = $params{'AllowSave'} || 1;
    $forth->{'__ds__'}->{'hooks'} = {};

    push @{ $forth->{'features'} }, 'datastore';
    $forth->add_dictionary(Universa::FORTH::DataDict->new($forth));
    $forth;
}


# This will create an entry in $self->{'hooks'}. Whenever a client
# updates this entry, everyone will be notified. This can be useful
# for creating message passing channels, or applying hooks to
# key update events:
sub subscribe {
    my ($self, $key) = @_;

    # TODO
}

# publish() is sort of the inverse or opposite of subscribe(). It
# will cause an event to fire to anyone listening on that key
# without modifying the contents of that key. Particularly intended
# for message passing via a key as if it were a channel:
sub publish {
    my ($self, $key, $message) = @_;

    # TODO
}

# Set the value of a specified key via . notation:
sub set_key {
    my ($self, $key, $value) = @_;

    my @path = split /\./, $key;
    
    my $last = pop @path;
    my $targ = $self->{'__ds__'}->{'heap'};
    
    $targ = $targ->{$_} ||= {} for @path;
    $targ->{$last} = $value;
}

# Fetch the value of a specified key via . notation:
sub fetch_key {
    my ($self, $key) = @_;

    my @path = split /\./, $key;

    my $last = pop @path;
    my $targ = $self->{'__ds__'}->{'heap'};

    $targ = $targ->{$_} ||= {} for @path;

    use Data::Dumper;
    print Dumper $targ;
    print $last;
    $targ->{$last};
}

sub client_connected {
    my ($self, $client) = @_;

    *STDIN  = \*{ $client };
    *STDOUT = \*{ $client };
    STDIN->autoflush(1);
    STDOUT->autoflush(1);

    # Create a FORTH interpreter for the client:
    my $forth = Universa::FORTH->new;
    $forth->add_dictionary(Universa::FORTH::DataDict->new($self->{'heap'}), $self);
    $forth->repl;
}

1;
