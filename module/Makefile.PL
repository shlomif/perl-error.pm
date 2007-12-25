use ExtUtils::MakeMaker;
use 5.004;

WriteMakefile(
	NAME	     => 'Error',
	VERSION_FROM => 'lib/Error.pm',
	PREREQ_PM => 
	{
		'Scalar::Util' => 0,
		'warnings' => 0,
	},
	AUTHOR    => 'Shlomi Fish <shlomif@iglu.org.il>',
	ABSTRACT  => 'Error/exception handling in an OO-ish way',
	PL_FILES => {},
);
