package LoopBed::DoublePeak;

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

	my ( $class, $p1, $p2, $membership, $addCols, $fname ) = @_;

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
		'addCols' => {},
		'active' => 1,
	};
	
	if ( defined $fname ) {
		$self->{'addCols'} ->{$fname} = $addCols;
	}
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
	## now add the other information - simple sum is the only one I have implemented for now
	foreach my $fname ( $self->unique( keys %{$self->{'addCols'}}, keys %{$other->{'addCols'}})) {
		unless ( defined $self->{'addCols'}->{$fname} ){
			$self->{'addCols'}->{$fname} = $other->{'addCols'}->{$fname};
		}elsif ( defined $self->{'addCols'}->{$fname} and defined $other->{'addCols'}->{$fname} ) {
			for (my $i = 0; $i <@{$self->{'addCols'}->{$fname}}; $i++ ){
				@{$self->{'addCols'}->{$fname}}[$i] += @{$other->{'addCols'}->{$fname}}[$i]
			}
		}
	}
	$other->{'active'} = 0;
	#print "new me:".  $self->pchr()."\n";
	return $self;
}

sub unique{
	my ( $self, @d) = @_;
	my $t = { map { $_ => 1} @d };
	return sort ( keys %$t );
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
	my @r =( $self->{'p1'}->asArray() , $self->{'p2'}->asArray(), @{$self->{'membership'}} );
	foreach  my $fname( sort keys %{$self->{'addCols'}} ){
		push( @r,@{$self->{'addCols'}->{$fname}}) if ( ref($self->{'addCols'}->{$fname}) eq 'ARRAY'  );
	}
	return @r;
}

sub print {
	my $self = shift;
	my $r = join("\t", 
	 $self->{'p1'}->print(), 
	 $self->{'p2'}->print(),
	 join("\t", @{$self->{'membership'}} ),
	 join("\t", map{ 
	 	join("\t",@{$self->{'addCols'}->{$_}}) if ( ref($self->{'addCols'}->{$_}) eq "ARRAY" )  
	 	} sort keys %{$self->{'addCols'}} ) 
	);
	$r =~s/\t\t/\t/g;
	$r =~s/\t*$//;
	return $r;
}

sub getMemStr {
	my $self = shift;
	return join("", map{ if ($_ > 0 ) {1} else {0} } @{$self->{'membership'}}) ;
}


1;
