#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/.."; #location of includes.pm
use includes; #file with paths to PsN packages
use linear_algebra;


#subtract, max and absolute
my @A = ([1, 2, 3], [2.1, 4, 5], [3.25, 5.17, 19]);
my @B = ([1, 2.1, 3.25], [2, 4, 5.17], [3, 5, 19]);
my $C = linear_algebra::subtract(\@A, \@B);
is_deeply($C, [[ 0.  , -0.1 , -0.25], [ 0.1 ,  0.  , -0.17], [ 0.25,  0.17,  0.  ]], "matrix subtraction");
is (linear_algebra::max($C), 0.25, "matrix maximum");
linear_algebra::absolute($C);
is_deeply($C, [[ 0.  , 0.1 , 0.25], [ 0.1,  0., 0.17], [ 0.25,  0.17,  0. ]], "matrix absolute");

# read_from_file
my $testdir = create_test_dir("linear_algebra_unit");
chdir $testdir;
open my $fh, ">", "testfile";
print $fh "1 ,2, 3,4,5\n";
print $fh "2,3,1,4,  99\n";
close $fh;
my $A = linear_algebra::read_from_file(filename => "testfile");
is_deeply($A, [[1, 2, 3, 4, 5], [2, 3, 1, 4, 99]], "read_from_file comma separated");

open my $fh, ">", "testfile_space";
print $fh "1.23 2e14    5\n";
print $fh "1 2  1.56789\n";
print $fh "1   1 1";
close $fh;
open my $fh, "<", "testfile_space";
my $A = linear_algebra::read_from_file(filehandle => $fh, separator => '\s+');
is_deeply($A, [[1.23, 2e14, 5], [1, 2, 1.56789], [1, 1, 1]], "read_from_file space separated");
close $fh;

remove_test_dir($testdir);

#pad_matrix
my @A = ([1, 2, 4], [3, 5 ,7], [8, 4, 1]);
linear_algebra::pad_matrix(\@A, 5);

is(scalar(@A), 5, "pad_matrix num rows");
is_deeply(@A[0], [1, 2, 4, 0, 0], "pad_matrix row 1");
is_deeply(@A[1], [3, 5, 7, 0, 0], "pad_matrix row 2");
is_deeply(@A[2], [8, 4, 1, 0, 0], "pad_matrix row 3");
is_deeply(@A[3], [0, 0, 0, 1, 0], "pad_matrix row 4");
is_deeply(@A[4], [0, 0, 0, 0, 1], "pad_matrix row 5");

#reduce_matrix
my @A = ([1, 3, 5, 7], [8, 6, 4, 2], [1, 2, 3, 4], [6, 7, 9, 1]);

linear_algebra::reduce_matrix(\@A, 4);
is(scalar(@A), 4, "reduce_matrix don't reduce");
is_deeply(@A[0], [1, 3, 5, 7], "reduce_matrix don't reduce row 0");
is_deeply(@A[3], [6, 7, 9, 1], "reduce_matrix don't reduce row 3");

linear_algebra::reduce_matrix(\@A, 2);

is(scalar(@A), 2, "reduce_matrix num rows");
is_deeply(@A[0], [1, 3], "reduce_matrix row 0");
is_deeply(@A[1], [8, 6], "reduce_matrix row 1");

#put_ones_on_diagonal_of_zero_lines
my @A = ([1, 2, 3, 4], [0, 0, 0, 0], [9, 8, 7, 6], [0, 0, 0, 0]);
linear_algebra::put_ones_on_diagonal_of_zero_lines(\@A);

is_deeply(@A[0], [1, 2, 3, 4], "put_ones_on... row 1");
is_deeply(@A[1], [0, 1, 0, 0], "put_ones_on... row 2");
is_deeply(@A[2], [9, 8, 7, 6], "put_ones_on... row 3");
is_deeply(@A[3], [0, 0, 0, 1], "put_ones_on... row 4");

