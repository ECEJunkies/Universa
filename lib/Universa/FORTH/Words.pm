package Universa::FORTH::Words;
# This dictionary set adds the base words used for arithmetic
# and other related operations.

use warnings;
use strict;

use Universa::FORTH::Dictionary;
use base 'Universa::FORTH::Dictionary';


sub populate {
    my ($self, $forth) = @_;

    # Dictionary words:
    {
	# Addition:
	'+' => {
	    codeword => 'code',
	    params   => [
		sub {
		    my ($x, $y) = $forth->pop_ps(2) or return;
		    $forth->push_ps($x + $y);
		},
		],
	},

	# Subtraction:
	'-' => {
	    codeword => 'code',
	    params   => [
		sub {
		    my ($x, $y) = $forth->pop_ps(2) or return;
		    $forth->push_ps($x - $y);
		},
		],
	},

	# Reverse subtraction:
	'r-' => {
	    codeword => 'code',
	    params   => [
		sub {
		    my ($x, $y) = $forth->pop_ps(2) or return;
		    $forth->push_ps($y - $x);
		},
		],
	},

	# Multiplication:
	'*' => {
	    codeword => 'code',
	    params   => [
		sub {
		    my ($x, $y) = $forth->pop_ps(2) or return;
		    $forth->push_ps($x * $y);
		},
		],
	},

	# Division:
	'/' => {
	    codeword => 'code',
	    params   => [
		sub {
		    my ($x, $y) = $forth->pop_ps(2) or return;
		    $forth->push_ps($x / $y);
		},
		],
	},

	# Reverse division:
	'r/' => {
	    codeword => 'code',
	    params   => [
		sub {
		    my ($x, $y) = $forth->pop_ps(2) or return;
		    $forth->push_ps($y / $x);
		},
		],
	},

	# Modulus:
	'%' => {
	    codeword => 'code',
	    params   => [
		sub {
		    my ($x, $y) = $forth->pop_ps(2) or return;
		    $forth->push_ps($x % $y);
		},
		],
	},

	# Reverse modulus:
	'r%' => {
	    codeword => 'code',
	    params   => [
		sub {
		    my ($x, $y) = $forth->pop_ps(2) or return;
		    $forth->push_ps($y % $x);
		},
		],
	},

	# Duplication:
	'dup' => {
	    codeword => 'code',
	    params   => [
		sub {
		    my $x = $forth->peek_ps(1) or return;
		    $forth->push_ps($x);
		},
		],
	},

	# General output:
	'.' => {
	    codeword => 'code',
	    params   => [
		sub {
		    my $x = $forth->pop_ps(1) or return;
		    print $x . "\n";
		},
		],
	},
	
	# a b -- b a:
	'swap' => {
	    codeword => 'code',
	    params   => [
		sub {
		    my ($x, $y) = $forth->pop_ps(2) or return;
		    $forth->push_ps($y, $x);
		},
		],
	},

	# a b c -- c a b:
	'rot' => {
	    codeword => 'code',
	    params   => [
		sub {
		    my ($x, $y, $z) = $forth->pop_ps(3) or return;
		    $forth->push_ps($z, $x, $y);
		},
		],
	},

	# a b c -- b c a:
	'-rot' => {
	    codeword => 'code',
	    params   => [
		sub {
		    my ($x, $y, $z) = $forth->pop_ps(3)
			or return warn "Error\n";
		    $forth->push_ps($y, $z, $x);
		},
		],
	},

	# a b -- a b a:
	'over' => {
	    codeword => 'code',
	    params   => [
		sub {
		    my ($x, $y) = $forth->pop_ps(2) or return;
		    $forth->push_ps($x, $y, $x);
		},
		],
	},

	# a b -- b:
	'nip' => {
	    codeword => 'code',
	    params   => [
		sub {
		    my ($x, $y) = $forth->pop_ps(2) or return;
		    $forth->push_ps($y);
		},
		],
	},

	# a b -- b a b:
	'tuck' => {
	    codeword => 'code',
	    params   => [
		sub {
		    my ($x, $y) = $forth->pop_ps(2) or return;
		    $forth->push_ps($y, $x, $y);
		},
		],
	},

	# Push a string onto the stack. Note that "s is required to
	# be on the same chunk (line):
	's"' => {
	    codeword => 'code',
	    params => [
		sub {
		    $forth->{'mode'} = 'collect';
		    $forth->{'_catch'} = [
			'"s' => sub {
			    my $data = shift;
			    $forth->push_ps($data);
			},
			],
		},
		],
	},

	# Same thing as s", except that instead of the string being
	# pushed onto the stack, it is printed as output:
	'."' => {
	    codeword => 'code',
	    params => [
		sub {
		    $forth->{'mode'} = 'collect';
		    $forth->{'_catch'} = [
			'".' => sub {
			    my $data = shift;
			    print $data . "\n";
			},
			],
		},
		],
	}
    }
}

1;
