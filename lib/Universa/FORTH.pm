package Universa::FORTH;

use v5.18;
use warnings;
use strict;
no warnings 'experimental::smartmatch';

use Universa::FORTH::Words;
use Carp 'croak';
use Scalar::Util;


# The constructor is not all that special here, but it will do for
# the moment:
sub new {
    my ($class, %params) = @_;

    # Parameters:
    my $datastore = delete $params{'store'};

    my $self = {
	'_ps'     => [],    # Parameter stack
	'_psp'    => 0,     # Parameter stack pointer
	'active'  => 1,     # Outer interpreter running state
	'dict'    => {},    # Dictionary
	'heap'    => $params{'heap'} || {}, # Data heap
	'builtin' => {},    # Builtin words here (code and eval)
	'mode'    => 'interpret',
	'catch'   => '',    # For collect mode
	'store'   => $datastore || undef, # Datastore object ref
    };

    my $object = bless $self, $class;
    $object->cold; # Load builtins and the provided base dictionary
    return $object;
}

# Just an error throwing helper:
sub error {
    my ($self, $message) = @_;
    print "error ($message)\n";
    0;
}

# We used to handle stack pointers here, but I think they can be
# ignored now. I am leaving these helper functions here since they
# clean the code up a bit:
sub push_ps {
    my ($self, @values) = @_;
    croak 'push_ps requires an argument' unless @values;
    push @{ $self->{'_ps'} }, @values;
}

# Can pop off more than one value. This will speed up  accesses to
# the stack, i.e. my ($num1, $num2) = $self->pop_ps(2); - It should
# also make it easier to handle errors:
sub pop_ps {
    my ($self, $values) = @_;
    return $self->error('Stack is not large enough for pop operation')
	unless @{ $self->{'_ps'} } >= ($values);
    return splice @{ $self->{'_ps'} }, (-1 * ($values ));
}

# peek_ps() will peer into the parameter stack and return values
# without removing them:
sub peek_ps {
    my ($self, $values, $offset) = @_;
    return $self->error('Stack is not large enough for peek operation')
	unless @{ $self->{'_ps'} } >= ($values);
    $offset ||= 0;
    return (reverse @{ $self->{'_ps'} })[$offset .. ($values - 1)];
    
}

# The first thing ever run when a FORTH interpreter is being born
# is cold. This function is responsible for providing all core
# words into our FORTH program. However, we also load our primary
# builtin words (not core words) as well:
sub cold {
    my $self = shift;

    # The eval core word accepts a string of Perl code and
    # evaluates it when the word is processed:
    $self->{'builtin'}->{'eval'} = sub {
	my $code = shift;

	eval $code;
	print $@ if $@;
    };

    # Most builtin words will use the code core word. The only
    # difference is that it accepts a code reference:
    $self->{'builtin'}->{'code'} = sub {
	my $coderef = shift;

	$coderef->(@_);
    };

    # Provide the builtin dictionary:
    $self->add_dictionary( Universa::FORTH::Words->new );
}

# forth_exec() is just a dispatcher, more than anything. The real
# work is mostly done by the forth modes:
sub forth_exec {
    my ($self, $chunk) = @_;
    
    while ($$chunk) {
	for ($self->{'mode'}) {
	    when (/^interpret$/) { $self->interpret($chunk) }
	    when (/^collect$/)   { $self->collect($chunk)   }
	}
    }
}

# collect() is responsible for string support; It could be used for
# more. Its' job is to load in alphanumeric characters until it
# hits a 'catch_word' thrown into $self->{'_catch'}:
sub collect {
    my ($self, $chunk) = @_;

    my $catch_word = $self->{'_catch'}->[0];
    $$chunk =~ /(.*)\s$catch_word/;
    $self->{'_catch'}->[1]->($1) if $1;
    $$chunk = (split /\s$catch_word/, $$chunk, 2)[1];
    $self->{'mode'} = 'interpret';
}

# Builtins are words provided to us that are defined in the
# dictionary. Oddly enough, this function can also be used to
# run user defined 'colon' definitions as well:
sub run_builtin {
    my ($self, $word) = @_;

    $self->{'builtin'}->{$self->{'dict'}->{$word}->{'codeword'}}->(
	@{ $self->{'dict'}->{$word}->{'params'} }
    );
}

# The semi-outer interpreter of FORTH lies here. Its' job is to
# handle the execution of builtins and core words, as well as
# bareword literals:
sub interpret {
    my ($self, $chunk) = @_;
    
    if ( (my $word, $$chunk) = split ' ', $$chunk, 2 ) {

	# Run a builtin, if possible (See above):
	if ( exists($self->{'dict'}->{$word}) ) {
	    $self->run_builtin($word);
	    return;
	}

        # Literals allow for us to perform arithmetic:
	if ( Scalar::Util::looks_like_number($word) ) {
	    push @{ $self->{'_ps'} }, $word;
	    return;
	}
	
	# A bareword is a literal starting with a period.
	# For example, .squirrel:
	if ($word =~ /^\./) {
	    $word = unpack "xA*", $word; # Remove leading period
	    push @{ $self->{'_ps'} }, $word;
	    return;
	}

	# TODO: Throw an error; Not sure how to handle.
    }
}

# IF you wish to add any extra words to the dictionary, you should
# do so here. Note: Conflicting entries do not get overridden:
sub add_dictionary {
    my ($self, $dict, @extra) = @_;

    my %entries    = %{ $dict->populate($self, @extra) };
    my %dictionary = %{ $self->{'dict'} };
    @dictionary{ keys %entries } = values %entries;
    $self->{'dict'} = \%dictionary;
}

# Every interpreter needs a convenient way to add words to its'
# dictionary. This function is never used internally:
sub add_word {
    my ($self, $dict, $name, $codeword, @params) = @_;
    
    my $entry = {
	'codeword' => $codeword,
	'params'   => \@params,
    };
    
    $dict->{'dict'}->{$name} = $entry;
    $entry;
}

# This executes if we run this module as a standalone script.
# It can be useful for interactive testing of the FORTH
# interpreter and such:
sub run { shift->repl }

sub repl {
    my $self = shift;
    
    while ($self->{'active'}) {
	
	print  "> ";
	my $chunk = <STDIN>;
	chomp $chunk;
	$chunk =~ s/^\s+|\s+$//; # Trim
	next unless $chunk;
	
	$self->forth_exec(\$chunk);
	print "ok [@{[join ', ', @{ $self->{'_ps'} } ]}]\n"; # Stack status
    }
}

__PACKAGE__->new->run unless caller;