#triangular_symmetric_to_full
my @A = (1, 5, 3, 7, 8, 2);
my $res = linear_algebra::triangular_symmetric_to_full(\@A);

is_deeply($res->[0], [1, 5, 7], "triangular_symmetric_to_full row 1");
is_deeply($res->[1], [5, 3, 8], "triangular_symmetric_to_full row 2");
is_deeply($res->[2], [7, 8, 2], "triangular_symmetric_to_full row 3");

#Transpose
my @A = ([1, 2, 3], [4, 5, 6], [7, 8, 9]);
linear_algebra::transpose(\@A);

is_deeply(@A[0], [1, 4, 7], "transpose row 1");
is_deeply(@A[1], [2, 5, 8], "transpose row 2");
is_deeply(@A[2], [3, 6, 9], "transpose row 3");

# is_symmetric
my @A = ([1, 2], [2, 3]);
ok(linear_algebra::is_symmetric(\@A), "is_symmetric matrix 1");
@A = ([1, 2], [3, 2]);
ok(!linear_algebra::is_symmetric(\@A), "is_symmetric matrix 2");

#LU_factorization
my $A = [[2, 3], [1, 2]];
linear_algebra::LU_factorization($A);
is_deeply($A, [[2, 3], [0.5, 0.5]], "lu matrix A");

my @B = ([8, 4, 1], [5, 5, 2], [4, 2, 2]);
linear_algebra::LU_factorization(\@B);
is_deeply(\@B, [[8, 4, 1], [0.625, 2.5, 1.375], [0.5, 0, 1.5]], "lu matrix B");

my $C = [[8, 7, 6, 5], [4, 3, 2, 1], [4, 3, 3, 1], [4, 3, 2, 0]];
linear_algebra::LU_factorization($C);
is_deeply($C, [[8, 7, 6, 5], [0.5, -0.5, -1, -1.5], [0.5, 1, 1, 0], [0.5, 1, 0, -1]], "lu matrix C");

#eigenvalue_decomposition
my @eigenValMatrix = ( [ '8.9544282663304415E+01', '-8.2566649009388087E+01', '8.6967174304372286E-02', '-4.3909645699741713E+00', '-1.6476336788019591E+01',
        '1.3784822470949292E+01', '1.2074968416416303E+00', '1.5699623392919333E+00', '-1.3673882615395747E+00', '-5.8476185564888334E+00' ],
      [ '-8.2566649009388087E+01', '5.0538799354932610E+02', '7.8999591192394849E+00', '-1.1155228236154463E+02', '-9.2582185092361200E+01',
        '-2.2659309460626335E+02', '7.2529816314235845E+01', '5.7048131765312196E+00', '-7.7734606378735516E-01', '-9.4482044146047386E+00' ],
      [ '8.6967174304372286E-02', '7.8999591192394849E+00', '2.3183671967132167E+01', '-7.4562261429523469E+00', '-5.9125649890345251E+00',
        '-1.7946256897967089E+01', '-1.7748821194127629E+01', '-6.2240178351010755E-01', '6.1756262261847938E-01', '7.8010427134354521E-01' ],
      [ '-4.3909645699741713E+00', '-1.1155228236154463E+02', '-7.4562261429523469E+00', '5.5315535817910721E+01', '9.0156228965423949E+01',
        '-2.2150166713057892E+01', '3.1349844124200253E+01', '-2.6057687943018619E+00', '-1.3024298077126174E+01', '-1.0438244499744593E+01' ],
      [ '-1.6476336788019591E+01', '-9.2582185092361200E+01', '-5.9125649890345251E+00', '9.0156228965423949E+01', '2.6483381331460754E+02',
        '-2.4031602911954596E+02', '2.4789036253653387E+02', '2.3230899216073259E-01', '-6.4928365881499488E+01', '-9.0630421685273802E+01' ],
      [ '1.3784822470949292E+01', '-2.2659309460626335E+02', '-1.7946256897967089E+01', '-2.2150166713057892E+01', '-2.4031602911954596E+02',
        '4.9321453266930064E+02', '-3.4414470741622665E+02', '-4.3428373858779965E+00', '7.8850627454916236E+01', '1.1527757017894507E+02' ],
      [ '1.2074968416416303E+00', '7.2529816314235845E+01', '-1.7748821194127629E+01', '3.1349844124200253E+01', '2.4789036253653387E+02',
        '-3.4414470741622665E+02', '9.4215994383596786E+04', '3.8342815093138626E+01', '7.7211729326696073E+01', '1.3484651750320691E+02' ],
      [ '1.5699623392919333E+00', '5.7048131765312196E+00', '-6.2240178351010755E-01', '-2.6057687943018619E+00', '2.3230899216073259E-01',
        '-4.3428373858779965E+00', '3.8342815093138626E+01', '1.5964711542724439E+02', '-9.4095451454909025E+01', '5.5635413108142568E+00' ],
      [ '-1.3673882615395747E+00', '-7.7734606378735516E-01', '6.1756262261847938E-01', '-1.3024298077126174E+01', '-6.4928365881499488E+01',
        '7.8850627454916236E+01', '7.7211729326696073E+01', '-9.4095451454909025E+01', '4.8678696776193942E+02', '-2.9983667699545244E+01' ],
      [ '-5.8476185564888334E+00', '-9.4482044146047386E+00', '7.8010427134354521E-01', '-1.0438244499744593E+01', '-9.0630421685273802E+01',
        '1.1527757017894507E+02', '1.3484651750320691E+02', '5.5635413108142568E+00', '-2.9983667699545244E+01', '9.3718803441985904E+02' ]
    );

