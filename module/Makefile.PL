use ExtUtils::MakeMaker;
use 5.004;

WriteMakefile(
	NAME	     => 'Error',
	VERSION_FROM => 'lib/Error.pm',
	PREREQ_PM => 
	{
		'Scalar::Util' => 0,
	},
    AUTHOR    => 'Graham Barr <gbarr@pobox.com>',
    ABSTRACT  => 'Error/exception handling in an OO-ish way',
    PL_FILES => {},
);
