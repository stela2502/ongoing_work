#! /usr/bin/env perl
use warnings;
use strict;

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
use LoopBed::DPlist;
use stefans_libs::root;

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

my ( $tadFlag, $extraHeader);

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

my $cmd = basename($0);
if ( $minRes ) {
	$cmd .= " -res $minRes"
}
if ( $prefix =~ m/\w/ ) {
	$cmd .= " -prefix $prefix"
}
if ( $tadFlag == 0 ){
	$cmd .= " -loop"
}
if ( $commonOnly ){
	warn "-commonOnly is not implemented here - please perform this step in the downstream analysis!"
}
$cmd .= " '". join("' '",  @intFiles)."'";

my $logF = join(".", basename($0), $$, 'log');
open ( LOG,">", $logF ) or die "I could not create the log file '$logF'\n$!";
print LOG $cmd."\n";
close ( LOG);
warn "created cmd log file '$logF'\n$prefix\n";


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
$extraHeader = {};

my @perFile;
for (my $i=0;$i<@intFiles;$i++) {
	warn "reading file $intFiles[$i]\n";
	push ( @perFile, read2Dbed($intFiles[$i],$i,$numFiles) );
}
warn "Files read\n";

my $chr = {};
foreach my $f ( @perFile ) {
	map { $chr->{$_} = 1 } keys %$f;
}

my $bed = {};
foreach my $c ( sort keys %$chr ) {		
	#warn "processing chr $c\n";
	$bed->{$c} = LoopBed::DPlist->new();
	for ( my $i = 0 ; $i < @perFile;$i++) {
		push( @{$bed->{$c}->{'data'}}, @{$perFile[$i]->{$c}->{'data'}} ) if ( defined $perFile[$i]->{$c})
	}
	#$bed->{$c}->{'data'} = [ map{ @{$_->{$c}->{'data'}} if ( $_->{$c} ) } @perFile ];
	#warn "merging #1 chr $c\n";
	$bed->{$c}->isValid($c." with a total of ".scalar(@{$bed->{$c}->{'data'}})." entries");
	$bed->{$c}->internal_merge($minRes);
}

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

open (OUT, ">debug.bed" ) or die $!;
my $tmp;	
print OUT "#merged=$c\tchr1\tstart1\tend1\t#chr2\tstart2\tend2\t" . join("\t", map {basename($_)." [n]"} @intFiles) ."\t", join("\t", map { $extraHeader->{$_} } sort keys %$extraHeader ),"\n";
foreach my $c ( sort keys %$chr ) {		
	print OUT join( "\n", map{ $_->print() } @{$bed->{$c}->{'data'}} )."\n";
}
close ( OUT );

if ($prefix eq '') {
	print  "#merged=$c\tchr1\tstart1\tend1\t#chr2\tstart2\tend2\t" . join("\t", map {basename($_)." [n]"} @intFiles) ."\t", join("\t", map { $extraHeader->{$_} } sort keys %$extraHeader ),"\n";
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
		print $fh "#merged=$counts{$_}\tchr1\tstart1\tend1\t#chr2\tstart2\tend2\t" . join("\t", map {basename($_)." [n]"} @intFiles) ."\t", join("\t", map { $extraHeader->{$_} } sort keys %$extraHeader ),"\n";
	}
	
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
	my $in = openFile( $file );
	my $same=0;
	my $total=0;
	while (<$in>) {
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
	close $in;
	return -1 if ($total < 1);
	return 1 if ($same/$total > 0.5);
	return 0;
}


sub openFile {
	my $file = shift;
	my $in ;
	if ( $file =~ m/gz$/ ) {
		open ( $in, "zcat $file |") or die "open the zcat pipe for file '$file'\n$!";
	}else {
		open ($in, "<", $file ) or Carp::confess( "Could not open file: '$file'\n$!" );
	}
	return $in
}

sub read2Dbed {
	my ($file,$index,$numFiles) = @_;
	my $bed = {};
	my $c = 0;
	
	my ($add, $storedDP, $last);
	
	my $fname =  basename( $file );
	$extraHeader->{$fname} = undef;
	my $in = openFile( $file );
	
	LINE: while (<$in>) {
		$c++;
		chomp;
		s/\r//g;
		my @line = split /\t/;
		if ( $line[0] =~ /^#/ and scalar(@line) > 6 or ! ( $line[1] =~m/^\d+$/ )  ){
			$extraHeader->{$fname} = join("\t",  map {$fname.": ".$line[$_]} 6..@line-1 );
			next LINE;
		}elsif ( scalar(@line) > 6 and  ! (defined $extraHeader->{$fname} ) ) {
			$extraHeader->{$fname} = join("\t",  map {$fname.": info ". ($_ - 5)} 6..@line-1 );
		}
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
		$bed->{$dp->{'p1'}->{'c'} } ||= LoopBed::DPlist->new();
		$bed->{$dp->{'p1'}->{'c'} } ->  add ( $dp, $minRes );	
	}
	foreach ( sort keys %$bed ) {
		$bed->{$_} -> internal_merge()
	}
	close $in;

	return $bed;
}