(my $eigen, my $vecs) = linear_algebra::eigenvalue_decomposition(\@eigenValMatrix);
cmp_float_array($eigen, 
[ '103.735518977137', '577.409123620258', '26.4391034036385', '8.31436812089702', '-0.0922465852143416',
  '735.406959776145', '94218.259066972', '132.962268669761', '421.085176924333', '1007.57699130853' ], "eigenvalues");
cmp_float_matrix($vecs, 
[ [ '0.858533360145535', '-0.0815272625678409', '-0.276778340107342', '-0.0370674630316422', '0.407929997751623', '0.0941137963799454', '1.10321458448217e-05', '0.0501809815749305', '0.0154494947282136', '0.0165051795403893' ],
          [ '-0.127128277969396', '0.593306835379972', '-0.192703954766765', '-0.0135472742932071', '0.408079183625171', '-0.585521402054757', '0.000779676970620123', '-0.0286033162157461', '-0.253754027916267', '-0.14118519949914' ],
          [ '0.0993153815302009', '0.0126487578069314', '0.905771563340727', '-0.0392429769917785', '0.409272163234004', '-0.0213427696052516', '-0.000187835774071636', '0.00175871852579824', '0.00444455468674422', '-0.00567695916958289' ],
          [ '-0.224380389103329', '-0.218375302337189', '-0.118680379435431', '0.829808874284842', '0.404066784432321', '0.0562716614554156', '0.000335132785146617', '0.00430942902793786', '0.179791297366182', '-0.0227553893526604' ],
          [ '-0.303350253536207', '-0.429591195213723', '-0.175719849038885', '-0.510973612848424', '0.410972196231212', '-0.152306935556326', '0.00264542648885041', '0.0264427130719482', '0.438011164668075', '-0.216339977529082' ],
          [ '-0.302158678647344', '0.123165409979213', '-0.144181113777307', '-0.216508321555358', '0.409135366737881', '0.608711288261839', '-0.00367808146790063', '-0.0558855034169174', '-0.385338814667859', '0.369218725407792' ],
          [ '-0.000112422607409911', '0.000885262766390327', '0.000307388401360586', '0.000309941246724041', '3.52252977801686e-05', '0.00341750857813817', '0.999987907415609', '-0.000890103224710209', '-0.00319067371725204', '0.000738142340499522' ],
          [ '-0.0553746022836126', '-0.130311263073596', '0.00558743004885902', '0.0028712626758958', '0.000552813122758316', '-0.0636376528689959', '0.000407125813673901', '0.957933772312949', '-0.241299741404108', '-0.00051483816067176' ],
          [ '-0.00695086615822947', '0.607570109038514', '-0.00506909671999226', '-0.0115381932216566', '0.000749655862838344', '0.303716331646694', '0.00081789479396663', '0.273792978746659', '0.679992431984221', '0.0324696567072524' ],
          [ '0.0106230539607319', '-0.0874698874648048', '-0.005395398500717', '-0.0144339534684047', '0.000252445100494845', '-0.393259954682628', '0.00143810308725646', '0.0148036793073181', '0.205086094443641', '0.891663468631833' ]
        ], "eigenvecs");


