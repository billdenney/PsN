#!/usr/bin/perl

# Argument: version-tag to release

if (scalar(@ARGV) != 1) {
    die "Must specify version tag name\n";
}

my $tag = $ARGV[0];

my $access_token = readpipe("zenity --entry --text \"Enter your github access token\" 2> /dev/null");

my $cmd = <<"EOF";
curl --data '{"tag_name": "$tag","target_commitish": "master","name": "PsN $tag internal release","body": "internal release","draft": false,"prerelease": true}' https://api.github.com/repos/UUPharmacometrics/PsN/releases?access_token=$access_token
EOF

my $response = readpipe($cmd);

$response =~ /\s\s\"id\":\s(\d+)/m;
my $id = $1; 

print $response;

print "Q: $id\n";

# Continue at http://help.appveyor.com/discussions/kb/2-guide-how-to-release-automatically-your-artifact-to-github
