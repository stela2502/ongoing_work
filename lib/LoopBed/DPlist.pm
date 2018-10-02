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
			}elsif ( @{$self->{'data'}}[$i]-> comes_before( @{$self->{'data'}}[$a] ) ) {
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
	if ( $merged > 0  and $iter +1 < 5 ) {
		#warn "merged $merged reads ($iter)\n";
		return $self->internal_merge( $minRes, $iter +1);
	}
	return $self;
}

sub add {
	my ( $self, $dp ) = @_;
	if (scalar(@{$self->{'data'}}) == 0 ){
		#print "Addin into empty array - OK?\n";
		push( @{$self->{'data'}}, $dp );
	}elsif ( $dp->{'p1'}->{'s'} > @{$self->{'data'}}[scalar(@{$self->{'data'}})-1]->{'p1'}->{'e'} ) {
	#	print "Adding at the end of the old array\n";
		push( @{$self->{'data'}}, $dp );
	}else {
		my $add = 0;
		for ( my $i =  @{$self->{'data'}}-2; $i > -1; $i -- ) {
		#	print "add check: @{$self->{'data'}}[$i]->{'p1'}->{'s'} > $dp->{'p1'}->{'e'}\n";
			if (  @{$self->{'data'}}[$i]->{'p1'}->{'e'} < $dp->{'p1'}->{'s'}  ){
				splice( @{$self->{'data'}}, $i+1, 0, $dp ); ## add it before this entry
		#		print "Splice add after/instedad of $i+1\n";
				$add = 1;
				last; 
			}
		}
		$self->{'data'} = [ sort { $a->{'p1'} -> {'s'} <=> $b->{'p1'} -> {'s'} } @{$self->{'data'}}, $dp ];
		#warn "I could not find where to add this thing!" if ( $add == 0);
		#$self->{'data'} = [ sort { $a->{'p1'} -> {'s'} <=> $b->{'p1'} -> {'s'} } @{$self->{'data'}}, $dp ];
	}
	#print "@{$self->{'data'}}[0]->{'p1'}->{'c'}:". join(", ", map{ $_->{'p1'}->{'s'} } @{$self->{'data'}} )."\n";
	return $self;
}


1;
