package Universa::DataStore::Server;

use warnings;
use strict;

use Universa::DataStore;
use Mojo::IOLoop;


sub new {
    my ($class, %params) = @_;
    my %heap = ();

    my $self = {
	'heap'     => \%heap,
	'clients'  => [],
	'forth'   => Universa::DataStore->new(
	    Heap      => \%heap,
	    AllowSave => 0,
	    ),
    };

    bless $self, $class;
}

sub start {
    my $self = shift;
    
    print "TEST\n";
    Mojo::IOLoop->server(
	{ port => 9603 } => sub {
	    my ($loop, $stream) = @_;

	    $stream->on(
		read => sub {
		    my ($stream, $bytes) = @_;

		    # TODO
		    print $bytes;
		    $stream->write('ok');
		},

		accept => sub {
		    print "connected!\n";
		},
		);
	},
	);

    Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
}

1;
