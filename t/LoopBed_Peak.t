#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 8;
BEGIN { use_ok 'LoopBed::Peak' }

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value, @values, $exp, $tmp );

my $OBJ = LoopBed::Peak -> new( 'chr1', 2000, 4000 );
is_deeply ( ref($OBJ) , 'LoopBed::Peak', 'simple test of function LoopBed::Peak -> new() ');

## so this is extremely simple!
is_deeply( $OBJ->pchr() , 'chr1:2000-4000', 'prints as chr1:2000-4000' );
is_deeply( $OBJ->print(), join("\t",'chr1', 2000, 4000), "the data" );
 
$tmp = LoopBed::Peak -> new( 'chr1', 3999, 9000 );

ok( $OBJ->overlaps($tmp ), "overlaps with ". $tmp->pchr() );


$tmp = LoopBed::Peak -> new( 'chr1', 1000, 2100 );

ok( $OBJ->overlaps($tmp ), "overlaps with ". $tmp->pchr() );


$tmp = LoopBed::Peak -> new( 'chr1', 8000, 9000 );

ok( ! $OBJ->overlaps($tmp ), "overlaps with ". $tmp->pchr() );

ok( $OBJ->overlaps($tmp, 6500 ), "overlaps with ". $tmp->pchr(). " + 6500" );



#print "\$exp = ".root->print_perl_var_def($value ).";\n";



