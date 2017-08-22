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
   
   binCreate.pl from  commit 
   

=head1  SYNOPSIS

    register_script.pl
       -name       : the script name
       -type       :'user' add a new documentation file into the wiki
                    'auto' mention the script in the automatic table


       -help       :print this help
       -debug      :verbose output
   
=head1 DESCRIPTION

  registers a new script and adds the links into the wiki.

  To get further help use 'register_script.pl -help' at the comman line.

=cut

use Getopt::Long;
use Pod::Usage;

use strict;
use warnings;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $name, $type);

Getopt::Long::GetOptions(
	 "-name=s"    => \$name,
	 "-type=s"    => \$type,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $name) {
	$error .= "the cmd line switch -name is undefined!\n";
}
unless ( defined $type) {
	$error .= "the cmd line switch -type is undefined!\n";
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

$task_description .= 'perl '.$plugin_path .'/register_script.pl';
$task_description .= " -name '$name'" if (defined $name);
$task_description .= " -type '$type'" if (defined $type);


## Do whatever you want!

my $tmp; 
unless ( -f $name ){
	## OK the script does not exist - I should find the path to search for the script
	## first check if we are in a git controlled path
	&test_fatal_git_controlled_dir();

	
}



sub test_fatal_git_controlled_dir {
	my ( $path ) = @_;
	$path ||= '';
	chdir ( $path ) if ( -d $path );
	my $tmp;
	open( TEST, "git remote -v 2>/dev/null |" ) or die "Could not run git\n$!\n";
	$tmp = join("",<TEST>);
	close ( TEST );
	print $tmp."\n" if ($debug);
	unless ( $tmp =~ m/\w/ ) {
		warn "I am not in a git controlled path\nExit\n";
		exit 0;
	}
}
