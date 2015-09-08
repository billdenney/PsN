#!/etc/bin/perl

use strict;
use warnings;
use File::Path 'rmtree';
use Test::More;
use File::Copy 'cp';
use FindBin qw($Bin);
use lib "$Bin/.."; #location of includes.pm
use includes; #file with paths to PsN packages and $path variable definition

our $tempdir = create_test_dir('system_benchmark');
chdir($tempdir);
my $model_dir = $includes::testfiledir;

my @commands = (
#	get_command('benchmark') . " $model_dir/pheno_cond.mod $model_dir/pheno.mod -merge -record_opt=est:METH=ZERO,METH=COND,,est:none,MAXEVAL=10 -alt_nonmem=740 -replicates=2 ",
#	get_command('benchmark') . " $model_dir/mox1.mod $model_dir/pheno.mod -record_opt=est:METH=ZERO,METH=COND,,est:none,MAXEVAL=10 -replicates=2 -rplots=0 -nm_ver=730 -alt_nonme=740",
	get_command('benchmark') . " $model_dir/pheno.mod -theta_init=CL:none,0.05,,V:none,1.5 -replicates=2 -rplots=0 ",
	 );

foreach my $command (@commands) {
	print "Running $command\n";
	my $rc = system($command);
	$rc = $rc >> 8;
	ok ($rc == 0, "$command, should run ok");
#	rmtree([$dir]);
}

#remove_test_dir($tempdir);

done_testing();