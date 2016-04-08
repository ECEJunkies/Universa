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
		    my $session = shift;
		    my ($x, $y) = $session->pop_ps(2) or return;
		    $session->push_ps($x + $y);
		},
		],
	},

	# Subtraction:
	'-' => {
	    codeword => 'code',
	    params   => [
		sub {
		    my $session = shift;
		    my ($x, $y) = $session->pop_ps(2) or return;
		    $session->push_ps($x - $y);
		},
		],
	},

	# Reverse subtraction:
	'r-' => {
	    codeword => 'code',
	    params   => [
		sub {
		    my $session = shift;
		    my ($x, $y) = $session->pop_ps(2) or return;
		    $session->push_ps($y - $x);
		},
		],
	},

	# Multiplication:
	'*' => {
	    codeword => 'code',
	    params   => [
		sub {
		    my $session = shift;
		    my ($x, $y) = $session->pop_ps(2) or return;
		    $session->push_ps($x * $y);
		},
		],
	},

	# Division:
	'/' => {
	    codeword => 'code',
	    params   => [
		sub {
		    my $session = shift;
		    my ($x, $y) = $session->pop_ps(2) or return;
		    $session->push_ps($x / $y);
		},
		],
	},

	# Reverse division:
	'r/' => {
	    codeword => 'code',
	    params   => [
		sub {
		    my $session = shift;
		    my ($x, $y) = $session->pop_ps(2) or return;
		    $session->push_ps($y / $x);
		},
		],
	},

	# Modulus:
	'%' => {
	    codeword => 'code',
	    params   => [
		sub {
		    my $session = shift;
		    my ($x, $y) = $session->pop_ps(2) or return;
		    $session->push_ps($x % $y);
		},
		],
	},

	# Reverse modulus:
	'r%' => {
	    codeword => 'code',
	    params   => [
		sub {
		    my $session = shift;
		    my ($x, $y) = $session->pop_ps(2) or return;
		    $session->push_ps($y % $x);
		},
		],
	},

	# Duplication:
	'dup' => {
	    codeword => 'code',
	    params   => [
		sub {
		    my $session = shift;
		    my $x = $session->peek_ps(1) or return;
		    $session->push_ps($x);
		},
		],
	},

	# General output:
	'.' => {
	    codeword => 'code',
	    params   => [
		sub {
		    my $session = shift;
		    my $x = $session->pop_ps(1) or return;
		    $session->out($x . "\n");
		},
		],
	},
	
	# a b -- b a:
	'swap' => {
	    codeword => 'code',
	    params   => [
		sub {
		    my $session = shift;
		    my ($x, $y) = $session->pop_ps(2) or return;
		    $session->push_ps($y, $x);
		},
		],
	},

	# a b c -- c a b:
	'rot' => {
	    codeword => 'code',
	    params   => [
		sub {
		    my $session = shift;
		    my ($x, $y, $z) = $session->pop_ps(3) or return;
		    $session->push_ps($z, $x, $y);
		},
		],
	},

	# a b c -- b c a:
	'-rot' => {
	    codeword => 'code',
	    params   => [
		sub {
		    my $session = shift;
		    my ($x, $y, $z) = $session->pop_ps(3)
			or return warn "Error\n";
		    $session->push_ps($y, $z, $x);
		},
		],
	},

	# a b -- a b a:
	'over' => {
	    codeword => 'code',
	    params   => [
		sub {
		    my $session = shift;
		    my ($x, $y) = $session->pop_ps(2) or return;
		    $session->push_ps($x, $y, $x);
		},
		],
	},

	# a b -- b:
	'nip' => {
	    codeword => 'code',
	    params   => [
		sub {
		    my $session = shift;
		    my ($x, $y) = $session->pop_ps(2) or return;
		    $session->push_ps($y);
		},
		],
	},

	# a b -- b a b:
	'tuck' => {
	    codeword => 'code',
	    params   => [
		sub {
		    my $session = shift;
		    my ($x, $y) = $session->pop_ps(2) or return;
		    $session->push_ps($y, $x, $y);
		},
		],
	},

	# a -- nil:
	'drop' => {
	    codeword => 'code',
	    params   => [
		sub {
		    my $session = shift;
		    my $x = $session->pop_ps(1) or return;
		},
		],
	},

	# a -- a + 1
	'++' => {
	    codeword => 'code',
	    params => [
		sub {
		    my $session = shift;
		    my $x = $session->pop_ps(1) or return;
		    $session->push_ps($x + 1);
		},
		],
	},

	# a -- a - 1
	'--' => {
	    codeword => 'code',
	    params => [
		sub {
		    my $session = shift;
		    my $x = $session->pop_ps(1) or return;
		    $session->push_ps($x - 1);
		},
		],
	},

	# Push a string onto the stack. Note that "s is required to
	# be on the same chunk (line):
	's"' => {
	    codeword => 'code',
	    params => [
		sub {
		    my $session = shift;
		    $session->{'imode'} = 'collect';
		    $session->{'_catch'} = [
			'"s' => sub {
			    my $data = shift;
			    $session->push_ps($data);
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
		    my $session = shift;
		    $session->{'imode'} = 'collect';
		    $session->{'_catch'} = [
			'".' => sub {
			    my $data = shift;
			    $session->out($data);
			},
			],
		},
		],
	},

	# TODO: Remove this and put it in its' own plugin:
	'temp' => {
	    codeword => 'code',
	    params   => [
		sub {
		    my $session = shift;
		    my $temp = `i2cget -y 1 0x4b 0 b` || '0';
		    chomp $temp;
		    $session->push_ps(sprintf( "%x", int($temp)));
		},
		],
	}
    }
}

1;