my $A = [[9,8,7], [8, 5, 3], [7, 3, 7]];
(my $eigen, my $vecs) = linear_algebra::eigenvalue_decomposition($A);
cmp_float_array($eigen, [ 19.609194939332617,  -1.903857409809233,   3.294662470476631 ], "eigen simple matrix");
cmp_float_matrix($vecs, [[ 0.706547465982442, -0.684965411383339, -0.177800628576624],
       [ 0.491463745176441,  0.655722706583517, -0.573141447853785],
       [ 0.509169977012525,  0.317569074815606,  0.79993488311851 ]], "eigenvectors simple matrix");

my $A = [[1, 2], [2, 3]];
(my $eigen, my $vecs) = linear_algebra::eigenvalue_decomposition($A);
cmp_float_array($eigen, [-0.23606797749979,  4.23606797749979], "eigen 2x2 matrix");
cmp_float_matrix($vecs, [[0.85065080835204 , 0.525731112119133], [ -0.525731112119133, 0.85065080835204 ]], "eigenvecs 2x2 matrix");

#invert_symmetric
my @matrix = ([3,1,0], [1,5,2], [0,2,4]);
my $result = [];
my $err = linear_algebra::invert_symmetric(\@matrix,$result);

is ($err,0,'invert_symmetric success');
cmp_float($result->[0]->[0], 0.363636363636364, 'invert_symmetric (1,1)');
cmp_float($result->[0]->[1], -0.090909090909091, 'invert_symmetric (1,2)');
cmp_float($result->[0]->[2], 0.045454545454545, 'invert_symmetric (1,3)');
cmp_float($result->[1]->[0], -0.090909090909091, 'invert_symmetric (2,1)');
cmp_float($result->[1]->[1], 0.272727272727273, 'invert_symmetric (2,2)');
cmp_float($result->[1]->[2], -0.136363636363636, 'invert_symmetric (2,3)');
cmp_float($result->[2]->[0], 0.045454545454545, 'invert_symmetric (3,1)');
cmp_float($result->[2]->[1], -0.136363636363636, 'invert_symmetric (3,2)');
cmp_float($result->[2]->[2], 0.318181818181818, 'invert_symmetric (3,3)');

my @matrix = ([3,1,0], [1,5,0], [0,0,0]);
my $result = [];
my $err = linear_algebra::invert_symmetric(\@matrix,$result);

is ($err,1,'invert_symmetric numerr');

#get_identity_matrix
my $identity = linear_algebra::get_identity_matrix(2);
is_deeply($identity, [ [ 1, 0 ], [ 0, 1 ] ], "identity matrix");

my $matrix = [ [1,2,3,4],[2,2,3,4],[3,3,3,4],[4,4,4,4] ]; 

is_deeply(linear_algebra::copy_and_reorder_square_matrix($matrix,[1,3,0,2]),[ [2,4,2,3],[4,4,4,4],[2,4,1,3],[3,4,3,3] ] , "copy and reorder");

my $omega = [[1,0.2,0.1,0.1],
			 [0.2,5,0.05,0.2],
			 [0.1,0.05,3,0.3],
			 [0.1,0.2,0.3,4] ];

