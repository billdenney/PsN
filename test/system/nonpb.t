#!/etc/bin/perl

# Blackbox testing of nonpb, not crash

use strict;
use warnings;
use File::Path 'rmtree';
use Test::More tests=>2;
use FindBin qw($Bin);
use lib "$Bin/.."; #location of includes.pm
use includes; #file with paths to PsN packages and $path variable definition


our $tempdir = create_test_dir('system_nonpb');
my $model_dir = $includes::testfiledir;
copy_test_files($tempdir,["pheno5.mod", "pheno5.dta","pheno5.lst"]);

chdir($tempdir);
my @a;

my $command2 = get_command('nonpb') . " pheno5.mod -lst=pheno5.lst -seed=123 -samples=5 -nonpb_v=1 -clean=2 -no-zip";
my $command1 = get_command('nonpb') . " pheno5.mod -lst=pheno5.lst -seed=123 -samples=5 -nonpb_v=2 -clean=2 -no-zip";

my  $rc = system($command1);
$rc = $rc >> 8;

ok ($rc == 0, "nonpb that should run ok");
$rc = system($command2);
$rc = $rc >> 8;

ok ($rc == 0, "nonpb that should run ok");

chdir('..');
remove_test_dir($tempdir);

done_testing();
