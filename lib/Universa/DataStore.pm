package Universa::DataStore;
# Pretty much a superpowered Redis clone (as of the date this was
# written). It runs on top of Universa::FORTH.

use warnings;
use strict;

use Universa::DataStore::Server;
use Universa::FORTH;
use Universa::FORTH::DataDict;
use IO::Socket::IP;
use IPC::Shareable qw(:lock);


my %heap = ();
tie %heap, 'IPC::Shareable';

sub new { bless { 
    'hooks' => {}, # For creating channels and event callbacks
}, shift }

# Fetch the value of a specified key via . notation:
sub fetch_key {
    my ($self, $key) = @_;

    my $r = \%heap;
    $r = $r->{$_} for split /\./, $key, $r;
    $r;
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
    my $targ = \%heap;
    
    $targ = $targ->{$_} ||= {} for @path;
    $targ->{$last} = $value;
}

sub client_connected {
    my ($self, $client) = @_;

    *STDIN  = \*{ $client };
    *STDOUT = \*{ $client };
    STDIN->autoflush(1);
    STDOUT->autoflush(1);

    # Create a FORTH interpreter for the client:
    my $forth = Universa::FORTH->new;
    $forth->add_dictionary(Universa::FORTH::DataDict->new(\%heap), $self);
    $forth->repl;
}

# Clearly the intended purpose of this entire project. A forking
# server that provides a FORTH shell to each client, with central
# access to the data heap:
sub start_server {
    my ($self, %params) = @_;

    my $listener = IO::Socket::IP->new(%params)
	or die "Can't create socket: $!\n";
    $self->{'_listener'} = $listener;

    # We may need to do some better network handling here..
    while (my $client = $listener->accept) {
	my $pid;

	while (not defined ($pid = fork)) {}
	$self->client_connected($client) if $pid;
    }
}

# For debugging / interactive purposes, throw the user into a
# Read Eval Print Loop with the data store dictionary set:
sub run {
    my $self = shift;

    my $forth = Universa::FORTH->new;
    $forth->add_dictionary(Universa::FORTH::DataDict->new(\%heap), $self);
    $forth->repl;
}

__PACKAGE__->new->run unless caller;
1;
