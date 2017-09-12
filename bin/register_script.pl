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
       -name       :the script file you want to document in the git WIKI

       -help       :print this help
       -debug      :verbose output
   
=head1 DESCRIPTION

  registers a new script and adds the links into the wiki.

  To get further help use 'register_script.pl -help' at the comman line.

=cut

use Getopt::Long;
use Pod::Usage;
use Cwd;
use stefans_libs::root;

use strict;
use warnings;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my ( $help, $debug, $database, $name, $type );

Getopt::Long::GetOptions(
	"-name=s" => \$name,
#	"-type=s" => \$type,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $name ) {
	$error .= "the cmd line switch -name is undefined!\n";
}
#unless ( defined $type ) {
#	$error .= "the cmd line switch -type is undefined!\n";
#}

if ($help) {
	print helpString();
	exit;
}

if ( $error =~ m/\w/ ) {
	helpString($error);
	exit;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	print "$errorMessage.\n";
	pod2usage( q(-verbose) => 1 );
}

my ($task_description);

$task_description .= 'perl ' . $plugin_path . '/register_script.pl';
$task_description .= " -name '$name'" if ( defined $name );
#$task_description .= " -type '$type'" if ( defined $type );

## Do whatever you want!

my ($tmp);
unless ( -f $name ) {
	## OK the script does not exist - I should die here
	die "Sorry, but the script file '$name' could not be found\n$!";
}

## so now I need to find the git root path and the wiki path from here

my $fm = root->filemap($name);
my ( $wd, $git_root ) = &test_fatal_git_controlled_dir( $fm->{'path'} );

print "I got the wd '$wd' and the git root '$git_root'\n" if ( $debug );
## now if I created a git repo using the create_project.pl script I should have a $git_root/<name>.wiki/ folder.
my $wiki_path = &get_wiki_path($git_root);

print "I got the wiki_path '$wiki_path'\n" if ( $debug);
print
"I will now create an entry into the correct WIKI files and commit them to git.\n";

if ( -f "$git_root/$wiki_path/home.md" ) {
	open( HOME, ">>$git_root/$wiki_path/home.md" );
}
else {
	die "The home.md wiki entry is missing!\n";
}
print HOME "
[$fm->{filename_core}](scripts/$fm->{filename_core})
";
close(HOME);

## create a standard wiki entry from the help message of the executable script (if it is executable or a perl script)
## I assume it would be executable if I would register it like that.
my $script_docf = "$git_root/$wiki_path/scripts/$fm->{filename_core}.md";
unless ( -f $script_docf ) {
	open( SCR, ">$script_docf" ) or die $!;

	if ( $fm->{filename_ext} eq "pl" ) {
		my $use = 0;
		open( IN, "perl $name |" ) or die $!;
		while (<IN>) {
			print SCR $_ if ($use);
			if ( $_ =~ m/^Usage:/ ) {
				$use = 1;
				print SCR "# Usage:\n\n```\n";
			}
		}
		if ($use) {
			print SCR "```\n\n";
		}
		close ( IN );
	}
	print SCR "# Description\n\nPlease describe the usability of the script here in more detail!\n";
	close ( SCR);
}

sub get_wiki_path {
	my ($path) = @_;
	$path ||= getcwd();
	print "I open the path '$path'\n";
	opendir( my $DIR, $path );
	my @wiki_dir = grep /wiki$/, readdir($DIR);
	closedir($DIR);
	chomp($wiki_dir[0]);
	return $wiki_dir[0];

}

sub test_fatal_git_controlled_dir {
	my ($path) = @_;
	$path ||= '';
	chdir($path) if ( -d $path );
	my $tmp;
	open( TEST, "git rev-parse --show-toplevel 2>/dev/null |" )
	  or die "Could not run git\n$!\n";
	$tmp = join( "", <TEST> );
	close(TEST);

	unless ( $tmp =~ m/\w/ ) {
		warn "I am not in a git controlled path\nExit\n";
		exit 0;
	}
	chomp($tmp);
	return getcwd(), $tmp;
}

