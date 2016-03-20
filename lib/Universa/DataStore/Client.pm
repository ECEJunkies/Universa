package Universa::DataStore::Client;

use warnings;
use strict;

use IO::Socket::IP;
use IO::Select;


sub new {
    my ($class, %params) = @_;

    my $host = delete $params{'Host'}
    or die 'Host is a required argument';

    my $self = {
	'_sel'     => IO::Select->New,
	'_tiehash' => {},
	'_handle'  => IO::Socket::IP->new(
	    RemoteAddr => $host,
	    Proto      => 'tcp',
	    Blocking   => 0,
	    ) or die "Can't open socket: $!\n",
    },

    my $object = bless $self, $class;
    tie %{ $self->{'_tiehash'} }, $object;
    $object;
}

sub get_handle { shift->{'_handle'} }

sub data_receive {
    
}

sub start_loop {
    my $self = shift;
    my $sel    = $self->{'_sel'};
    my $socket = $self->{'_handle'};

    # This all should be cleaned up. Maybe use IO::Async..
    while (my @ready = $s->can_read(0)) {
	my $line = <$socket>;
	chomp $line;

	$self->data_receive($line);
    }
}

# Sends a raw message to the server. Useful for advanced features
sub put_raw {
    my ($self, $data) = @_;

    # TODO
}

sub get_key {
    my ($self, $key) = @_;

    # TODO
}

sub set_key {
    my ($self, $key, value) = @_;

    # TODO
}

sub subscribe {
    my ($self, $key) = @_;

    # TODO
}

sub publish {
    my ($self, $key, $message) = @_;

    # TODO
}

sub freeze {
    my ($self, $key) = @_;

    # TODO
}

sub thaw {
    my ($self, $key, $json) = @_;

    # TODO
}

1;

package Universa::DataStore::HashSim;

use warnings;
use strict;

use Tie::Hash;
use base 'Tie::Hash';


sub TIEHASH {
    my ($class, %params) = shift;

    my $self = {
	'_ds' => delete $params{'datastore'} or die 'an argument is required.';
    };

    bless $self, $class;

sub store {
    my $self = shift;

    use Data::Dumper;
    print Dumper @_;
}

1;
