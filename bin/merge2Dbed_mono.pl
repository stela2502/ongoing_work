#!/usr/bin/env perl
use warnings;


# Copyright 2009 - 2018 Christopher Benner <cbenner@ucsd.edu>
#
# This file is part of HOMER
#
# HOMER is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# HOMER is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

#use stefans_libs::root;

use POSIX;
use File::Basename;

sub printCMD {
	print STDERR "\n\tmerge2Dbed.pl [options] <2D BED file1> <2D BED file2> [2D BED file3]...\n";
	print STDERR "\n\tOptions:\n";
	print STDERR "\t\t-res <#> (maximum distance between endpoints to merge, default: 15000)\n";
	print STDERR "\t\t\tUsually for loops -res should be set to the window/superRes size, for TADs 2x window/superRes\n";
	print STDERR "\t\t-loop (treat 2D bed input files as loops, default)\n";
	print STDERR "\t\t-tad (treat 2D bed input files as TADs)\n";
	print STDERR "\t\t-prefix <filePrefix> (output venn diagram overlaps to separate files)\n";
	print STDERR "\n";
	exit;
}

if (@ARGV < 2) {
	printCMD();
}
my @intFiles = ();
my $minRes = '';
$tadFlag = -1;
my $commonOnly=0;
my $prefix = '';
for (my $i=0;$i<@ARGV;$i++) {
	if ($ARGV[$i] eq '-dist' or $ARGV[$i] eq '-res' or $ARGV[$i] eq '-window' or $ARGV[$i] eq '-superRes') {
		$minRes = $ARGV[++$i];
	} elsif ($ARGV[$i] eq '-tad' or $ARGV[$i] eq '-TAD') {
		$tadFlag = 1;
		die "Sorry tad support is broken!\n";
	} elsif ($ARGV[$i] eq '-cp' or $ARGV[$i] eq '-loop' or $ARGV[$i] eq '-loops') {
		$tadFlag = 0;
	} elsif ($ARGV[$i] eq '-commonOnly') {
		$commonOnly=1;
	} elsif ($ARGV[$i] eq '-prefix') {
		$prefix = $ARGV[++$i];
	} elsif ($ARGV[$i] =~ /^-/) {
		print STDERR "!!! Error: $ARGV[$i] not recognized!!!\n";
		printCMD();
	} else {
		push(@intFiles, $ARGV[$i]);
	}
}

my $numFiles = scalar(@intFiles);
if ($tadFlag == -1) {
	$tadFlag = 0;
	for (my $i=0;$i<@intFiles;$i++) {
		my $v = check2Dbed($intFiles[$i]);
		if ($v < 0) {
			print STDERR "\tWarning: $intFiles[$i] may not have any valid 2D entries...\n";
		} elsif ($v eq '1') {
			print STDERR "\tFile $intFiles[$i] looks like a TAD 2D BED file\n";
			$tadFlag++;
		} else {
			print STDERR "\tFile $intFiles[$i] looks like a loop 2D BED file\n";
		}
	}
	if ($tadFlag > 0) {
		if ($tadFlag < $numFiles) {
			print STDERR "\t!!! Warning: only $tadFlag of $numFiles look like TAD files\n";
		} else {
			print STDERR "\tTreating files as TAD 2D BED files ($tadFlag of $numFiles look like TAD files)\n";
		}
		$tadFlag = 1;
	} else {
		print STDERR "\tTreating files as loop 2D BED files\n";
		$tadFlag = 0;
	}
} elsif ($tadFlag == 1) {
	print STDERR "\tTreating files as TAD 2D BED files (-tad)\n";
} else {
	print STDERR "\tTreating files as loop 2D BED files (-loop)\n";
}

if ($tadFlag == 1) {
	die "sorry, tad support is broken\n";
}

if ($minRes eq '') {
	if ($tadFlag) {
		$minRes = 30000;
		print STDERR "\n\tMerging resolution set to $minRes (default for TAD files)\n";
	} else {
		$minRes = 15000;
		print STDERR "\n\tMerging resolution set to $minRes (default for loop files)\n";
	}
} else {
	print STDERR "\n\tMerging resolution set to $minRes (user defined)\n";
}
print STDERR "\n";

my %peaks = ();
my $id1 = 1;
my $id2 = 1;
my $index = 0;


my %toCombine =();
$extraHeader = '';

