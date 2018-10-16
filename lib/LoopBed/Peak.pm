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

	unless ( $self->isValid() ){
		Carp::confess( "I am not a valid peak:\n".$self->print() );
	}
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

sub isValid {
	my $self = shift;
	return ($self->{'s'} =~ m/^\d+$/ and  $self->{'e'} =~ m/^\d+$/);
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
