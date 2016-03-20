package Universa::FORTH::Plugin::DataStore;
# Pretty much a superpowered Redis clone (as of the date this was
# written). It runs on top of Universa::FORTH.

use warnings;
use strict;

use Universa::FORTH;
use Universa::FORTH::DataDict;

use base 'Universa::FORTH::Plugin';


## Plugin system stuff ##

sub name { 'datastore'}

sub plugin_init {
    my ($self, $forth) = @_;

    $forth->{'feature'}->{'datastore'} = $self;
    $forth->add_dictionary(
	Universa::FORTH::Plugin::DataStore::Dictionary->new,
	$self,
	);
}

## Datastore stuff ##

# The construction operations for Universa::FORTH inherited objects are sort of
# non-traditional, but they seem to work ok:
sub new {
    my ($class, %params) = @_;

    my $self = {
	'heap' => delete $params{'Heap'} || {},
    };

    bless $self, $class;
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
    my $targ = $self->{'heap'};
    
    $targ = $targ->{$_} ||= {} for @path;
    $targ->{$last} = $value;
}

# Fetch the value of a specified key via . notation:
sub fetch_key {
    my ($self, $key) = @_;

    my @path = split /\./, $key;

    my $last = pop @path;
    my $targ = $self->{'heap'};

    $targ = $targ->{$_} ||= {} for @path;

    $targ->{$last};
}

1;

package Universa::FORTH::Plugin::DataStore::Dictionary;

use warnings;
use strict;

use Universa::FORTH::Dictionary;
use base 'Universa::FORTH::Dictionary';
use JSON qw(encode_json decode_json);
use Data::Dumper;


sub populate {
    my ($self, $forth, $store) = @_;

    die "This dictionary requires the datastore feature from Universa::DataStore \n"
	unless $forth->feature('datastore');

    {
	'dump' => {
	    codeword => 'code',
	    params   => [
		sub {
		    my $session = shift;
		    my $k = $session->pop_ps(1) or return;
		    my $data = $store->fetch_key($k)
			or return $forth->error("can't find key");
		    print Dumper $data;
		},
		],
	},


	'set' => {
	    codeword => 'code',
	    params   => [
		sub {
		    my $session = shift;
		    my ($key, $value) = $session->pop_ps(2) or return;
		    $store->set_key($key, $value);
		},
		],
	},

	'get' => {
	    codeword => 'code',
	    params   => [
		sub {
		    my $session = shift;
		    my $key = $session->pop_ps(1) or return;
		    my $value = $store->fetch_key($key)
			or return $forth->error("can't find key");
		    $session->push_ps($value);
		},
		],
	},

	'freeze' => {
	    codeword => 'code',
	    params   => [
		sub {
		    my $session = shift;
		    my $key = $session->pop_ps(1) or return;
		    my $value = $store->fetch_key($key)
			or return $forth->error("can't find key");
		    $session->push_ps(encode_json($value));
		},
		],
	},

	'thaw' => {
	    codeword => 'code',
	    params   => [
		sub {
		    my $session = shift;
		    my ($key, $value) = $session->pop_ps(2) or return;
		    $store->set_key($key, decode_json($value));
		},
		],
	},
    };
}

1;