my ($strings,$inits,$code,$warnings)=linear_algebra::string_cholesky_block(value_matrix=>$omega,record_index=>0,theta_count=>1,testing=>1,fix=>0);
#print "\n";

#for (my $i=0; $i<scalar(@{$params}); $i++){
#	print 'my '.$params->[$i]." ".$inits->[$i]."\n";
#}

my ($SD_A1,$SD_A2,$SD_A3,$SD_A4,$SD_A5);
my ($COR_A21,$COR_A31,$COR_A41,$COR_A51,$COR_A32,$COR_A42,$COR_A52);
my ($COR_A43,$COR_A53,$COR_A54);
my ($CH_A22,$CH_A32,$CH_A42,$CH_A52,$CH_A33,$CH_A43,$CH_A53,$CH_A44,$CH_A54,$CH_A55);



eval(join(' ',@{$inits}));
#print (join("\n",@{$code}))."\n";
#exit;
eval(join(' ',@{$code}));

my @matrix=();
for(my $i=0;$i<scalar(@{$strings});$i++){
	push(@matrix,[ (0) x scalar(@{$strings})]);
}
for(my $i=0;$i<scalar(@{$strings});$i++){
	for (my $j=0; $j<=$i; $j++){
		my $value = eval($strings->[$j]->[$i]);
		$matrix[$i]->[$j]=$value;
	}
#	print join(' ',@{$matrix[$i]})."\n";
}

for(my $i=0;$i<scalar(@{$strings});$i++){
	for (my $j=0; $j<=$i; $j++){
		my $sum=0;
		for (my $k=0;$k<scalar(@{$strings});$k++){
			$sum = $sum+$matrix[$i]->[$k]*$matrix[$j]->[$k];
		}
		cmp_float($sum,$omega->[$i]->[$j],"cholesky product element $i,$j is ".$omega->[$i]->[$j]);
	}
#	print join(' ',@{$matrix[$i]})."\n";
}
#extend to 6x
my $omega6 = [
	[1,0.2,0.1,0.1,0.2,-0.2],
	[0.2,5,0.05,0.2,-0.3,0.2],
	[0.1,0.05,3,0.3,0.2,-0.1],
	[0.1,0.2,0.3,4,0.1,0.3],
	[0.2,-0.3,0.2,0.1,4,0.4],
	[-0.2,0.2,-0.1,0.3,0.4,2] 
];

my ($strings,$inits,$code,$warnings)=linear_algebra::string_cholesky_block(
	value_matrix=>$omega6,
	record_index=>2,
	theta_count=>1,
	testing=>0,
	fix=>0);

if (0){
	print join("\n",@{$code})."\n\n";
	print join("\n",@{$inits})."\n";
	for(my $i=0;$i<scalar(@{$strings});$i++){
		for (my $j=0; $j<=$i; $j++){
			print $strings->[$i]->[$j]."\t";
		}
		print "\n";
	}
}
my ($count,$code,$etalist)=linear_algebra::eta_cholesky_code(
	stringmatrix=> $strings,
	eta_count=> 5,
	diagonal => 0);

is_deeply($etalist,[6,7,8,9,10,11],'eta_cholesky_code etalist 1');
is($count,6,'eta_cholesky_code count');
my @anscode =(
'ETA_6=ETA(6)*SD_C1',
'ETA_7=ETA(6)*COR_C21*SD_C2+ETA(7)*CH_C22*SD_C2',
'ETA_8=ETA(6)*COR_C31*SD_C3+ETA(7)*CH_C32*SD_C3+ETA(8)*CH_C33*SD_C3',
'ETA_9=ETA(6)*COR_C41*SD_C4+ETA(7)*CH_C42*SD_C4+ETA(8)*CH_C43*SD_C4+ETA(9)*CH_C44*SD_C4',
'ETA_10=ETA(6)*COR_C51*SD_C5+ETA(7)*CH_C52*SD_C5+ETA(8)*CH_C53*SD_C5+ETA(9)*CH_C54*SD_C5+ETA(10)*CH_C55*SD_C5',
'ETA_11=ETA(6)*COR_C61*SD_C6+ETA(7)*CH_C62*SD_C6+ETA(8)*CH_C63*SD_C6+ETA(9)*CH_C64*SD_C6+ETA(10)*CH_C65*SD_C6+ETA(11)*CH_C66*SD_C6'
	);
