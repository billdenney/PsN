#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin qw($Bin);
use lib "$Bin/../.."; #location of includes.pm
use includes; #file with paths to PsN packages

use tool::frem;
use model;

our $tempdir = create_test_dir('unit_frem');
chdir($tempdir);
my $modeldir = $includes::testfiledir;
my $model = model->new(filename => "$modeldir/mox_no_bov.mod", 
					   ignore_missing_data => 1);

my $bov_parameters = ['PHI','LAG','CL','V','KA'];
my ($ctv_parameters,$etanum_to_parameterhash) =  tool::frem::get_CTV_parameters(model=> $model,
																				bov_parameters => $bov_parameters);
is_deeply($ctv_parameters,['CL','KA','LAG','PHI','V'],"get_CTV_parameters ctvparams"); 
is(scalar(keys(%{$etanum_to_parameterhash})),3,"get_CTV_parameters length hash keys");
is($etanum_to_parameterhash->{1},'CL',"get_CTV_parameters etanum_to_parameterhash 1");
is($etanum_to_parameterhash->{2},'V',"get_CTV_parameters etanum_to_parameterhash 2");
is($etanum_to_parameterhash->{3},'KA',"get_CTV_parameters etanum_to_parameterhash 3");

my $bov_parameters = ['PHI','KA'];
my ($ctv_parameters,$etanum_to_parameterhash) =  tool::frem::get_CTV_parameters(model=> $model,
																				bov_parameters => $bov_parameters);
is_deeply($ctv_parameters,['CL','KA','PHI','V'],"get_CTV_parameters ctvparams"); 
is(scalar(keys(%{$etanum_to_parameterhash})),3,"get_CTV_parameters length hash keys");
is($etanum_to_parameterhash->{1},'CL',"get_CTV_parameters etanum_to_parameterhash 1");
is($etanum_to_parameterhash->{2},'V',"get_CTV_parameters etanum_to_parameterhash 2");
is($etanum_to_parameterhash->{3},'KA',"get_CTV_parameters etanum_to_parameterhash 3");

my $time_varying = ['CLCR','WT'];
my $invariant = ['AGE','SEX'];

my($start_eta,$total_orig_etas,$bsv_parameters,$start_omega_record)=
	tool::frem::get_start_numbers(model=>$model,
					  n_invariant => 0, 
					  start_eta => undef);
is($start_eta,4,"get_start_numbers start_eta");
is($total_orig_etas,3,"get_start_numbers total_orig_etas");
is($bsv_parameters,0,"get_start_numbers bsv_parameters");
is($start_omega_record,3,"get_start_numbers start_omega_record");

($start_eta,$total_orig_etas,$bsv_parameters,$start_omega_record)=
	tool::frem::get_start_numbers(model=>$model,
								  n_invariant => scalar(@{$invariant}), 
								  start_eta => undef);
is($start_eta,1,"get_start_numbers start_eta");
is($total_orig_etas,3,"get_start_numbers total_orig_etas");
is($bsv_parameters,3,"get_start_numbers bsv_parameters");
is($start_omega_record,1,"get_start_numbers start_omega_record");

my $labelshash = tool::frem::create_labels(invariant => $invariant,
										   bov_parameters => $bov_parameters,
										   time_varying => $time_varying,
										   etanum_to_parameter => $etanum_to_parameterhash,
										   occasionlist => [3,8],
										   occasion => 'VISI',
										   start_eta => $start_eta,
										   bsv_parameters => $bsv_parameters);

is_deeply($labelshash->{'occasion_labels'},['VISI=3','VISI=8'],"create labels occasion");
is_deeply($labelshash->{'bov_par_labels'},['BOV par PHI','BOV par KA'],"create labels bov par");
is_deeply($labelshash->{'bov_cov_labels'},['BOV cov CLCR','BOV cov WT'],"create labels bov cov");
is_deeply($labelshash->{'bsv_par_labels'},['BSV par CL','BSV par V','BSV par KA'],"create labels bsv par");
is_deeply($labelshash->{'bsv_cov_labels'},['BSV cov AGE','BSV cov SEX'],"create labels bsv cov");

($start_eta,$total_orig_etas,$bsv_parameters,$start_omega_record)=
	tool::frem::get_start_numbers(model=>$model,
					  n_invariant => scalar(@{$invariant}), 
					  start_eta => 3);
