#! /usr/bin/perl -w

=head1 LICENCE

  Copyright (C) 2017-08-22 Stefan Lang

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

=head1 CREATED BY

   binCreate.pl from git@github.com:stela2502/Stefans_Lib_Esentials.git commit


=head1  SYNOPSIS

    reset_files.pl
       -files     :<please add some info!> you can specify more entries to that


       -help           :print this help
       -debug          :verbose output

=head1 DESCRIPTION

  git reset head a list of files in the commit message from a file

  To get further help use 'reset_files.pl -help' at the comman line.

=cut

use Getopt::Long;
use Pod::Usage;

use strict;
use warnings;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, @files);

Getopt::Long::GetOptions(
       "-files=s{,}"    => \@files,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $files[0]) {
	$error .= "the cmd line switch -files is undefined!\n";
}
elsif( -f $files[0]  ) {
	open ( TMP , "<$files[0]" ) or die "I could not open the file list file\n";
	my @tmp;
	while ( <TMP> ){
		chomp;
		if ( $_ =~m /^#\s*new file:\s*(.*)/) {
			push( @tmp, $1 );
		}
		else {
			push ( @tmp, $_ );
		}
	}
	close ( TMP );
	@files = @tmp;
}


if ( $help ){
	print helpString( ) ;
	exit;
}

if ( $error =~ m/\w/ ){
	helpString($error ) ;
	exit;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage);
	print "$errorMessage.\n";
	pod2usage(q(-verbose) => 1);
}



my ( $task_description);

$task_description .= 'perl '.$plugin_path .'/reset_files.pl';
$task_description .= ' -files "'.join( '" "', @files ).'"' if ( defined $files[0]);


## Do whatever you want!

system( 'git reset --soft HEAD^' );

foreach ( @files ) {
	if ( -f $_ ) {
		system( "git reset HEAD $_" );
	}
}

print  "Now you should be able to commit the updated file list.\n";