my @perFile;
for (my $i=0;$i<@intFiles;$i++) {
	warn "reading file $intFiles[$i]\n";
	push ( @perFile, read2Dbed($intFiles[$i],$i,$numFiles) );
}
my $chr = {};
foreach my $f ( @perFile ) {
	map { $chr->{$_} = 1 } keys %$f;
}

my $bed = {};
foreach my $c ( sort keys %$chr ) {		
	#warn "processing chr $c\n";
	$bed->{$c} = LoopBed::DPlist->new();
	$bed->{$c}->{'data'} = [ map{ @{$_->{$c}->{'data'}} } @perFile ];
	#warn "merging #1 chr $c\n";
	$bed->{$c}->internal_merge($minRes);
}


open (OUT, ">debug.bed" ) or die $!;
foreach my $c ( sort keys %$chr ) {		
		print OUT join( "\n", map{ $_->print() } @{$bed->{$c}->{'data'}} )
}
close ( OUT );
#print "The \%bed = ".root->print_perl_var_def( $bed ).";\n";


my %counts = ();
my $c = 0;
my %sets = ();

foreach my $chr ( sort keys %$bed ) {
	foreach my $dp ( @{$bed->{$chr}->{'data'}} ) {
		my $memStr = $dp ->getMemStr();
		$counts{$memStr}++;
		$sets{$memStr} ||= [];
		push(@{$sets{$memStr}},$dp);
		$c++;
	}
}

if ($prefix eq '') {
	print "#merged=$c chr1\tstart1\tend1\tchr2\tstart2\tend2\n";
}
print STDERR "\t$c total features after merging\n";
print STDERR "\nFeatures";
foreach(@intFiles) {
	print STDERR "\t$_";
}
print STDERR "\tName\n";
foreach(sort keys %counts) {

	my $name = '';	
	my $file = '';	
	print STDERR "$counts{$_}";
	
	for (my $i=0;$i<$numFiles;$i++) {
		my $substr = substr($_,$i,1);
		if ($substr eq '1') {
			print STDERR "\tX";
			$name .= "|" . $intFiles[$i];
			$file .= "_" . $intFiles[$i];
		} else {
			print STDERR "\t";
		}
	}
	$name =~ s/^\|//;
	print STDERR "\t$name\n";

	my $fh=*STDOUT;
	if ($prefix ne '') {
		my $outFile = $prefix . $file;
		$outFile =~ s/\//_/g;
		open ($fh,">",$outFile);
	}
	print $fh "#merged=$counts{$_} chr1\tstart1\tend1\tchr2\tstart2\tend2" . join("\t", map {basename($_)} @intFiles) . "\n";
	
	foreach(@{$sets{$_}}) {
		print $fh $_->print()."\n";
	}
	if ($prefix ne '') {
		close $fh;
	}
}
exit;