is($start_eta,3,"get_start_numbers start_eta");
is($total_orig_etas,3,"get_start_numbers total_orig_etas");
is($bsv_parameters,1,"get_start_numbers bsv_parameters");
is($start_omega_record,2,"get_start_numbers start_omega_record");
#what is bsv_parameters????
$labelshash = tool::frem::create_labels(invariant => $invariant,
										   bov_parameters => $bov_parameters,
										   time_varying => $time_varying,
										   etanum_to_parameter => $etanum_to_parameterhash,
										   occasionlist => [3,8],
										   occasion => 'VISI',
										   start_eta => $start_eta,
										   bsv_parameters => $bsv_parameters);

is_deeply($labelshash->{'occasion_labels'},['VISI=3','VISI=8'],"create labels occasion");
is_deeply($labelshash->{'bov_par_labels'},['BOV par PHI','BOV par KA'],"create labels bov par");
is_deeply($labelshash->{'bov_cov_labels'},['BOV cov CLCR','BOV cov WT'],"create labels bov cov");
is_deeply($labelshash->{'bsv_par_labels'},['BSV par KA'],"create labels bsv par");
is_deeply($labelshash->{'bsv_cov_labels'},['BSV cov AGE','BSV cov SEX'],"create labels bsv cov");



my $full = tool::frem::create_full_block(top_block => [[3,1],[1,4]],
										 bottom_block => [[2,0.4,0.2],[0.4,4,0.1],[0.2,0.1,5]],
										 correlation => 0.01);
is_deeply($full->[0],[3,1,sqrt(3)*sqrt(2)*0.01,sqrt(3)*sqrt(4)*0.01 ,sqrt(3)*sqrt(5)*0.01],"create full_block 0");
is_deeply($full->[1],[1,4,sqrt(4)*sqrt(2)*0.01,sqrt(4)*sqrt(4)*0.01 ,sqrt(4)*sqrt(5)*0.01],"create full_block 1");
is_deeply($full->[2],[sqrt(3)*sqrt(2)*0.01,sqrt(4)*sqrt(2)*0.01 ,2,0.4,0.2],"create full_block 2");
is_deeply($full->[3],[sqrt(3)*sqrt(4)*0.01,sqrt(4)*sqrt(4)*0.01 ,0.4,4,0.1],"create full_block 3");
is_deeply($full->[4],[sqrt(3)*sqrt(5)*0.01,sqrt(4)*sqrt(5)*0.01 ,0.2,0.1,5],"create full_block 4");

my ($filtered_data_model,$indices,$first_timevar_type,$extra_input_items,$message) = 
	tool::frem::create_data2_model( model => $model,
									filename => 'filterdata.mod',
									filtered_datafile => 'filtertype0.dta',
									bov_parameters => scalar(@{$bov_parameters}), 
									dv  => 'DV',
									time_varying  => $time_varying,
									invariant  => $invariant,
									occasion  => 'VISI');

my $formatted = $filtered_data_model->problems->[0]->tables->[0]->_format_record;
my @ans = qw (ID VISI XAT2 DGRP DOSE FLAG ONO XIME DVO NEUY SCR AGE SEX NYHA WT COMP ACE DIG DIU NUMB TAD TIME VIDD CLCR AMT SS II VID CMT CONO DV EVID OVID FREMTYPE NOAPPEND);
for (my $i=0; $i<scalar(@ans); $i++){
	is($filtered_data_model->problems->[0]->tables->[0]->options->[$i]->name, $ans[$i], 'table record options '.$i);
}
is($first_timevar_type,scalar(@{$invariant})+1,'first timevar type create_data2');
is_deeply($extra_input_items,['FREMTYPE'],'extra_input_items create_data2');
is($message,"Running dummy model to filter data and add FREMTYPE for Data set 2",'create_data2 message');

is($indices->{'occ_index'},1,'occ index');
is($indices->{'evid_index'},31,'evid index');
is($indices->{'mdv_index'},undef,'mdv index');
is($indices->{'type_index'},33,'type index');
is_deeply($indices->{'cov_indices'},[30,11,12,23,14],'cov indices');


$model = model->new(filename => "$modeldir/pheno.mod", 
					ignore_missing_data => 1);
my @code = ('TVCL=THETA(1)','TVV=THETA(2)','CL=TVCL*EXP(ETA(1))','V=TVV*EXP(ETA(2))','S1=V');
$model->set_code(record => 'pk', code => \@code);

tool::frem::replace_tvpar_with_ctvpar( model => $model, 
									   ctvpar => ['V']);

@code = @{$model->get_code(record => 'pk')};
is_deeply(\@code,['TVCL=THETA(1)','TVV=CTVV','CL=TVCL*EXP(ETA(1))','V=TVV*EXP(ETA(2))','S1=V'],"replace tvpar with ctvpar");

#set_frem_records FIXME
#more dataset handling FIXME
#set_frem_code FIXME

done_testing();
exit;



done_testing();