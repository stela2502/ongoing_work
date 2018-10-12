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
		my $dp;
		if ( scalar(@line) > 6 ){
			$dp = LoopBed::DoublePeak->new( $p1, $p2,\@membership, [@line[6..scalar(@line)-1]], $fname );
		}else {
			$dp = LoopBed::DoublePeak->new( $p1, $p2,\@membership, [], $fname );
		}
		$OBJ -> add_check_overlap ( $dp, $minRes );
	}
}

&readFile( $plugin_path."/data/loop.bed" );

#print "\$exp = ".root->print_perl_var_def( $OBJ-> asArrayOfArrays() ).";\n";
$exp = [ 
[ 'chr1', '3000', '4000', 'chr1', '9000', '12000', '0', '4', '0', '3', '1' ], 
[ 'chr1', '3000', '4000', 'chr1', '13000', '14000', '0', '1', '0', '1', '1' ], 
[ 'chr1', '5000', '6000', 'chr1', '10000', '12000', '0', '3', '0', '1', '2' ] 
];


is_deeply($OBJ-> asArrayOfArrays(),  $exp, "data read as expected" );

#print "\$exp = ".root->print_perl_var_def( [ map{ 	@{$OBJ->{'data'}}[$_]->print() } 0..@{$OBJ->{'data'}}-1  ] ).";\n";

$OBJ-> {'data'} = [ @{$OBJ-> {'data'}}, map { my $t = ref($_) -> new( $_->{'p1'},$_->{'p2'},$_->{'membership'}); $t->{'addCols'} = $_->{'addCols'}; $t } @{$OBJ-> {'data'}} ];

ok(scalar(@{$OBJ->{'data'}}) == 6, "duplicated file");

$OBJ = $OBJ->sortByStart();

#print "\$exp = ".root->print_perl_var_def( $OBJ-> asArrayOfArrays() ).";\n";

$exp = [
[ 'chr1', '3000', '4000', 'chr1', '9000', '12000', '0', '4', '0', '3', '1' ], 
[ 'chr1', '3000', '4000', 'chr1', '9000', '12000', '0', '4', '0', '3', '1' ], 
[ 'chr1', '3000', '4000', 'chr1', '13000', '14000', '0', '1', '0', '1', '1' ], 
[ 'chr1', '3000', '4000', 'chr1', '13000', '14000', '0', '1', '0', '1', '1' ], 
[ 'chr1', '5000', '6000', 'chr1', '10000', '12000', '0', '3', '0', '1', '2' ], 
[ 'chr1', '5000', '6000', 'chr1', '10000', '12000', '0', '3', '0', '1', '2' ] 
];

is_deeply($OBJ-> asArrayOfArrays(),  $exp, "data read as expected" );

$OBJ->internal_merge();

#print "\$exp = ".root->print_perl_var_def( $OBJ-> asArrayOfArrays() ).";\n";

$exp = [ 
[ 'chr1', '3000', '4000', 'chr1', '9000', '12000', '0', '8', '0', '6', '2' ], 
[ 'chr1', '3000', '4000', 'chr1', '13000', '14000', '0', '2', '0', '2', '2' ], 
[ 'chr1', '5000', '6000', 'chr1', '10000', '12000', '0', '6', '0', '2', '4' ] 
];

is_deeply($OBJ-> asArrayOfArrays(),  $exp, "data after merge" );



$OBJ = LoopBed::DPlist -> new();

&readFile( $plugin_path."/data/loop.bed", 15000 );

#print "\$exp = ".root->print_perl_var_def( $OBJ-> asArrayOfArrays() ).";\n";

$exp = [ [ 'chr1', '3000', '6000', 'chr1', '9000', '14000', '0', '8', '0', '5', '4' ] ];
is_deeply($OBJ-> asArrayOfArrays(),  $exp, "data read as expected using minRes = 15000" );



#print "\$exp = ".root->print_perl_var_def($value ).";\n";