sub check2Dbed {
	my ($file) = @_;
	open IN, $file or die "Could not open file: $file\n";
	my $same=0;
	my $total=0;
	while (<IN>) {
		chomp;
		s/\r//g;
		my @line = split /\t/;
		next if ($line[0] =~ /^#/);
		next if (@line < 6);
		if (($line[1] eq $line[4]) and ($line[0] eq $line[3]) and ($line[2] eq $line[5])) {
			$same++;
		}
		$total++;
	}
	close IN;
	return -1 if ($total < 1);
	return 1 if ($same/$total > 0.5);
	return 0;
}

sub read2Dbed {
	my ($file,$index,$numFiles) = @_;
	my $bed = {};
	$extraHeader = '';
	my $c = 0;
	open IN, $file or die "Could not open file: $file\n";
	my ($add, $storedDP, $last);
	
	while (<IN>) {
		$c++;
		chomp;
		s/\r//g;
		my @line = split /\t/;
		if ($c == 1) {
			for (my $i=6;$i<@line;$i++){ 
				if ($line[0] =~ /^#/) {
					$extraHeader .= "\t" . $line[$i];
				} else {
					$extraHeader .= "\tinfo";
				}
			}
			unless ( $line[0] =~ m/^[Cc]hr/ ) {
				next;
			}
		}
		my $p1 = LoopBed::Peak ->new( @line[0..2] );
		my $p2 = LoopBed::Peak ->new( @line[3..5] );
		my @membership = map{ 0 } 0..($numFiles-1);
		$membership[$index] = 1;
		my $dp = LoopBed::DoublePeak->new( $p1, $p2,\@membership );
		$bed->{$dp->{'p1'}->{'c'} } ||= LoopBed::DPlist->new();
		$bed->{$dp->{'p1'}->{'c'} } -> add ( $dp, $minRes );	
	}
	foreach ( sort keys %$bed ) {
		$bed->{$_} -> internal_merge()
	}
	close IN;

	return $bed;
}

1;package LoopBed::DoublePeak;

#use FindBin;
#use lib "$FindBin::Bin/../lib/";
#created by bib_create.pl from  commit 
use strict;
use warnings;

=head1 LICENCE

  Copyright (C) 2018-10-02 Stefan Lang

  This program is free software; you can redistribute it 
  and/or modify it under the terms of the GNU General Public License 
  as published by the Free Software Foundation; 
  either version 3 of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful, 
  but WITHOUT ANY WARRANTY; without even the implied warranty of 
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
  See the GNU General Public License for more details.

  You should have received a copy of the GNU General Public License 
  along with this program; if not, see <http://www.gnu.org/licenses/>.


=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

LoopBed::DoublePeak

=head1 DESCRIPTION

Class to store double cromosome loactaions in

=head2 depends on


=cut


=head1 METHODS

=head2 new (  $class, $p1, $p2, $membership  )

new returns a new object reference of the class LoopBed::DoublePeak.
All entries of the hash will be copied into the objects hash - be careful t use that right!

=cut



use strict;
use warnings;
use List::Util qw[min max];

use LoopBed::Peak;

sub new {

	my ( $class, $p1, $p2, $membership ) = @_;

	my ($self);

	#always give these two a useful order
	if ( $p1->{'c'} eq $p2->{'c'} ) {
		( $p1, $p2 ) = sort { $a->{'s'} <=> $b->{'s'} } ( $p1, $p2 );
	}else {
		( $p1, $p2 ) = sort { $a->{'c'} cmp $b->{'c'} } ( $p1, $p2 );
	}

	$self = {
		'p1' => $p1,
		'p2' => $p2,
		'membership' => $membership,
		'active' => 1,
	};
	
	bless $self, $class if ( $class eq "LoopBed::DoublePeak" );

	return $self;

}

sub add {
	my ( $self, $other ) = @_;
	#print "old me:". $self->pchr()."\n";
	$self->{'p1'}->{'s'} = min( $self->{'p1'}->{'s'}, $other->{'p1'}->{'s'});
	$self->{'p1'}->{'e'} = max( $self->{'p1'}->{'e'}, $other->{'p1'}->{'e'});
	
	$self->{'p2'}->{'s'} = min( $self->{'p2'}->{'s'}, $other->{'p2'}->{'s'});
	$self->{'p2'}->{'e'} = max( $self->{'p2'}->{'e'}, $other->{'p2'}->{'e'});
	
	for (my $i = 0; $i <@{$self->{'membership'}}; $i++ ){
		@{$self->{'membership'}}[$i] += @{$other->{'membership'}}[$i]
	}
	$other->{'active'} = 0;
	#print "new me:".  $self->pchr()."\n";
	return $self;
}

sub comes_after{
	my ( $self, $dp ) = @_;
	if ($self->{'p1'}->{'s'} ==  $dp->{'p1'}->{'s'} ) {
		return $self->{'p2'}->comes_after($dp->{'p2'} )
	}else {
		return $self->{'p1'}->comes_after($dp->{'p1'} ) 
	}
}

sub comes_before{
	my ( $self, $dp, $maxDist  ) = @_;
	if ($self->{'p1'}->{'s'} ==  $dp->{'p1'}->{'s'} ) {
		return $self->{'p2'}->comes_before($dp->{'p2'}  )
	}else {
		return $self->{'p1'}->comes_before($dp->{'p1'} ) 
	}
}

sub overlaps{
	my ( $self, $other, $maxDist ) = @_;
	my $ok = 0;
	foreach ( 'p1', 'p2' ) {
		$ok += $self->{$_}->overlaps( $other->{$_}, $maxDist );
	}
	return $ok == 2
}

sub pchr {
	my $self = shift;
	return $self->{'p1'}->pchr()." to ".  $self->{'p2'}->pchr();
}

sub asArray{
	my ( $self ) = @_;
	return ( $self->{'p1'}->asArray() , $self->{'p2'}->asArray(), @{$self->{'membership'}} );
}

sub print {
	my $self = shift;
	return join("\t", $self->{'p1'}->print() , $self->{'p2'}->print(), join("\t", @{$self->{'membership'}} ) );
}

sub getMemStr {
	my $self = shift;
	return join("", map{ if ($_ > 0 ) {1} else {0} } @{$self->{'membership'}}) ;
}


1;
package LoopBed::DPlist;

#use FindBin;
#use lib "$FindBin::Bin/../lib/";
#created by bib_create.pl from  commit 
use strict;
use warnings;

=head1 LICENCE

  Copyright (C) 2018-10-02 Stefan Lang

  This program is free software; you can redistribute it 
  and/or modify it under the terms of the GNU General Public License 
  as published by the Free Software Foundation; 
  either version 3 of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful, 
  but WITHOUT ANY WARRANTY; without even the implied warranty of 
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
  See the GNU General Public License for more details.

  You should have received a copy of the GNU General Public License 
  along with this program; if not, see <http://www.gnu.org/licenses/>.


=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

LoopBed::DPlist

=head1 DESCRIPTION

A class to store chromosome wise DoublePeak's and automaticly merge overlapping

=head2 depends on


=cut


=head1 METHODS

=head2 new ( $class )

new returns a new object reference of the class LoopBed::DPlist.
All entries of the hash will be copied into the objects hash - be careful t use that right!

=cut


use strict;
use warnings;

use LoopBed::DoublePeak;

sub new {

	my ( $class) = @_;

	my ($self);

	$self ={
		'data' => [],
    };
	

	bless $self, $class if ( $class eq "LoopBed::DPlist" );

	return $self;

}

sub add_check_overlap{
	my ( $self, $dp, $minRes) =  @_;
	
	if ( @{$self->{'data'}} == 0) {
		push( @{$self->{'data'}}, $dp );
		return $self;
	}
	my $local;
	$local = @{$self->{'data'}}[0];
	if  ( $local->overlaps( $dp, $minRes)  ){
		$local->add( $dp );
		return $self;
	}
	if ($local->comes_after($dp)) {
		unshift( @{$self->{'data'}}, $dp );
		return $self;
	}
	for ( my $i = @{$self->{'data'}} -1; $i > -1; $i --) {
		
		$local = @{$self->{'data'}}[$i];
		if ( $local->overlaps( $dp, $minRes) ) {
			## is match
			$local->add( $dp );
			return $self;
		}
		if ( $local->comes_after($dp) ) {
			## OK probably the next does match?
			next;
		}
		if ( $local->comes_before($dp) ) {
			## OK this thing should be added instead of this
			splice( @{$self->{'data'}}, $i+1,0, $dp );
			return $self;
		}
	}
	Carp::confess ( "This should not be reached! ".$dp->pchr()."\n" );
}


sub print {
	my ( $self ) = @_;
	my @ret;
	for ( my $i = 0; $i < @{$self->{'data'}}; $i ++){
		if ( @{$self->{'data'}}[$i]->{'active'} ) {
			push( @ret, @{$self->{'data'}}[$i]->print());
		}
	}
	return join("\n", @ret );
}

sub asArrayOfArrays {
	my ( $self ) = @_;
	return [ map { [$_->asArray() ] } @{$self->{'data'}} ];
}

sub sortByStart {
	my ( $self ) = @_;
	
	my $byThat = sub{ 
		if ( $a->{'p1'}->{'s'} == $b->{'p1'}->{'s'} ) {
			$a->{'p2'}->{'s'} <=> $b->{'p2'}->{'s'}	
		} 
		else {
			$a->{'p1'}->{'s'} <=> $b->{'p1'}->{'s'}	
		} 
	};
	my $tmp = [ sort $byThat @{$self->{'data'}} ];
	$self->{'data'} = $tmp;
	return $self;
}

sub internal_merge{
	my ( $self, $minRes, $iter) = @_;
	$minRes ||= 0;
	$iter ||= 0;
	$self->sortByStart();
	LOOP: for ( my $i = 0; $i < @{$self->{'data'}} -1; $i ++ ){
		next unless (  @{$self->{'data'}}[$i]->{'active'} );
		for( my $a = $i+1; $a < @{$self->{'data'}}; $a++ ) {
			next unless (  @{$self->{'data'}}[$a]->{'active'} );
			if ( @{$self->{'data'}}[$i] -> overlaps ( @{$self->{'data'}}[$a]) ) {
				 @{$self->{'data'}}[$i] -> add ( @{$self->{'data'}}[$a]) ;
				 @{$self->{'data'}}[$a]->{'active'} = 0;
			}elsif ( @{$self->{'data'}}[$i]->{'p1'}->{'e'} + $minRes < @{$self->{'data'}}[$a]->{'p1'}->{'e'} - $minRes )  {
				## out of range
				next LOOP;
			}
		}
	}
	## remove the inactive..
	my (@new, $merged);
	$merged = 0;
	for ( my $i = 0; $i < @{$self->{'data'}}; $i ++ ) {
		if (@{$self->{'data'}}[$i]->{'active'} ) {
			push(@new, @{$self->{'data'}}[$i])
		}else {
			$merged ++;
		}
	}
	$self->{'data'} = \@new;
	if ( $merged > 0  and $iter +1 < 10 ) {
		#warn "merged $merged reads ($iter)\n";
		return $self->internal_merge( $minRes, $iter +1);
	}
	return $self;
}

sub add {
	my ( $self, $dp ) = @_;
	push( @{$self->{'data'}}, $dp );
	return $self;
}


1;
package LoopBed::Peak;

#use FindBin;
#use lib "$FindBin::Bin/../lib/";
#created by bib_create.pl from  commit 
use strict;
use warnings;


=head1 LICENCE

  Copyright (C) 2018-10-02 Stefan Lang

  This program is free software; you can redistribute it 
  and/or modify it under the terms of the GNU General Public License 
  as published by the Free Software Foundation; 
  either version 3 of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful, 
  but WITHOUT ANY WARRANTY; without even the implied warranty of 
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
  See the GNU General Public License for more details.

  You should have received a copy of the GNU General Public License 
  along with this program; if not, see <http://www.gnu.org/licenses/>.


=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

LoopBed::Peak

=head1 DESCRIPTION

a simple class to store single cghromosome locations in

=head2 depends on


=cut


=head1 METHODS

=head2 new ( $class, $chromosome, $start, $end )

new returns a new object reference of the class LoopBed::Peak.
All entries of the hash will be copied into the objects hash - be careful t use that right!

=cut



use strict;
use warnings;
use POSIX;

sub new {

	my ( $class, $c, $s, $e ) = @_;

	my ($self);

	unless ( defined $c and defined $s) {
		Carp::confess( "I need chr start and end at creation time");
	}
    if ( $s < $e ) {
		$self = {
			c => $c,
			s => $s, 
			e => $e
		};
    }else {
    	$self = {
			c => $c,
			s => $e, 
			e => $s
		};
    }
	
	$self->{'m'} = floor( ($self->{'s'} + $self->{'e'} ) / 2 );

	bless $self, $class if ( $class eq "LoopBed::Peak" );

	return $self;

}

=head2 overlaps ( $self, <LoopBed::Peak>, $max_dist_of_centers )

=cut

sub overlaps{
	my ( $self, $other, $maxDist) = @_;
	$maxDist ||= 0;
	if ( $self->{'c'} eq $other->{'c'} ) {
		return 1 if ( $self->{'s'} <= $other->{'e'}  and $self->{'e'} >= $other->{'s'} );
		return 1 if ( abs($self->{'m'} - $other->{'m'} ) <= $maxDist );
	}
	return 0;
}

sub comes_after{
	my ( $self, $peak ) = @_;
	if ( $self->{'c'} eq $peak->{'c'} ) {
		return  $peak->{'s'} < $self->{'s'};
	}else {
		warn ref($self)."::comes_after(".$self->pchr().", ". $peak->pchr()." ): The peaks are not on the same chromosome";
	}
	return -1;
}

sub comes_before{
	my ( $self, $peak ) = @_;
	if ( $self->{'c'} eq $peak->{'c'} ) {
		return  $peak->{'s'} > $self->{'s'};
	}else {
		warn ref($self)."::comes_after(".$self->pchr().", ". $peak->pchr()." ): The peaks are not on the same chromosome";
	}
	return -1;
}

sub pchr{
	my $self = shift;
	return $self->{'c'}.":". $self->{'s'}."-". $self->{'e'} ;
}

sub asArray{
	my($self) =  @_;
	return ($self->{'c'}, $self->{'s'}, $self->{'e'} );
}
sub print{
	my $self = shift;
	return join("\t", $self->{'c'}, $self->{'s'}, $self->{'e'} );
}


1;
