#!/usr/bin/perl -w

# Usage: perl warndie.pl [1 or true or whatever if you want to use warndie]
require Error;
if( $ARGV[0] ) {
    import Error qw( :warndie );
    print "Imported the :warndie tag.\n";
    print "\n";
}
else {
    print "Running example without the :warndie tag.\n";
    print "Try also passing a true value as \$ARGV[0] to import this tag\n";
    print "\n";
}

sub inner {
  shift->foo();
}

sub outer {
  inner( @_ );
}

outer( undef );
