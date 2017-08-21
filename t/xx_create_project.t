#! /usr/bin/perl
use strict;
use warnings;
use stefans_libs::root;
use Test::More tests => 6;
use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value, @values, $exp, $path, $name, $git_server, $git_user, $debug );

my $exec = $plugin_path . "/../bin/create_project.pl";
ok( -f $exec, 'the script has been found' );
my $outpath = "$plugin_path/data/output/create_project";
if ( -d $outpath ) {
	system("rm -Rf $outpath");
}
$name = "test_project";
$path = "$plugin_path/data/output/test_project";

$debug = "";
unless ( defined $ARGV[0] ){
	$debug = " -debug";
}

if ( -d $path){
	system( "rm -Rf $path/*" );
}
my $cmd =
    "perl -I $plugin_path/../lib  $exec "
. " -path " . $path 
. " -name " . $name 
#. " -git_server " . $git_server 
#. " -git_user " . $git_user 
. "$debug";
my $start = time;
print ( $cmd."\n");
system( $cmd );
my $duration = time - $start;
print "Execution time: $duration s\n";

foreach my $dir ( qw( data scripts outpath) ){
	ok ( -d "$path/$dir", "path '$dir'" );
}
foreach my $file ( "README.md", "scripts/$name.R" ){
	ok ( -f "$path/$file", "path '$file'" );
}

#print "\$exp = ".root->print_perl_var_def($value ).";\n";