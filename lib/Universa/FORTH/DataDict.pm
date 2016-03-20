package Universa::FORTH::DataDict;

use warnings;
use strict;

use Universa::FORTH::Dictionary;
use base 'Universa::FORTH::Dictionary';
use JSON qw(encode_json decode_json);
use Data::Dumper;


sub populate {
    my ($self, $forth) = @_;

    die "This dictionary requires the datastore feature from Universa::DataStore \n"
	unless $forth->feature('datastore');

    {
	'dump' => {
	    codeword => 'code',
	    params   => [
		sub {
		    my $session = shift;
		    my $k = $session->pop_ps(1) or return;
		    my $data = $forth->fetch_key($k)
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
		    use Data::Dumper; print Dumper $session;
		    my ($key, $value) = $session->pop_ps(2) or return;
		    $forth->set_key($key, $value);
		},
		],
	},

	'get' => {
	    codeword => 'code',
	    params   => [
		sub {
		    my $key = $forth->pop_ps(1) or return;
		    my $value = $forth->fetch_key($key)
			or return $forth->error("can't find key");
		    $forth->push_ps($value);
		},
		],
	},

	'freeze' => {
	    codeword => 'code',
	    params   => [
		sub {
		    my $session = shift;
		    my $key = $session->pop_ps(1) or return;
		    my $value = $forth->fetch_key($key)
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
		    $forth->set_key($key, decode_json($value));
		},
		],
	},
    };
}

1;
