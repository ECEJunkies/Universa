package Universa::FORTH::Plugin;
{ $Universa::FORTH::Plugin::VERSION = '0.01' }

use warnings;
use strict;


# Overload this with some reasonable value. Its' return value will be added
# to $forth->{'feature'} so that it can be queried and accessed:
sub name { "" }

# This should be overloaded as well. plugin_init() is called from add_plugin
# after it has been loaded and stored:
sub plugin_init {}

1;
