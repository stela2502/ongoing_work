#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 7;
BEGIN { use_ok 'LoopBed::DPlist' }

use stefans_libs::root;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value, @values, $exp );
my $OBJ = LoopBed::DPlist -> new();
is_deeply ( ref($OBJ) , 'LoopBed::DPlist', 'simple test of function LoopBed::DPlist -> new() ');

## this thing should be able to pile up double peaks Loop files



sub readFile {
	my ( $fname, $minRes ) =  @_;
	open ( IN, "<".$fname) or die "I could not open the file $fname\n$!";
	$minRes ||= 0;
	my @line;
	my $index = 1;
	my $numFiles = 3;
	
	while( <IN> ) {
		next if ( $_ =~ m/^#/);
		chomp;
		@line = split("\t",$_);
		my $p1 = LoopBed::Peak ->new( @line[0..2] );
		my $p2 = LoopBed::Peak ->new( @line[3..5] );
		my @membership = map{ 0 } 0..($numFiles-1);
		$membership[$index] = 1;
		my $dp = LoopBed::DoublePeak->new( $p1, $p2,\@membership );
		$OBJ -> add_check_overlap ( $dp, $minRes );
	}
}

&readFile( $plugin_path."/data/loop.bed" );

#print "\$exp = ".root->print_perl_var_def( $OBJ-> asArrayOfArrays() ).";\n";
$exp = [ 
[ 'chr1', '3000', '4000', 'chr1', '9000', '12000', '0', '4', '0' ], 
[ 'chr1', '3000', '4000', 'chr1', '13000', '14000', '0', '1', '0' ], 
[ 'chr1', '5000', '6000', 'chr1', '10000', '12000', '0', '3', '0' ] 
];

is_deeply($OBJ-> asArrayOfArrays(),  $exp, "data read as expected" );

$OBJ-> {'data'} = [ @{$OBJ-> {'data'}}, map { ref($_) -> new( $_->{'p1'},$_->{'p2'},$_->{'membership'}) } @{$OBJ-> {'data'}} ];

ok(scalar(@{$OBJ->{'data'}}) == 6, "duplicated file");

$exp = [ 
[ 'chr1', '3000', '4000', 'chr1', '9000', '12000', '0', '4', '0' ], 
[ 'chr1', '3000', '4000', 'chr1', '9000', '12000', '0', '4', '0' ], 
[ 'chr1', '3000', '4000', 'chr1', '13000', '14000', '0', '1', '0' ], 
[ 'chr1', '3000', '4000', 'chr1', '13000', '14000', '0', '1', '0' ], 
[ 'chr1', '5000', '6000', 'chr1', '10000', '12000', '0', '3', '0' ], 
[ 'chr1', '5000', '6000', 'chr1', '10000', '12000', '0', '3', '0' ] 
];

$OBJ = $OBJ->sortByStart();

is_deeply($OBJ-> asArrayOfArrays(),  $exp, "data read as expected" );

$OBJ->internal_merge();

print "\$exp = ".root->print_perl_var_def( $OBJ-> asArrayOfArrays() ).";\n";

$exp = [ 
[ 'chr1', '3000', '4000', 'chr1', '9000', '12000', '0', '8', '0' ], 
[ 'chr1', '3000', '4000', 'chr1', '13000', '14000', '0', '2', '0' ], 
[ 'chr1', '5000', '6000', 'chr1', '10000', '12000', '0', '6', '0' ]
];
is_deeply($OBJ-> asArrayOfArrays(),  $exp, "data after merge" );


$OBJ = LoopBed::DPlist -> new();

&readFile( $plugin_path."/data/loop.bed", 15000 );
$exp = [ [ 'chr1', '3000', '6000', 'chr1', '9000', '14000', '0', '8', '0' ] ];
is_deeply($OBJ-> asArrayOfArrays(),  $exp, "data read as expected using minRes = 15000" );


#print "\$exp = ".root->print_perl_var_def($value ).";\n";


