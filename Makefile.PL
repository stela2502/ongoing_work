#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.

use ExtUtils::MakeMaker;

opendir( DIR, "bin/" ) or die "I could not open the bin folder\n$!\n";

WriteMakefile(
	NAME         => "ongoing_work",
	VERSION => "0.1",
	EXE_FILES    => [ map {"bin/$_" } grep !/^\./,  grep '*.pl', readdir(DIR) ],
	PREREQ_PM    => {
		'Stefans_Libs_Essentials'               => 0,
		'Shell' => 0,
	  }

);
closedir(DIR);