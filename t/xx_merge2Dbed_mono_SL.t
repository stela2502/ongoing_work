#! /usr/bin/perl
use strict;
use warnings;
use stefans_libs::root;
use File::Path;
use Test::More tests => 3;
use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value, @values, $exp, $path, $name, $git_server, $git_user, $debug );

my $exec = $plugin_path . "/../bin/merge2Dbed_mono_SL.pl";
ok( -f $exec, 'the script has been found' );
my $outpath = "$plugin_path/data/output/merge2Dbed_mono_SL";
@values = ( 'error.out', 'std.out' );

if ( -d $outpath ) {
	map { unlink("$outpath/$_") if ( -f "$outpath/$_" ) } @values;
}
else {
	File::Path::make_path($outpath);
}

unlink("$outpath/*.log" );

$path = "$plugin_path/data/output/merge2Dbed_mod";

$debug = "";
if (0) {
	$debug = " -debug";
}

my $cmd = "perl -I $plugin_path/../lib  $exec "

  #   . " -res 0"
  . " $plugin_path/data/EBF1.tiny.bed" . " $plugin_path/data/IKZF1.tiny.bed"

  #. " -git_server " . $git_server
  #. " -git_user " . $git_user
  . "$debug" . " 2>$outpath/error.out 1>$outpath/std.out";
my $start = time;
print( $cmd. "\n" );
system($cmd );
my $duration = time - $start;
print "Execution time: $duration s\n";

my $err = slurpFile("$outpath/error.out");

$exp = [
	[ 'Features', "$plugin_path/data/EBF1.tiny.bed", "$plugin_path/data/IKZF1.tiny.bed", 'Name' ],
	[ '6', '',  'X', "$plugin_path/data/IKZF1.tiny.bed" ],
	[ '6', 'X', '',  "$plugin_path/data/EBF1.tiny.bed" ],
	[
		'3', 'X', 'X',
		"$plugin_path/data/EBF1.tiny.bed|$plugin_path/data/IKZF1.tiny.bed"
	]
];

is_deeply( [ @$err[ 13 .. 16 ] ], $exp, "error file correct" );

my $out = slurpFile("$outpath/std.out");

#print "\$exp = " . root->print_perl_var_def($out) . ";\n";
$exp = [
	[
		'#merged=15',             'chr1',
		'start1',                'end1',
		'#chr2',                 'start2',
		'end2',                  'EBF1.tiny.bed [n]',
		'IKZF1.tiny.bed [n]',    'EBF1.tiny.bed: 3\' EBF1',
		'EBF1.tiny.bed: 5\' EBF1', 'IKZF1.tiny.bed: 3\' IKZF',
		'IKZF1.tiny.bed: 5\' IKZF'
	],
	[
		'chr1', '755000', '760000', 'chr1', '778420', '778642',
		'0',    '1',      '0',      '0'
	],
	[
		'chr10',    '91055000', '91065000', 'chr10',
		'91092115', '91092337', '0',        '2',
		'0',        '1'
	],
	[
		'chr10',    '91060000', '91065000', 'chr10',
		'91088008', '91088230', '0',        '1',
		'1',        '1'
	],
	[
		'chr10',    '91061097', '91061319', 'chr10',
		'91115000', '91120000', '0',        '1',
		'1',        '0'
	],
	[
		'chr10',    '91088008', '91088230', 'chr10',
		'91170000', '91175000', '0',        '1',
		'0',        '1'
	],
	[
		'chr10',    '91092115', '91092337', 'chr10',
		'91125000', '91130000', '0',        '1',
		'0',        '0'
	],
	[
		'chr1',     '15025000', '15030000', 'chr1',
		'15251335', '15251553', '1',        '0',
		'1',        '0'
	],
	[
		'chr10',    '91055000', '91065000', 'chr10',
		'91093470', '91093688', '2',        '0',
		'0',        '2'
	],
	[
		'chr10',    '91093470', '91093688', 'chr10',
		'91125000', '91130000', '1',        '0',
		'0',        '1'
	],
	[
		'chr10',    '91093470', '91093688', 'chr10',
		'91170000', '91175000', '1',        '0',
		'1',        '0'
	],
	[
		'chr10',    '91175237', '91175455', 'chr10',
		'91400000', '91405000', '1',        '0',
		'10',       '0'
	],
	[
		'chr10',    '92863644', '92863862', 'chr10',
		'92920000', '92925000', '1',        '0',
		'0',        '10'
	],
	[
		'chr1', '1092861', '1093183', 'chr1', '1165000', '1170000',
		'1',    '1',       '1',       '0',    '1',       '1'
	],
	[
		'chr1',     '15025000', '15030000', 'chr1',
		'15062470', '15062696', '1',        '1',
		'0',        '1',        '0',        '1'
	],
	[
		'chr10',    '91090000', '91095000', 'chr10',
		'91150000', '91155000', '1',        '1',
		'0',        '0',        '1',        '1'
	]
];

is_deeply( $out, $exp, "error file correct" );

sub slurpFile {
	my $file = shift;
	open( my $in, "<$file" ) or die $!;
	my @r;
	while (<$in>) {
		chomp();
		push( @r, [ split( "\t", $_ ) ] );
	}
	close($in);
	return \@r;
}

#print "\$exp = ".root->print_perl_var_def($value ).";\n";
