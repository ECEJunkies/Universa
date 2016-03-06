package Universa::FORTH::DataDict;

use warnings;
use strict;

use Universa::FORTH::Dictionary;
use base 'Universa::FORTH::Dictionary';
use JSON qw(encode_json decode_json);
use Data::Dumper;


sub populate {
    my ($self, $forth, $store) = @_;

    {
	'dump' => {
	    codeword => 'code',
	    params   => [
		sub {
		    my $k = $forth->pop_ps(1) or return;
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
		    my ($key, $value) = $forth->pop_ps(2) or return;
		    $store->set_key($key, $value);
		},
		],
	},

	'get' => {
	    codeword => 'code',
	    params   => [
		sub {
		    my $key = $forth->pop_ps(1) or return;
		    my $value = $store->fetch_key($key)
			or return $forth->error("can't find key");
		    $forth->push_ps($value);
		},
		],
	},

	'freeze' => {
	    codeword => 'code',
	    params   => [
		sub {
		    my $key = $forth->pop_ps(1) or return;
		    my $value = $store->fetch_key($key)
			or return $forth->error("can't find key");
		    $forth->push_ps(encode_json($value));
		},
		],
	},

	'thaw' => {
	    codeword => 'code',
	    params   => [
		sub {
		    my ($key, $value) = $forth->pop_ps(2) or return;
		    $store->set_key($key, decode_json($value));
		},
		],
	},
    };
}

1;
