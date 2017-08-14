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
       -git_path   :the git path to create the links to the gittable files


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
	 "-name=s"    => \$name,
	 "-path=s"    => \$path,
	 "-git_user" => \$git_user,
	 "-git_server" => \$git_server,
	 
	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $name) {
	$error .= "the cmd line switch -name is undefined!\n";
}
unless ( defined $path) {
	$error .= "the cmd line switch -path is undefined!\n";
}

$git_user = "stefanlang" unless ( $git_user);
$git_server = "gitlab" unless ( $git_server );

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

$task_description .= 'perl '.$plugin_path .'/creatre_project.pl';
$task_description .= " -name '$name'" if (defined $name);
$task_description .= " -path '$path'" if (defined $path);
$task_description .= " -git_user '$git_user'" if (defined $git_user);
$task_description .= " -git_server '$git_server'" if (defined $git_server);

# check and create the path if not exisiting

unless ( -d $path ) {
	system("mkdir -p '$path'" );
}

foreach ( qw(scripts data outpath) ) {
	system("mkdir -p '$path/$_'" ) unless ( -d "$path/$_");
}

my $today = Date::Simple->new();

if ( -f "$path/README.md" ){
	Carp::confess( "Sorry, but you already used the project name '$name' before - choose a different one." );
}

open ( OUT, ">$path/scripts/$name.md") or die "I could not create the documentation file '$path/scripts/$name.md'\n$!\n";
print OUT "#Main documentation for analysis project $name created on $today.\n";
print OUT "main folder '$path'.\n";

close ( OUT );

open ( Rscript , ">$path/scripts/$name.R" ) or die $!;

print Rscript "opath = '$path/outpath'\n";

close ( Rscript );

unless ( -d "$path/.git" ) {
	system( "git init $path");
	chdir( $path );
	system( "git add ." );
	system( "git commit -M 'Project initiation'" );
	
	warn "I hope you have created the $git_server repository '$name' before I try the following steps:";
	$tmp = "git remote add origin git\@$git_server:$git_user/$name.git";
	warn $tmp."\n";
	system( $tmp );
	$tmp = "git push -u origin master";
	warn $tmp."\n";
	system( $tmp );
}

warn  "Please do not use the git to store any data (raw or analyzed) or any results (figures, tables, ...)\n".
"This information should be either backed up else where or re-creatable using the stored scripts." ;

