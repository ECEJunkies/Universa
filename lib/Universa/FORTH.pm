package Universa::FORTH;

use v5.18;
use warnings;
use strict;
no warnings 'experimental::smartmatch';

use Universa::FORTH::Words;
use Universa::FORTH::Session;
use Carp 'croak';
use Scalar::Util;
use List::Util 'first';

#use Devel::Confess;

# Safety first (before GD):
END {
    undef our $INTERPRETER;
}

# The real constructor is not all that special here: 
sub new {
    my ($class, %params) = @_;

    # If the core interpreter is not yet already set up, do so:
    our $INTERPRETER ||= _new_interpreter($class, %params);

    # Instead of providing the client with the interpreter, provide them with a new
    # session that can access it. There is a strange bug here we need to watch out
    # for. apparently we can't pass parameters to new because they dissapear:
    my $session = Universa::FORTH::Session->new;
    $session->{'_link'} = $INTERPRETER;
    $session;
}

# This shouldn't be called directly, but it is here just in case:
sub _new_interpreter {
    my $class = shift;

    my $self = {
	'dict'    => {},    # Global dictionary
	'builtin' => {},    # Builtin words here (code and eval)
	'feature' => {},    # Additional feature references (eg. datastore)
    };
    
    my $interpreter = bless $self, $class;
    $interpreter->cold; # Load builtins and the provided base dictionary
    $interpreter;
}

# feature() returns a true value if an array element in $self->{'feature'} contains
# that string. It is intended to be used by dictionaries which depend on code not
# provided by this module to help ensure that their environment is sane:
sub feature {
    my ($self, $feature) = @_;

    # We only need to find a feature once:
    return 0 unless exists($self->{'feature'}->{$feature});
}

# Just an error throwing helper:
sub error {
    my ($self, $message) = @_;
    print "error ($message)\n";
}

# The answer I came up with to better handle additional dictionary entries, etc
# was to support a simple plugin system. Before, mpodules would have to inherit
# Universa::FORTH which was a bit messy:
sub add_plugin {
    my ($self, $object) = @_;
    my $package = ref $object;

    $object->isa('Universa::FORTH::Plugin')
	or die "Plugin '$package' must inherit 'Universa::Forth::Plugin\n";

    # All plugins must have a name to identify them as a 'feature':
    my $name = $object->name or die "Plugin '$package$' must have a name\n";
    return warn "Plugin '$package' already loaded\n"
	if $self->{'feature'}->{$name};
    $self->{'feature'}->{$name} = $object; # Store it!

    $object->plugin_init($self);
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
	my ($session, $code) = @_;

	eval $code; # TODO: carry $session.
	print $@ if $@;
    };

    # Most builtin words will use the code core word. The only
    # difference is that it accepts a code reference:
    $self->{'builtin'}->{'code'} = sub {
	my ($session, $coderef) = @_;

	$coderef->($session, @_);
    };

    # Provide the builtin dictionary:
    $self->add_dictionary( Universa::FORTH::Words->new );
}

# forth_exec() is just a dispatcher, more than anything. The real
# work is mostly done by the forth modes:
sub forth_exec {
    my ($self, $session, $chunk) = @_;

    while ($$chunk) {
	for ($session->{'imode'}) {
	    when (/^interpret$/) { $self->interpret($session, $chunk) }
	    when (/^collect$/)   { $self->collect($session, $chunk)   }
	}
    }

    # Return a reference to the parameter stack. This is really just to help
    # make code a bit easier during implementation:
    $session->{'_ps'};
}

# collect() is responsible for string support; It could be used for
# more. Its' job is to load in alphanumeric characters until it
# hits a 'catch_word' thrown into $self->{'_catch'}:
sub collect {
    my ($self, $session, $chunk) = @_;

    my $catch_word = $session->{'_catch'}->[0];
    $$chunk =~ /(.*)\s$catch_word/;
    $session->{'_catch'}->[1]->($1) if $1;
    $$chunk = (split /\s$catch_word/, $$chunk, 2)[1];
    $session->{'imode'} = 'interpret';
}

# Builtins are words provided to us that are defined in the
# dictionary. Oddly enough, this function can also be used to
# run user defined 'colon' definitions as well:
sub run_builtin {
    my ($self, $session, $word) = @_;

    $self->{'builtin'}->{$self->{'dict'}->{$word}->{'codeword'}}->(
	$session, @{ $self->{'dict'}->{$word}->{'params'} }
    );
}

# The semi-outer interpreter of FORTH lies here. Its' job is to
# handle the execution of builtins and core words, as well as
# bareword literals:
sub interpret {
    my ($self, $session, $chunk) = @_;
    
    if ( (my $word, $$chunk) = split ' ', $$chunk, 2 ) {

	# Run a builtin, if possible (See above):
	if ( exists($self->{'dict'}->{$word}) ) {
	    $self->run_builtin($session, $word);
	    return;
	}

        # Literals allow for us to perform arithmetic:
	if ( Scalar::Util::looks_like_number($word) ) {
	    push @{ $session->{'_ps'} }, $word;
	    return;
	}
	
	# A bareword is a literal starting with a period.
	# For example, .squirrel:
	if ($word =~ /^\./) {
	    $word = unpack "xA*", $word; # Remove leading period
	    push @{ $session->{'_ps'} }, $word;
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
sub run {

    my $session = __PACKAGE__->new;
    $session->repl;
}

sub repl {
    my ($self, $session) = @_;
    
    while ($session->{'active'}) {

	my $in_handle  = $session->{'in_handle'};
	my $out_handle = $session->{'out_handle'};

	print $out_handle "> ";
	my $chunk = <$in_handle>;
	chomp $chunk;
	$chunk =~ s/^\s+|\s+$//; # Trim
	next unless $chunk;
	
	$self->forth_exec($session, \$chunk);
	print $out_handle "ok [@{[join ', ', @{ $session->{'_ps'} } ]}]\n"; # Stack status
    }
}

__PACKAGE__->run unless caller; # We can't use :: here.... at least not right now
