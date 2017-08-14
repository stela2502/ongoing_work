# Ongoing work

Ongoing work is a tiny perl script, that initiates a project specific git repository (local) and tries to link it to a local gitlab server.

# Install

git clone git@gitlab:stefanlang/ongoing_work.git

cd ongoing_work

perl Makefile.PL

make

make install

# Usage 

Create a git repo in your git repository if you want to link to a git server.

create_project.pl -path <the path to the project> -name <the project name> -git_user <the git user> -git_server <the git server>

Make sure you update the git information by adding all scripts to the git list by

git add newScript.R

And update the Readme.md file to contain all information you think might be necessary later on.

# And last but not least commit on a regular basis!
