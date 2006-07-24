#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 21;

use Error qw/ :warndie /;

# Turn on full stack trace capture
$Error::Debug = 1;

# Returns the line number it is called from
sub this_line()
{
    my @caller = caller();
    return $caller[2];
}

# This file's name - for string matching
my $file = $0;

# Most of these tests are fatal, and print data on STDERR. We therefore use
# this testing function to run a CODEref in a child process and captures its
# STDERR and note whether the CODE block exited
my ( $s, $felloffcode );
my $linekid = this_line + 14; # the $code->() is 14 lines below this one
sub run_kid(&)
{
    my ( $code ) = @_;

    my $kid = open( my $childh, "-|" );

    defined $kid or
        die "Can't pipe/fork myself - $!";

    if ( !$kid ) {
        close STDERR;
        open STDERR, ">&", STDOUT;

        $code->();

        print STDERR "FELL OUT OF CODEREF\n";
        exit(1);
    }

    $s = "";
    while( defined ( $_ = <$childh> ) ) {
        $s .= $_;
    }

    close( $childh );

    $felloffcode = 0;
    if( $s =~ s/FELL OUT OF CODEREF\n$// ) {
        $felloffcode = 1;
    }
}

ok(1, "Loaded");

run_kid {
    print STDERR "Print to STDERR\n";
};

is( $s, "Print to STDERR\n", "Test framework STDERR" );
is( $felloffcode, 1, "Test framework felloffcode" );

my $line;

$line = this_line;
run_kid {
    warn "A warning\n";
};

my ( $linea, $lineb ) = ( $line + 2, $line + 3 );
like( $s, qr/^A warning at $file line $linea:
\tmain::__ANON__\(\) called at $file line $linekid
\tmain::run_kid\('CODE\(0x[0-9a-f]+\)'\) called at $file line $lineb
$/, "warn \\n-terminated STDERR" );
is( $felloffcode, 1, "warn \\n-terminated felloffcode" );

$line = this_line;
run_kid {
    warn "A warning";
};

( $linea, $lineb ) = ( $line + 2, $line + 3 );
like( $s, qr/^A warning at $file line $linea:
\tmain::__ANON__\(\) called at $file line $linekid
\tmain::run_kid\('CODE\(0x[0-9a-f]+\)'\) called at $file line $lineb
$/, "warn unterminated STDERR" );
is( $felloffcode, 1, "warn unterminated felloffcode" );

$line = this_line;
run_kid {
    die "An error\n";
};

( $linea, $lineb ) = ( $line + 2, $line + 3 );
like( $s, qr/^
Unhandled perl error caught at toplevel:

  An error

Thrown from: $file:$linea

Full stack trace:

\tmain::__ANON__\(\) called at $file line $linekid
\tmain::run_kid\('CODE\(0x[0-9a-f]+\)'\) called at $file line $lineb

$/, "die \\n-terminated STDERR" );
is( $felloffcode, 0, "die \\n-terminated felloffcode" );

$line = this_line;
run_kid {
    die "An error";
};

( $linea, $lineb ) = ( $line + 2, $line + 3 );
like( $s, qr/^
Unhandled perl error caught at toplevel:

  An error

Thrown from: $file:$linea

Full stack trace:

\tmain::__ANON__\(\) called at $file line $linekid
\tmain::run_kid\('CODE\(0x[0-9a-f]+\)'\) called at $file line $lineb

$/, "die unterminated STDERR" );
is( $felloffcode, 0, "die unterminated felloffcode" );

$line = this_line;
run_kid {
    throw Error( -text => "An exception" );
};

( $linea, $lineb ) = ( $line + 2, $line + 3 );
like( $s, qr/^
Unhandled exception of type Error caught at toplevel:

  An exception

Thrown from: $file:$linea

Full stack trace:

\tmain::__ANON__\(\) called at $file line $linekid
\tmain::run_kid\('CODE\(0x[0-9a-f]+\)'\) called at $file line $lineb

$/, "Error STDOUT" );
is( $felloffcode, 0, "Error felloffcode" );

# Now custom warn and die functions to ensure the :warndie handler respects them
$SIG{__WARN__} = sub { warn "My custom warning here: $_[0]" };
$SIG{__DIE__}  = sub { die  "My custom death here: $_[0]" };

# First test them
$line = this_line;
run_kid {
    warn "A warning";
};

$linea = $line + 2;
is( $s, "My custom warning here: A warning at $file line $linea.\n", "Custom warn test STDERR" );
is( $felloffcode, 1, "Custom warn test felloffcode" );

$line = this_line;
run_kid {
    die "An error";
};

$linea = $line + 2;
is( $s, "My custom death here: An error at $file line $linea.\n", "Custom die test STDERR" );
is( $felloffcode, 0, "Custom die test felloffcode" );

# Re-install the :warndie handlers
import Error qw( :warndie );

$line = this_line;
run_kid {
    warn "A warning\n";
};

( $linea, $lineb ) = ( $line + 2, $line + 3 );
like( $s, qr/^My custom warning here: A warning at $file line $linea:
\tmain::__ANON__\(\) called at $file line $linekid
\tmain::run_kid\('CODE\(0x[0-9a-f]+\)'\) called at $file line $lineb
$/, "Custom warn STDERR" );
is( $felloffcode, 1, "Custom warn felloffcode" );

$line = this_line;
run_kid {
    die "An error";
};

( $linea, $lineb ) = ( $line + 2, $line + 3 );
like( $s, qr/^My custom death here: 
Unhandled perl error caught at toplevel:

  An error

Thrown from: $file:$linea

Full stack trace:

\tmain::__ANON__\(\) called at $file line $linekid
\tmain::run_kid\('CODE\(0x[0-9a-f]+\)'\) called at $file line $lineb

$/, "Custom die STDERR" );
is( $felloffcode, 0, "Custom die felloffcode" );

# Done
