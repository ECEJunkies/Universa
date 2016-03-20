package Universa::FORTH::Session;

use warnings;
use strict;

use Carp qw(croak);
use Universa::FORTH::CONFIG; # sdelegates and idelegates


sub new {
    my ($class, %params) = shift;

    my $self = {
	'_ps'    => [],          # Parameter stack
	'_rs'    => [],          # Return stack
	'_es'    => [],          # Exception stack
	'active' => 1,           # Outer interpreter running state
	'imode'  => 'interpret', # Interpreter mode
	'catch'  => '',          # For collect mode
	'_link'  => undef,       # Reference to the interpreter

	# IO stuff (allows the interpreter to control session IO):
	'in_handle'  => delete $params{'inHandle'}  || \*STDIN,
	'out_handle' => delete $params{'outHandle'} || \*STDOUT,
    };
    
    bless $self, $class;
}

sub push_ps {
    my ($self, @values) = @_;
    croak 'push_ps requires an argument' unless @values;
    push @{ $self->{'_ps'} }, @values;
}

# These helper functions can pop off more than one value. This will speed up
# accesses to the stack, i.e. my ($num1, $num2) = $self->pop_ps(2); - It should
# also make it easier to handle errors:
sub pop_ps {
    my ($self, $values) = @_;
    
    unless ( @{ $self->{'_ps'} } >= ($values) ) {
	$self->{'_link'}->error('Stack is not large enough for pop operation');
	return;
    }
    
    splice @{ $self->{'_ps'} }, (-1 * ($values ));
}

# peek_ps() will peer into the parameter stack and return values
# without removing them:
sub peek_ps {
    my ($self, $values, $offset) = @_;
    unless (@{ $self->{'_ps'} } >= ($values)) {
	$self->{'_link'}->error('Stack is not large enough for peek operation');
	return;
    }

    $offset ||= 0;
    (reverse @{ $self->{'_ps'} })[$offset .. ($values - 1)];
    
}

# Glob references are a magical thing that everyone should try at least try
# once. In the following case, SDELEGATES pass the current session to the
# interpreter:
for my $method (@Universa::FORTH::CONFIG::SDELEGATES) {
    my $globref = do {
	no strict 'refs';
	\*$method;
    };
    
    *$globref = sub {
	my $self = shift; 
	$self->{'_link'}->$method($self, @_)
    };
}

# However, IDELEGATES are independent from the session and therefore do not
# pass the current session to the interpreter:
for my $method (@Universa::FORTH::CONFIG::IDELEGATES) {
    my $globref = do {
	no strict 'refs';
	\*$method;
    };
    
    *$globref = sub {
	my $self = shift; 
	$self->{'_link'}->$method(@_)
    };
}

1;
