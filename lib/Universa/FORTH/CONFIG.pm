package Universa::FORTH::CONFIG;
# The purpose of this module is mainly to prevent redefines from Universa::FORTH::Session in
# the Universa::FORTH package.

use warnings;
use strict;


# An SDELEGATE is a session specific delegation, where the current session is passed 
# down to the delegate, while an IDELEGATE is an interpreter wide delegation,
# lacking the session information:
our @IDELEGATES = qw(feature add_plugin);
our @SDELEGATES = qw(repl forth_exec);

1;
