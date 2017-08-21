#! /usr/bin/perl -w

=head1 LICENCE

  Copyright (C) 2017-08-14 Stefan Lang

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

    create_project.pl
       -name       :the project name (should be unique)
       -path       :the main path to the project
       -git_user   :your git user name
       -git_server :the git server name

       -help           :print this help
       -debug          :verbose output
   
=head1 DESCRIPTION

  Create and initialize an analyis project.

  To get further help use 'creatre_project.pl -help' at the comman line.

=cut

use Getopt::Long;
use Pod::Usage;
use Date::Simple;

use strict;
use warnings;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my ( $help, $debug, $database, $name, $path, $tmp, $git_user, $git_server );

Getopt::Long::GetOptions(
	"-name=s"     => \$name,
	"-path=s"     => \$path,
	"-git_user"   => \$git_user,
	"-git_server" => \$git_server,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $name ) {
	$error .= "the cmd line switch -name is undefined!\n";
}
unless ( defined $path ) {
	$error .= "the cmd line switch -path is undefined!\n";
}

$git_user   = "stefanlang" unless ($git_user);
$git_server = "gitlab"     unless ($git_server);

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

$task_description .= 'perl ' . $plugin_path . '/creatre_project.pl';
$task_description .= " -name '$name'" if ( defined $name );
$task_description .= " -path '$path'" if ( defined $path );
$task_description .= " -git_user '$git_user'" if ( defined $git_user );
$task_description .= " -git_server '$git_server'" if ( defined $git_server );

# check and create the path if not exisiting

unless ( -d $path ) {
	system("mkdir -p '$path'");
}

foreach (qw(scripts data outpath)) {
	system("mkdir -p '$path/$_'") unless ( -d "$path/$_" );
}

my $today = Date::Simple->new();

if ( -f "$path/README.md" ) {
	Carp::confess(
"Sorry, but you already used the project name '$name' before - choose a different one."
	);
}

open( OUT, ">$path/README.md" )
  or die
  "I could not create the documentation file '$path/scripts/$name.md'\n$!\n";
print OUT
  "## Main documentation for analysis project $name created on $today.\n\n";
print OUT "main folder '$path'.\n";

close(OUT);

open( Rscript, ">$path/scripts/$name.R" ) or die $!;

print Rscript "opath = '$path/outpath'\n";

close(Rscript);

unless ( -f "$path/.gitignore" ) {
	open( OUT, ">$path/.gitignore" )
	  or die "I could not create the .gitignore file\n$!\n";
	print OUT
	  join( "\n", "*.sam", '*.bam', '*.gz', '*.xls', '*.RData', '*.zip' );
	print OUT "##exclude wiki files from main project\n$name.wiki\n$name.wiki/*\n";
	close(OUT);
}

unless ( -d "$path/.git" ) {
	system("git init $path");
	chdir($path);
	system("git add .");
	system("git commit -m 'Project initiation'");

	warn
"I hope you have created the $git_server repository '$name' before I try the following steps:";
	$tmp = "git remote add origin git\@$git_server:$git_user/$name.git";
	warn $tmp . "\n";
	system($tmp );
	$tmp = "git push -u origin master";
	warn $tmp . "\n";
	system($tmp ) unless ($debug);
	$tmp = "git clone git\@$git_server:$git_user/$name.wiki.git";
	warn $tmp . "\n";
	
	system($tmp ) unless ($debug);
	if ( $debug) {
		warn "The gitlab wiki integration does not work in debug mode\n";
	}
	#create the main wiki page
	open( WIKI, ">$name.wiki/home.md" )
	  or die "I could not create the wiki home file\n$!\n";
	print WIKI
	  "# The main documentation site for the bioinformatics project $name\n\n"
	  . "This wiki is meant to document the scripts and analysis pipelines developed during the analyis of the data. "
	  . "It is not the place to document the biomedical experiment from a lab point of view. "
	  . "Nevertheless the broad experimental aim and setup should be doumented here, too.\n\n"
	  . "[Aim/Hypothesis](aim)\n\n"
	  . "# Scripts\n\n"
	  . "Add one link for every analysis script you use:\n\n"
	  . "[$name.git](scripts/$name)\n\n";
	close(WIKI);

	open( WIKI, ">$name.wiki/aim.md" )
	  or die "I could not create the wiki home file\n$!\n";
	## fill in aim
	print WIKI "# Setup\n\n\n# Aim \n\n\n";
	close(WIKI);

	mkdir("$name.wiki/scripts") unless ( -d "$name.wiki/scripts" );
	open( WIKI, ">$name.wiki/scripts/$name.md" )
	  or die "I could not create the wiki home file\n$!\n";
	## fill in script description start
	print WIKI "#The main analysis script for project $name\n\n";
	close(WIKI);

	chdir("$name.wiki");
	system('git add .');
	system('git commit -a -m "Initial commit"');
	system('git push') unless ($debug);

}

warn
"Please do not use the git to store any data (raw or analyzed) or any results (figures, tables, ...)\n"
  . "This information should be either backed up else where or re-creatable using the stored scripts.";