is_deeply($code,\@anscode,'eta_cholesky code block');


my ($SD_C1,$SD_C2,$SD_C3,$SD_C4,$SD_C5,$SD_C6);
my ($COR_C21,$COR_C31,$COR_C41,$COR_C51,$COR_C61,$COR_C32,$COR_C42,$COR_C52,$COR_C62);
my ($COR_C43,$COR_C53,$COR_C63,$COR_C54,$COR_C64,$COR_C65);
my ($CH_C22,$CH_C32,$CH_C42,$CH_C52,$CH_C62,$CH_C33,$CH_C43,$CH_C53,$CH_C63,$CH_C44,$CH_C54,$CH_C64,$CH_C55,$CH_C65,$CH_C66);

my ($strings,$inits,$code,$warnings)=linear_algebra::string_cholesky_block(
	value_matrix=>$omega6,
	record_index=>2,
	theta_count=>1,
	testing=>1,
	fix=>0);
eval(join(' ',@{$inits}));
eval(join(' ',@{$code}));

my @matrix=();
for(my $i=0;$i<scalar(@{$strings});$i++){
	push(@matrix,[ (0) x scalar(@{$strings})]);
}
for(my $i=0;$i<scalar(@{$strings});$i++){
	for (my $j=0; $j<=$i; $j++){
		my $value = eval($strings->[$j]->[$i]);
		$matrix[$i]->[$j]=$value;
	}
}

for(my $i=0;$i<scalar(@{$strings});$i++){
	for (my $j=0; $j<=$i; $j++){
		my $sum=0;
		for (my $k=0;$k<scalar(@{$strings});$k++){
			$sum = $sum+$matrix[$i]->[$k]*$matrix[$j]->[$k];
		}
		cmp_float($sum,$omega6->[$i]->[$j],"cholesky product element $i,$j is ".$omega6->[$i]->[$j]);
	}
#	print join(' ',@{$matrix[$i]})."\n";
}



my ($count,$code,$etalist)=linear_algebra::eta_cholesky_code(
	stringmatrix=> ['SD_C1','SD_C2','SD_C3'],
	eta_count=> 5,
	diagonal => 1);

is($count,3,'eta_cholesky code count');
is($code->[0],'ETA_6=ETA(6)*SD_C1','eta_cholesky code diagonal 1');
is($code->[1],'ETA_7=ETA(7)*SD_C2','eta_cholesky code diagonal 2');
is($code->[2],'ETA_8=ETA(8)*SD_C3','eta_cholesky code diagonal 3');
is_deeply($etalist,[6,7,8],'eta_cholesky_code etalist 2');

($count,$code,$etalist)=linear_algebra::eta_cholesky_code(
	stringmatrix=> [undef,undef,'SD_C3'],
	eta_count=> 5,
	diagonal => 1);

is($count,3,'eta_cholesky code count 2');
is($code->[0],'ETA_8=ETA(8)*SD_C3','eta_cholesky code 2 diagonal 3');
is($etalist->[0],8,'eta_cholesky code etalist');

$code = ['CL=THETA(2)*EXP(ETA(2))','V=THETA(3)*(1+ETA(3))*(1+ETA(5))'];
linear_algebra::substitute_etas(code => $code,eta_list => [2,3,5]);
is($code->[0],'CL=THETA(2)*EXP(ETA_2)','substitute etas 1');
is($code->[1],'V=THETA(3)*(1+ETA_3)*(1+ETA_5)','substitute etas 2');
linear_algebra::substitute_etas(code => $code,eta_list => [2,3,5], inverse => 1);
is($code->[0],'CL=THETA(2)*EXP(ETA(2))','inverse substitute etas 1');
is($code->[1],'V=THETA(3)*(1+ETA(3))*(1+ETA(5))','inverse substitute etas 2');

