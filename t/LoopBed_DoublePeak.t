#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 11;
BEGIN { use_ok 'LoopBed::DoublePeak' }

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value, @values, $exp );

my ( $p1, $p2, $before, $after, $map, $map_not_second );
$p1 = LoopBed::Peak->new( 'chr1', 16000, 14000 );
$p2 = LoopBed::Peak->new( 'chr1', 4000, 6000 );


my $OBJ = LoopBed::DoublePeak -> new( $p1, $p2, [1,3,0] );

is_deeply ( ref($OBJ) , 'LoopBed::DoublePeak', 'simple test of function LoopBed::DoublePeak -> new() ');

is_deeply($OBJ->pchr(), 'chr1:4000-6000 to chr1:14000-16000' , 'correct definition (both reordered)');

$p2 = LoopBed::Peak->new( 'chr1', 1000, 2000 );

$before = LoopBed::DoublePeak -> new( $p1, $p2, [1,3,0] );

ok( ! $OBJ->overlaps( $before, 0), "no overlap" );

ok( $OBJ->comes_after( $before ), $OBJ->pchr()." comes after ". $before->pchr() );

ok(! $OBJ->comes_before( $before ), $OBJ->pchr()." ! comes before ". $before->pchr() );

$p2 = LoopBed::Peak->new( 'chr1', 7000, 8000 );

$after = LoopBed::DoublePeak -> new( $p1, $p2, [1,3,0] );

ok( ! $OBJ->overlaps( $after, 0), "no overlap" );

ok( $OBJ->comes_before( $after ), $OBJ->pchr()." comes before ". $after->pchr() );


$p2 = LoopBed::Peak->new( 'chr1', 3000, 5000 );

$map = LoopBed::DoublePeak -> new( $p1, $p2, [0 ,0, 1] );

ok(  $OBJ->overlaps( $map, 0), "overlap with ". $map->pchr() );

$OBJ->add( $map );

is_deeply( $OBJ->print(), 'chr1	3000	6000	chr1	14000	16000	1	3	1', 'correct add' );

$p1 =  LoopBed::Peak->new( 'chr1', 9000, 11000 );
$map_not_second = LoopBed::DoublePeak -> new( $p1, $p2, [0 ,0, 1] );

ok( ! $OBJ->overlaps( $map_not_second, 0), "no overlap with ". $map->pchr() );




#print "\$exp = ".root->print_perl_var_def($value ).";\n";


