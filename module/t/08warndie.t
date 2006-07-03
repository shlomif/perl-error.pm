#!/usr/bin/perl -w

use strict;

use Test::More tests => 13;

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
# STDERR and exit code.
my ( $s, $exitcode );
my $linekid = this_line + 16; # the $code->() is 16 lines below this one
sub run_kid(&)
{
    my ( $code ) = @_;

    my $kid = open( my $childh, "-|" );

    defined $kid or
        die "Can't pipe/fork myself - $!";

    if ( !$kid ) {
        close STDERR;
        open STDERR, ">&", STDOUT;

        $! = 3; # This number should be returned from a die

        $code->();

        exit( 5 ); # This number should be returned if the $code block returns
    }

    $s = "";
    while( defined ( $_ = <$childh> ) ) {
        $s .= $_;
    }

    $exitcode = 0;
    unless( close( $childh ) ) {
        warn "Error closing pipe - $!" if $!;
        $exitcode = ($? >> 8) & 0xff;
    }   
}

ok(1, "Loaded");

run_kid {
    print STDERR "Print to STDERR\n";
};

is( $s, "Print to STDERR\n", "Test framework STDERR" );
is( $exitcode, 5, "Test framework exitcode" );

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
is( $exitcode, 5, "warn \\n-terminated exit code" );

$line = this_line;
run_kid {
    warn "A warning";
};

( $linea, $lineb ) = ( $line + 2, $line + 3 );
like( $s, qr/^A warning at $file line $linea:
\tmain::__ANON__\(\) called at $file line $linekid
\tmain::run_kid\('CODE\(0x[0-9a-f]+\)'\) called at $file line $lineb
$/, "warn unterminated STDERR" );
is( $exitcode, 5, "warn unterminated exit code" );

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
is( $exitcode, 3, "die \\n-terminated exit code" );

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
is( $exitcode, 3, "die unterminated exit code" );

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
is( $exitcode, 3, "Error exit code" );

# Done