$code = ['CL=THETA(2)*EXP(ETA(2))','V=THETA(3)*(1+ETA(3))*(1+ETA(5))'];
linear_algebra::substitute_etas(code => $code,eta_list => [1,3]);
is($code->[0],'CL=THETA(2)*EXP(ETA(2))','substitute etas 3');
is($code->[1],'V=THETA(3)*(1+ETA_3)*(1+ETA(5))','substitute etas 4');
linear_algebra::substitute_etas(code => $code,eta_list => [1,3], inverse => 1);
is($code->[0],'CL=THETA(2)*EXP(ETA(2))','inverse substitute etas 3');
is($code->[1],'V=THETA(3)*(1+ETA(3))*(1+ETA(5))','inverse substitute etas 4');

$code = ['CL=THETA(2)*EXP(EPS(2))','V=THETA(3)*(1+EPS(3))*(1+EPS(5))'];
linear_algebra::substitute_etas(code => $code,eta_list => [1,2,3], sigma => 1);
is($code->[0],'CL=THETA(2)*EXP(EPS_2)','substitute etas 5');
is($code->[1],'V=THETA(3)*(1+EPS_3)*(1+EPS(5))','substitute etas 6');
linear_algebra::substitute_etas(code => $code,eta_list => [1,2,3], sigma => 1, inverse => 1);
is($code->[0],'CL=THETA(2)*EXP(EPS(2))','inverse substitute etas 5');
is($code->[1],'V=THETA(3)*(1+EPS(3))*(1+EPS(5))','inverse substitute etas 6');

my $hashref = linear_algebra::get_inverse_parameter_list(code => [
													   'SD_A1=THETA(3)',
													   'SD_A2=THETA(4)',
													   'COR_A21=THETA(5)',
													   'SD_A3=THETA(6)',
													   'COR_A31=THETA(7)',
													   'COR_A32=THETA(8)',
													   ';Comments below show CH variables for 1st column, too simple to need new variables',
													   ';CH_A11=1',
													   ';CH_A21=COR_A21',
													   ';CH_A31=COR_A31',
													   'CH_A22=SQRT(1-(COR_A21**2))',
													   'CH_A32=(COR_A32-COR_A21*COR_A31)/CH_A22',
													   'CH_A33=SQRT(1-(COR_A31**2+CH_A32**2))',
													   'ETA_1=ETA(1)*SD_A1',
													   'ETA_2=ETA(1)*COR_A21*SD_A2+ETA(2)*CH_A22*SD_A2',
													   'ETA_3=ETA(1)*COR_A31*SD_A3+ETA(2)*CH_A32*SD_A3+ETA(3)*CH_A33*SD_A3']);

is_deeply($hashref->{'ETA'},[1,2,3],"get inverse parameter list ETA");
is_deeply($hashref->{'EPS'},[],"get inverse parameter list EPS");
is_deeply($hashref->{'THETA'},[3,4,5,6,7,8],"get inverse parameter list THETA");
is_deeply($hashref->{'RECORD'},[0],"get inverse parameter list RECORD");


my ($strings,$inits,$code)=linear_algebra::string_cholesky_diagonal(
	value_matrix=>[4,9,16],
	record_index=>3,
	theta_count=>0,
	testing=>0,
	fix_vector=>[1,0,1]);
is($strings->[0],undef,'string cholesky diag 1');
is($strings->[1],'SD_D2','string cholesky diag 2');
is($strings->[2],undef,'string cholesky diag 3');

is($inits->[0],'(0,3) ; SD_D2','string cholesky init diag 2');


is($code->[0],'SD_D2=THETA(1)','string cholesky code diag 2');


done_testing();
