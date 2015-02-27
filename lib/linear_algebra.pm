package linear_algebra;

use MooseX::Params::Validate;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use strict;
use array qw(:all);
use Math::Trig;
use math;

sub subtract
{
    #Return difference between two matrices in new matrix
    my $A = shift;
    my $B = shift;

    my $C;
    for (my $row = 0; $row < scalar(@$A); $row++) {
        for (my $col = 0; $col < scalar(@{$A->[0]}); $col++) {
            $C->[$row]->[$col] = $A->[$row]->[$col] - $B->[$row]->[$col];
        }
    }

    return $C;
}

sub read_from_file
{
    # Read a matrix from file given either a filename or a filehandle.
    my %parm = validated_hash(\@_,
		filename => { isa => 'Str', optional => 1 },
        filehandle => { isa => 'Ref', optional => 1 },
        separator => { isa => 'Str', default => ',' },
	);
	my $filename = $parm{'filename'};
    my $filehandle = $parm{'filehandle'};
	my $separator = $parm{'separator'};

    if (defined $filename) {
        open $filehandle, "<", $filename;
    }

    my @A;
    while (my $line = <$filehandle>) {
        chomp $line;
        my @fields = split($separator, $line);
        foreach my $e (@fields) {       # Convert into number. simplifies faultfinding and unittesting
            $e += 0;
        }
        push @A, \@fields;
    }

    if (defined $filename) {
        close $filehandle;
    }

    return \@A;
}

sub max
{
    #Return the maximum element of a matrix
    my $A = shift;

    my $maximum = -math::inf();

    for (my $row = 0; $row < scalar(@$A); $row++) {
        for (my $col = 0; $col < scalar(@{$A->[0]}); $col++) {
            if ($A->[$row]->[$col] > $maximum) {
                $maximum = $A->[$row]->[$col];
            }
        }
    }

    return $maximum;
}

sub absolute
{
    # In place elementwise absolute value of matrix
    my $A = shift;

    for (my $row = 0; $row < scalar(@$A); $row++) {
        for (my $col = 0; $col < scalar(@{$A->[0]}); $col++) {
            $A->[$row]->[$col] = abs($A->[$row]->[$col]);
        }
    }
}

sub pad_matrix
{
    # Augment a square matrix with unit matrix to new_size
	my $A = shift;
	my $new_size = shift;
	my $cur_size = scalar(@$A);

	for (my $row = 0; $row < $cur_size; $row++) {
		push @{$A->[$row]}, (0) x ($new_size - $cur_size);
	}
	for (my $i = scalar(@$A); $i < $new_size; $i++) {
		my @add = (0) x $new_size;
		$add[$i] = 1;
		push @$A, \@add;
	}
}

sub reduce_matrix
{
    # Reduce a square matrix to new size
	my $A = shift;
	my $new_size = shift;
	my $cur_size = scalar(@$A);
	
	for (my $row = 0; $row < $new_size; $row++) {
		splice @{$A->[$row]}, $new_size, $cur_size - $new_size;
	}
	splice @$A, $new_size, $cur_size - $new_size;
}

sub put_ones_on_diagonal_of_zero_lines
{
    # Replace all lines containing only zeros in matrix with ones on the diagonal
	my $A = shift;

	for (my $row = 0; $row < @$A; $row++) {
		my $all_zero = 1;
		for (my $col = 0; $col < @{$A->[$row]}; $col++) {
			if ($A->[$row]->[$col] != 0) {
				$all_zero = 0;
				last;
			}
		}
		if ($all_zero) {
			$A->[$row]->[$row] = 1;
		}
	}
}

sub triangular_symmetric_to_full
{
    # Convert a matrix in triangular vector form to full form assuming symmetry

    my $triangular = shift;
    my $A = [];

    my $row = 0;
    my $col = 0;
    foreach my $element (@$triangular) {
        $A->[$row]->[$col] = $element;
        $A->[$col]->[$row] = $element;
        $col++;
        if ($col > $row) {
            $col = 0;
            $row++;
        }
    }

    return $A;
}


sub mvnpdf_cholesky
{
    my $covar=shift;
    my $mu=shift;
    my $xvectors=shift;
	my $inflation=shift;
	my $relative=shift;

    my $ncol= scalar(@{$covar});
    my $mrow = scalar(@{$covar->[0]});
    croak("input covariance matrix to mvnpdf_cholesky is empty") unless ($ncol > 0);
    croak("input covariance matrix to mvnpdf_cholesky is not square, col $ncol rows $mrow") unless ($ncol == $mrow);
    croak("input mu to mvnpdf_cholesky undefined ") unless (defined $mu );
    croak("input mu to mvnpdf_cholesky has wrong dim ".scalar(@{$mu})) unless ($ncol == scalar(@{$mu}));
    croak("input xvectors to mvnpdf_cholesky undefined ") unless (defined $xvectors);
    croak("input xvectors to mvnpdf_cholesky is empty ") unless (scalar(@{$xvectors})>0);
    croak("input xvectors to mvnpdf_cholesky has wrong dim ".scalar(@{$xvectors->[0]})) unless ($ncol == scalar(@{$xvectors->[0]}));
    croak("input inflation to mvnpdf_cholesky is not positive: $inflation") unless ($inflation > 0);
    croak("input relative to mvnpdf_cholesky is $relative") unless (($relative == 1) or ($relative==0));

	my @covar_copy=();
	for (my $i=0; $i<$ncol; $i++){
		$covar_copy[$i] =[0 x $ncol];
		for (my $j=0; $j<$ncol; $j++){
			$covar_copy[$i][$j] = $covar->[$i][$j];
		}
	}

	my $err=cholesky_transpose(\@covar_copy);

	croak("failed cholesky in mvnpdf_cholesky") unless ($err==0);
	my @arr=();
	for (my $i=0; $i< $ncol; $i++){
		push(@arr,$covar_copy[$i][$i]);
	}
	my @sorted = sort { $a <=> $b } @arr; #sort ascending

	my $root_determinant = $sorted[0];
	for (my $i=1; $i< $ncol; $i++){
		$root_determinant = $root_determinant*$sorted[$i];
	}
	unless ($inflation == 1){
		$root_determinant = $root_determinant*($inflation**($ncol/2));
	}


	my @results=();

	foreach my $xvec (@{$xvectors}){
		my @diff = 0 x $ncol;
		for (my $j=0; $j< $ncol; $j++){
			$diff[$j]= ($xvec->[$j] - $mu->[$j]);
		}
		$err = linear_algebra::upper_triangular_transpose_solve(\@covar_copy,\@diff);
		croak("failed solve in mvnpdf_cholesky") unless ($err==0);

		my @sorted = sort { $a <=> $b } @diff; #sort ascending for numerical safety
		my $sum = 0;
		for (my $i=0; $i< $ncol; $i++){
			$sum = $sum + ($sorted[$i])**2;
		}
		unless ($inflation == 1){
			$sum = $sum/$inflation;
		}

		if ($relative){
			push(@results,exp(-0.5*$sum));
		}else{
			push(@results,(((2*pi)**(-$ncol/2))*(1/$root_determinant))*exp(-0.5*$sum));
		}
	}
	return \@results;
}

sub transpose
{
    # Transpose a matrix in place
    my $A = shift;
    for (my $row = 0; $row < @$A; $row++) {
        for (my $col = 0; $col < $row; $col++) {
            my $temp = $A->[$row]->[$col];
            $A->[$row]->[$col] = $A->[$col]->[$row];
            $A->[$col]->[$row] = $temp;
        }
    }
}

sub is_symmetric
{
    # Check if matrix is symmetric (A^T = A)
    my $A = shift;

    for (my $row = 0; $row < @$A; $row++) {
        for (my $col = 0; $col < $row; $col++) {
            if ($A->[$row]->[$col] != $A->[$col]->[$row]) {
                return 0;
            }
        }
    }

    return 1;
}

sub house
{ 
    my $xvec = shift;
    #add checking for 0 div here
    my $n=scalar(@{$xvec});
    my $sigma=0;
    my @vvec=@{$xvec};
    my $beta=0;
    $vvec[0]=1;
    for (my $i=1;$i<$n;$i++){
	$sigma += ($xvec->[$i])**2;
	$vvec[$i]=$xvec->[$i];
    }
    if ($sigma == 0){
	$beta=0;
    }else{
	my $mu = sqrt(($xvec->[0])**2 + $sigma);
	if ($xvec->[0] <= 0){
	    $vvec[0] = $xvec->[0]-$mu;
	}else{
	    $vvec[0] = -$sigma/($xvec->[0]+$mu);
	}
	$beta = 2*($vvec[0])**2/($sigma+($vvec[0])**2);
	for (my $i=1;$i<$n;$i++){
	    $vvec[$i]=$vvec[$i]/$vvec[0];
	}
	$vvec[0]=1;
    }
    my %answer={};
    $answer{'beta'}=$beta;
    $answer{'vvec'}=\@vvec;
    return \%answer;
} 

sub QR_factorize
{ 
    
    #verified against matlab for small matrices
    #householder method transform
    #assume Amatrix is column format
    #returned rmatrix is column format Rmat->[$col][$row]

    my $ref =shift;
    my $Rmatrix =shift;
    my @Amatrix = @{$ref};

    my $ncol= scalar(@Amatrix);
    my $endcol=$ncol-1;
    my $mrow = scalar(@{$Amatrix[0]});
    my $endrow=$mrow-1;
    my $input_error = 2;
    my $numerical_error = 1;

    
    for (my $j=0;$j<$ncol;$j++){
	my @xvec = @{$Amatrix[$j]}[$j..$endrow];
	#print join(' ',@xvec)."\n";
	#die;
	my $href = house(\@xvec);
	my $beta = $$href{'beta'}; #double $ ?
	my $vvec = $$href{'vvec'};
	#house transform A(j:endrow,j:endcol)
	#for first col know only first comp is number, rest is 0 (R matrix)
	#w=beta Atrans v
	my @wvec;
	for (my $i=0;$i<($ncol-$j);$i++){
	    my $col=$i+$j;
	    $wvec[$i]=0;
	    for (my $k=0;$k<($mrow-$j);$k++){
		$wvec[$i] += $beta*($vvec->[$k])*$Amatrix[$col][$k+$j];
	    }      
	}
	#col $j gives R
	my @rcol;
	@rcol = @{$Amatrix[$j]}[0..($j-1)] if ($j>0);
	push(@rcol,($Amatrix[$j][$j]-$wvec[0]*$vvec->[0]));
	push(@{$Rmatrix},\@rcol);
	#check that rest practically 0 
	for (my $k=1;$k<($mrow-$j);$k++){
	    my $val = $Amatrix[$j][$j+$k]-$wvec[0]*$vvec->[$k];
	    unless ( $val < 0.00001){
		print "error in house transformation j $j k $k val $val\n";
		return $numerical_error;
	    }
	}
	#tranform rest of A cols for next iteration
	for (my $i=1;$i<($ncol-$j);$i++){
	    for (my $k=0;$k<($mrow-$j);$k++){
		$Amatrix[$i+$j][$j+$k] = $Amatrix[$i+$j][$j+$k]-$wvec[$i]*$vvec->[$k];
	    }
	}
    }

    return 0;
} 

sub cholesky_transpose
{
    #input is lower triangle, including diagonal, of symmetric positive definite matrix 
    #in *column format*, A->[col][row]

	my $Aref=shift;
    my $input_error = 2;
    my $numerical_error = 1;
    my $ncol= scalar(@{$Aref});
    my $mrow = scalar(@{$Aref->[0]});
    return $input_error unless ($mrow == $ncol);

	my $err = cholesky($Aref);
	return $err unless ($err==0);

	#fill up
    for (my $j=0; $j< $ncol; $j++){
		for (my $i=($j+1); $i<$ncol; $i++){
			$Aref->[$i][$j] = $Aref->[$j][$i];
			$Aref->[$j][$i]= 0;
		}
	}
	return 0;
}

sub cholesky
{
    #input is lower triangle, including diagonal, of symmetric positive definite matrix 
    #in *column format*, A->[col][row]
    #this matrix is overwritten with lower triangular Cholesky factor (G^T) 
    #Golub p144 Alg 4.2.1
    #verified with matlab
    #verified call by reference

    my $Aref=shift;
    my $input_error = 2;
    my $numerical_error = 1;
    my $ncol= scalar(@{$Aref});
    my $mrow = scalar(@{$Aref->[0]});
    return $input_error unless ($mrow == $ncol);

    for (my $j=0; $j< $ncol; $j++){
		if ($j>0) {
			#i=j
			my $sum=0;
			for (my $k=0; $k<$j ; $k++){
				$sum=$sum+($Aref->[$k][$j])**2;
			}
			my $diff = $Aref->[$j][$j]-$sum;
			return $numerical_error if ($diff < 0);
			$Aref->[$j][$j]=sqrt($diff);
			return $numerical_error if ($Aref->[$j][$j] == 0);
			#i=j+1:n
			for (my $i=($j+1); $i<$ncol; $i++){
				my $sum=0;
				for (my $k=0; $k<$j ; $k++){
					$sum=$sum+($Aref->[$k][$j])*($Aref->[$k][$i]);
				}
				$Aref->[$j][$i]=($Aref->[$j][$i]-$sum)/($Aref->[$j][$j]);
			}
		} else {
			$Aref->[0][0]=sqrt($Aref->[0][0]);
			if ($Aref->[0][0] == 0){
				print "cholesky leading element is 0";
				return $numerical_error ;
			}
			for (my $i=1; $i< $ncol; $i++){
				$Aref->[0][$i]=$Aref->[0][$i]/($Aref->[0][0]);
			}
		}
    }

    return 0;
}

sub LU_factorization
{
	my $A_matrix = shift;
	my @A_temp = @{$A_matrix};
	
	#in *row format*, A->[row][col]
	#this matrix is overwritten with L(without the identity diagonal elements) and U
	#Golub p92 Algorithm 3.2.2

	my $i = 0;
	while($A_temp[$i][$i] != 0 && $i < $#A_temp + 1) {
		for(my $j = 0; $j < $#A_temp + 1; $j++) {
			for(my $k = 0; $k < $#A_temp + 1; $k++) {
			}
		}
		my @A_copy = map { [@$_] } @A_temp;
		
		for (my $j = $i + 1; $j < $#A_temp + 1; $j++) {
			my $tau = $A_temp[$j][$i] / $A_temp[$i][$i];
			for (my $k = $i + 1; $k < $#A_temp + 1; $k++) {
				$A_temp[$j][$k] = $A_temp[$j][$k] - $tau * $A_copy[$i][$k];
			}
			$A_temp[$j][$i] = $tau;
		}
		$i++;
	}
	if ($i != ($#A_temp)) {
		die "LU factorization failed. \n";
	}
	return 0;
}

sub eigenvalue_decomposition
{
    # Perfor an eigenvalue decomposition of a symmetric matrix
    # using the Jacoby algorithm
    my $A = shift;

    my @eigenValMatrix = map { [@$_] } @$A;

    my $maxInd1 = 0;
    my $maxInd2 = 1;
    my $extremeVal = 10000;
    my $counter = 0;

    my @G;

    #initialise G to identity matrix
    for (my $index1 = 0; $index1 < scalar(@eigenValMatrix); $index1++) {
        for (my $index2 = 0; $index2 < $index1; $index2++) {
            $G[$index1][$index2] = 0;
            $G[$index2][$index1] = 0;
        }
        $G[$index1][$index1] = 1;
    }

    while (abs($extremeVal) > 0.0000000001 and $counter < 100000000) {

        for (my $index1 = 0; $index1 < scalar(@eigenValMatrix); $index1++) {
            for (my $index2 = $index1 + 1; $index2 < scalar(@eigenValMatrix); $index2++) {
                if ((abs($eigenValMatrix[$maxInd1][$maxInd2]) < abs($eigenValMatrix[$index1][$index2])) and ($index1 != $index2)) {
                    $maxInd1 = $index1;
                    $maxInd2 = $index2;
                    $extremeVal = $eigenValMatrix[$maxInd1][$maxInd2];
                }
            }
        }
        my $theta = (atan(2 * $eigenValMatrix[$maxInd1][$maxInd2] / ($eigenValMatrix[$maxInd2][$maxInd2] - $eigenValMatrix[$maxInd1][$maxInd1]))) / 2;
        my $c = cos($theta);
        my $s = sin($theta);

        my @G_copy = map { [@$_] } @G;
        my @R_copy = map { [@$_] } @eigenValMatrix;

        for (my $index = 0; $index < scalar(@G); $index++) {
            $G[$maxInd1][$index] = $c * $G_copy[$maxInd1][$index] - $s * $G_copy[$maxInd2][$index];
            $G[$maxInd2][$index] = $s * $G_copy[$maxInd1][$index] + $c * $G_copy[$maxInd2][$index];
        }

        for (my $index = 0; $index < scalar(@eigenValMatrix); $index++) {
            $eigenValMatrix[$maxInd1][$index] = $c * $R_copy[$maxInd1][$index] - $s * $R_copy[$maxInd2][$index];
            $eigenValMatrix[$maxInd2][$index] = $s * $R_copy[$maxInd1][$index] + $c * $R_copy[$maxInd2][$index];
        }

        my @r1;
        my @r2;

        for (my $index = 0; $index < scalar(@eigenValMatrix); $index++) {
            $r1[$index] = $eigenValMatrix[$index][$maxInd1];
            $r2[$index] = $eigenValMatrix[$index][$maxInd2];
        }

        my @R_copy2 = map { [@$_] } @eigenValMatrix;

        for (my $index = 0; $index < scalar(@eigenValMatrix); $index++) {
            $eigenValMatrix[$index][$maxInd1] = $c * $R_copy2[$index][$maxInd1] - $s * $R_copy2[$index][$maxInd2];
            $eigenValMatrix[$index][$maxInd2] = $s * $R_copy2[$index][$maxInd1] + $c * $R_copy2[$index][$maxInd2];
        }

        $counter = $counter + 1;
    }

    my @eigenValues;

    for (my $index = 0; $index < scalar(@eigenValMatrix); $index++) {
        $eigenValues[$index] = $eigenValMatrix[$index][$index];
    }

    transpose(\@G);

    return (\@eigenValues, \@G);
}

sub lower_triangular_identity_solve
{
    #input is lower triangular matrix
    #in *column format*, A->[col][row]
    #and number of columns $nsolve to solve for
    #and reference to empty solution matrix
    #right hand side is first $ncol columns of identity matrix
    #algorithm Golub p 90, alg 3.1.3 adapted to identity right hand side and stop after $ncol
    #verified against matlab

    my $Aref=shift;
    my $nsolve=shift;
    my $solution = shift;
    my $input_error = 2;
    my $numerical_error = 1;

    my $ncol= scalar(@{$Aref});
    return $input_error if ($nsolve>$ncol);
    my $nrow = scalar(@{$Aref->[0]});
    return $input_error unless ($nrow == $ncol);

    #create part of identity matrix as right hand. Will be overwritten with solution
    for (my $i=0; $i<$nsolve; $i++){
	push(@{$solution},[(0) x $nrow]);
	$solution->[$i][$i]=1;
    }

    #solve by forward substitution
    for (my $i=0; $i< $nsolve; $i++){   
	if ($i < ($nrow-1)){
	    #right column is nonzero only for j=i
	    return $numerical_error if ($Aref->[$i][$i] == 0);
	    $solution->[$i][$i]=$solution->[$i][$i]/$Aref->[$i][$i];
	    for (my $k=($i+1);$k<$nrow;$k++){
		$solution->[$i][$k]=-$solution->[$i][$i]*$Aref->[$i][$k];
	    }
	}

	for (my $j=($i+1);$j<($nrow-1);$j++){
	    return $numerical_error if ($Aref->[$j][$j] == 0);
	    $solution->[$i][$j]=$solution->[$i][$j]/$Aref->[$j][$j];
	    for (my $k=($j+1);$k<$nrow;$k++){
		$solution->[$i][$k]=$solution->[$i][$k]-$solution->[$i][$j]*$Aref->[$j][$k];
	    }
	}
	return $numerical_error if ($Aref->[$nrow-1][$nrow-1] == 0);
	$solution->[$i][$nrow-1]=$solution->[$i][$nrow-1]/$Aref->[$nrow-1][$nrow-1];

    }
    return 0;


}

sub upper_triangular_solve
{
    #input is upper triangular matrix
    #in *column format*, Umat->[col][row]
    #and reference to right hand vector which will be overwritten with solution
    #solve Umat*x=b
    #algorithm Golub p 89, alg 3.1.2
    #verified with matlab 

    my $Umat=shift;
    my $solution = shift;
    my $input_error = 2;
    my $numerical_error = 1;
    my $ncol= scalar(@{$Umat});

    return $numerical_error if ($Umat->[$ncol-1][$ncol-1] == 0);
    $solution->[$ncol-1]=$solution->[$ncol-1]/$Umat->[$ncol-1][$ncol-1];
    for (my $i=($ncol-2);$i>=0;$i--){
      my $sum=0;
      for (my $j=($i+1);$j<$ncol;$j++){
	$sum += ($Umat->[$j][$i])*$solution->[$j];
      }
      return $numerical_error if ($Umat->[$i][$i] == 0);
      $solution->[$i]=($solution->[$i]-$sum)/($Umat->[$i][$i]); 
    }
    return 0;

}

sub upper_triangular_transpose_solve
{
    #input is upper triangular matrix
    #in *column format*, Umat->[col][row]
    #and reference to right hand vector which will be overwritten with solution
    #solve Umat'*x=b
    #algorithm Golub p 89, lower triangular alg 3.1.1
    #verified with matlab

    my $Umat=shift;
    my $solution = shift;
    my $input_error = 2;
    my $numerical_error = 1;
    my $ncol= scalar(@{$Umat});

    return $numerical_error if ($Umat->[0][0] == 0);
    $solution->[0]=$solution->[0]/$Umat->[0][0];

    for (my $i=1;$i<$ncol;$i++){
		my $sum=0;
		for (my $j=0;$j<$i;$j++){
			$sum += ($Umat->[$i][$j])*$solution->[$j];
		}
		return $numerical_error if ($Umat->[$i][$i] == 0);
		$solution->[$i]=($solution->[$i]-$sum)/$Umat->[$i][$i];
    }
	
    return 0;
	
}

sub upper_triangular_identity_solve
{
    #input is upper triangular matrix
    #in *column format*, A->[col][row]
    #and reference to empty solution matrix
    #right hand side is identity matrix
    #algorithm Golub p 90, alg 3.1.4 adapted to identity right hand side
    #verified with matlab

    my $Aref=shift;
    my $solution = shift;
    my $input_error = 2;
    my $numerical_error = 1;
    my $ncol= scalar(@{$Aref});

    for (my $j=0;$j< $ncol;$j++){
	my $nrow = scalar(@{$Aref->[$j]});
#	print "nrow $nrow ncol $ncol\n";
	return $input_error unless ($nrow > $j);
    }

    #create identity matrix as right hand. Will be overwritten with solution
    for (my $i=0; $i<$ncol; $i++){
	push(@{$solution},[(0) x $ncol]);
	$solution->[$i][$i]=1;
    }
    for (my $i=0;$i<$ncol; $i++){
	if ($i>0){
	    return $numerical_error if ($Aref->[$i][$i] == 0);
	    $solution->[$i][$i]=$solution->[$i][$i]/$Aref->[$i][$i];
	    for (my $k=0; $k<$i;$k++){
		$solution->[$i][$k]=-$solution->[$i][$i]*$Aref->[$i][$k];
	    }
	}
	for (my $j=($i-1);$j>0;$j--){
	    return $numerical_error if ($Aref->[$j][$j] == 0);
	    $solution->[$i][$j]=$solution->[$i][$j]/$Aref->[$j][$j];
	    for (my $k=0; $k<$j; $k++){
		$solution->[$i][$k]=$solution->[$i][$k]-$solution->[$i][$j]*$Aref->[$j][$k];
	    }
	}
	return $numerical_error if ($Aref->[0][0] == 0);
	$solution->[$i][0]=$solution->[$i][0]/$Aref->[0][0];
    }
    return 0;
}

sub upper_triangular_UUT_multiply
{
    #input is upper triangular matrix
    #in *column format*, R->[col][row]
    #and reference to empty solution matrix
    #multiply from the right with transpose, output only lower triangle of symmetric matrix
    #verified in matlab

    my $Rref=shift;
    my $solution = shift;
    my $input_error = 2;
    my $numerical_error = 1;
    my $ncol= scalar(@{$Rref});

    for (my $j=0;$j< $ncol;$j++){
	my $nrow = scalar(@{$Rref->[$j]});
#	print "nrow $nrow ncol $ncol\n";
	return $input_error unless ($nrow > $j);
    }

    #create zeros matrix as placeholder for solution
    for (my $i=0; $i<$ncol; $i++){
	push(@{$solution},[(0) x $ncol]);
    }

    for (my $i=0; $i< $ncol; $i++){
	for (my $j=0; $j<=$i; $j++){
	    my $sum=0;
	    for (my $k=$i; $k< $ncol; $k++){
		$sum=$sum+$Rref->[$k][$i]*$Rref->[$k][$j];
	    }
	    $solution->[$j][$i]=$sum;
	}
    }
    return 0;
}

sub column_cov
{
    #input is reference to values matrix 
    #in *column format*, Aref->[col][row]
    #and reference to empty result matrix
    #compute square variance covariance matrix
    #Normalization is done with N-1, input error if N<2
    #verified with matlab cov function

    my $Aref=shift;
    my $varcov = shift;
    my $input_error = 2;
    my $numerical_error = 1;
    my $ncol= scalar(@{$Aref});
    my $nrow = scalar(@{$Aref->[0]});
    return $input_error if ($nrow < 2);

    my @sum = (0) x $ncol;
    my @mean = (0) x $ncol;

    #initialize square result matrix
    for (my $i=0; $i<$ncol; $i++){
	push(@{$varcov},[(0) x $ncol]);
    }

    for (my $col=0; $col< $ncol; $col++){
	return $input_error if (scalar(@{$Aref->[$col]}) != $nrow);

	foreach my $val (@{$Aref->[$col]}){
	    $sum[$col] = $sum[$col] + $val;
	}
	$mean[$col]=$sum[$col]/$nrow;

	#variance
	my $sum_errors_pow2=0;
	foreach my $val (@{$Aref->[$col]}){
	    $sum_errors_pow2 = $sum_errors_pow2 + ($val - $mean[$col])**2;
	}
	unless ( $sum_errors_pow2 == 0 ){
	    #if sum is 0 then assume all estimates 0, just ignore
	    $varcov->[$col][$col]= $sum_errors_pow2/($nrow-1);
	}

	#covariance
	#here $j is always smaller than $col, meaning that mean is already computed 
	for (my $j=0; $j< $col; $j++){
	    my $sum_errors_prod=0;
	    for (my $i=0; $i< $nrow; $i++){
		$sum_errors_prod = $sum_errors_prod + ($Aref->[$col][$i] - $mean[$col])*($Aref->[$j][$i] - $mean[$j]);
	    }
	    unless( $sum_errors_prod == 0 ){
		#if sum is 0 then assume all estimates 0, just ignore
		$varcov->[$j][$col]= $sum_errors_prod/($nrow-1);
		$varcov->[$col][$j]=$varcov->[$j][$col]; 
	    }
	}

    }

    return 0;
}

sub row_cov
{
    #input is reference to values matrix 
    #in *row format*, Aref->[row][col]
    #and reference to empty result matrix
    #compute square variance covariance matrix
    #Normalization is done with N-1, input error if N<2
    #verified with matlab cov function

    
    my $Aref=shift;
    my $varcov = shift;
    my $debug=0;
    my $input_error = 2;
    my $numerical_error = 1;
    my $nrow= scalar(@{$Aref});
    return $input_error if ($nrow < 2);
    my $ncol = scalar(@{$Aref->[0]});
    for (my $row=1; $row< $nrow; $row++){
	return $input_error if (scalar(@{$Aref->[$row]}) != $ncol);
    }

    my @sum = (0) x $ncol;
    my @mean = (0) x $ncol;

    #initialize square result matrix
    for (my $i=0; $i<$ncol; $i++){
	push(@{$varcov},[(0) x $ncol]);
    }

    for (my $col=0; $col< $ncol; $col++){

	for (my $row=0; $row< $nrow; $row++){
	    $sum[$col] = $sum[$col] + $Aref->[$row][$col];
	}
	$mean[$col]=$sum[$col]/$nrow;
	print "mean $col is ".$mean[$col]."\n" if $debug;
	#variance
	my $sum_errors_pow2=0;
	for (my $row=0; $row< $nrow; $row++){
	    $sum_errors_pow2 = $sum_errors_pow2 + ($Aref->[$row][$col] - $mean[$col])**2;
	}
	unless ( $sum_errors_pow2 == 0 ){
	    #if sum is 0 then assume all estimates 0, just ignore
	    $varcov->[$col][$col]= $sum_errors_pow2/($nrow-1);
	    print "variance $col is ".$varcov->[$col][$col]."\n" if $debug;
	}

	#covariance
	#here $j is always smaller than $col, meaning that mean is already computed 
	for (my $j=0; $j< $col; $j++){
	    my $sum_errors_prod=0;
	    for (my $i=0; $i< $nrow; $i++){
		$sum_errors_prod = $sum_errors_prod + ($Aref->[$i][$col] - $mean[$col])*($Aref->[$i][$j] - $mean[$j]);
	    }
	    unless( $sum_errors_prod == 0 ){
		#if sum is 0 then assume all estimates 0, just ignore
		$varcov->[$j][$col]= $sum_errors_prod/($nrow-1);
		$varcov->[$col][$j]=$varcov->[$j][$col]; 
	    }
	}

    }

    return 0;
}

sub row_cov_median
{
    #input is reference to values matrix 
    #in *row format*, Aref->[row][col]
    #and reference to empty result matrix covariance
    #and reference to empty result array median
    #and missing data token
    #compute square variance covariance matrix
    #Normalization is done with N-1, input error if N<2
    #compute median
    #handle missing values: skip in all computations, adjust N in mean and normalization
    #verified with matlab cov function when no missing values.
    #verified with matlab for replacing values equal to mean with missing in a pattern when only xor missing, not both missing
    
    my $Aref=shift;
    my $varcov = shift;
    my $median = shift;
    my $missing_data_token = shift;
    my $debug=0;
    my $input_error = 2;
    my $numerical_error = 1;
    my $nrow= scalar(@{$Aref});
    return $input_error if ($nrow < 2);
    my $ncol = scalar(@{$Aref->[0]});
    for (my $row=1; $row< $nrow; $row++){
		return $input_error if (scalar(@{$Aref->[$row]}) != $ncol);
    }

    my @sum = (0) x $ncol;
    my @mean = (0) x $ncol;
    my @N_array = (0) x $ncol; #smaller N if missing values

    #initialize square result matrix
    for (my $i=0; $i<$ncol; $i++){
		push(@{$varcov},[(0) x $ncol]);
    }
    @{$median} = (0) x $ncol;

    for (my $col=0; $col< $ncol; $col++){
		my @values=();
		for (my $row=0; $row< $nrow; $row++){
			unless ($Aref->[$row][$col] == $missing_data_token){
				$sum[$col] = $sum[$col] + $Aref->[$row][$col];
				$N_array[$col] = $N_array[$col]+1; 
				push(@values,$Aref->[$row][$col]);
			}
		}
		return $input_error if ($N_array[$col]<2);
		$mean[$col]=$sum[$col]/$N_array[$col];
		print "mean $col is ".$mean[$col]."\n" if $debug;
		$median->[$col]=median(\@values);
		#variance
		my $sum_errors_pow2=0;
		for (my $row=0; $row< $nrow; $row++){
			unless ($Aref->[$row][$col] == $missing_data_token){
				$sum_errors_pow2 = $sum_errors_pow2 + ($Aref->[$row][$col] - $mean[$col])**2;
			}
		}
		unless ( $sum_errors_pow2 == 0 ){
			#if sum is 0 then assume all estimates 0, just ignore
			$varcov->[$col][$col]= $sum_errors_pow2/($N_array[$col]-1);
			print "variance $col is ".$varcov->[$col][$col]."\n" if $debug;
		}

		#covariance
		#here $j is always smaller than $col, meaning that mean is already computed 
		#how handle missing in one but not the other...? 
		#if xor missing then add to N_local but not to sum_errors_prod. Is like assuming missin value is equal to mean, 
		#which is not too bad
		for (my $j=0; $j< $col; $j++){
			my $sum_errors_prod=0;
			my $N_local=0;
			for (my $i=0; $i< $nrow; $i++){
				if (($Aref->[$i][$col] != $missing_data_token) and ($Aref->[$i][$j] != $missing_data_token)){
					#have both values
					$sum_errors_prod = $sum_errors_prod + ($Aref->[$i][$col] - $mean[$col])*($Aref->[$i][$j] - $mean[$j]);
					$N_local++;
				}elsif (($Aref->[$i][$col] == $missing_data_token) xor ($Aref->[$i][$j] == $missing_data_token)){
					$N_local++;
					#have one value but not the other, pretend missing value is equal to mean.
				}
				#if both missing then just skip
			}
			unless( $sum_errors_prod == 0 ){
				#if sum is 0 then assume all estimates 0, just ignore
				$varcov->[$j][$col]= $sum_errors_prod/($N_local-1);
				$varcov->[$col][$j]=$varcov->[$j][$col]; 
			}
		}

    }
	
    return 0;
}

sub get_identity_matrix
{
	my $dimension = shift;

	croak("dimension must be larger than 0 in get_identity_matrix") unless ($dimension > 0);
	my @result = ();
	for (my $i = 0; $i < $dimension; $i++) {
		my @line = (0) x $dimension;
		$line[$i] = 1;
		push(@result, \@line);
	}
	return \@result;
}

sub invert_symmetric
{
    #input is full symmetric positive definite matrix 
    #this matrix will be overwritten
	#and reference to empty result matrix
    #verified with matlab

    my $matrixref = shift;
	my $result = shift;

    my $err=cholesky($matrixref);
    if ($err > 0){
		print "cholesky error $err in invert_symmetric\n";
		return $err ;
    }
    my $refInv = [];
	my $ncol =scalar(@{$matrixref});
    $err = lower_triangular_identity_solve($matrixref,$ncol,$refInv);
    if ($err > 0){
		print "lower triang error $err in invert_symmetric\n";
		return $err ;
    }

    $err = lower_triangular_UTU_multiply($refInv,$result);
    if ($err > 0){
		print "multiply error in invert_symmetric\n";
		return $err ;
    }

    return 0;
}

sub lower_triangular_UTU_multiply
{
    #input is lower triangular matrix
    #in *column format*, R->[col][row]
    #and reference to empty solution matrix
    #multiply from the left with transpose, output is full symmetric square matrix
    #verified in matlab

    my $Rref=shift;
    my $solution = shift;
    my $input_error = 2;
    my $numerical_error = 1;
    my $ncol= scalar(@{$Rref});

    for (my $j=0;$j< $ncol;$j++){
		my $nrow = scalar(@{$Rref->[$j]});
#	print "nrow $nrow ncol $ncol\n";
		return $input_error unless ($nrow > $j);
    }

    #create zeros matrix as placeholder for solution
    for (my $i=0; $i<$ncol; $i++){
		push(@{$solution},[(0) x $ncol]);
    }

    for (my $i=0; $i< $ncol; $i++){
		for (my $j=0; $j<=$i; $j++){
			my $sum=0;
			for (my $k=$i; $k< $ncol; $k++){
				$sum=$sum+$Rref->[$i][$k]*$Rref->[$j][$k];
			}
			$solution->[$j][$i]=$sum;
			$solution->[$i][$j]=$sum;
		}
    }
    return 0;
}

sub frem_conditional_omega_block
{
    #input is lower triangle, including diagonal, of symmetric positive definite matrix 
    #in *column format*, A->[col][row]
    #this matrix will be overwritten
    #input is also number of leading interesting etas
    #and reference to empty result matrix which will hold symmetric conditional omega block
    #verified with matlab

    my $omegaref = shift;
    my $n_eta = shift;
    my $result = shift;

    my $err=cholesky($omegaref);
    if ($err > 0){
		print "cholesky error $err in frem\n";
		return $err ;
    }
    my $refInv = [];
    $err = lower_triangular_identity_solve($omegaref,$n_eta,$refInv);
    if ($err > 0){
		print "lower triang error $err in frem\n";
		return $err ;
    }


    my $Rmat=[];
    $err = QR_factorize($refInv,$Rmat);
    if ($err > 0){
		print "QR error in frem\n";
		return $err ;
    }


    my $refRInv = [];
    $err = upper_triangular_identity_solve($Rmat,$refRInv);
    if ($err > 0){
		print "upper triang error in frem\n";
		return $err ;
    }
    return $err if ($err > 0);

    $err = upper_triangular_UUT_multiply($refRInv,$result);
    if ($err > 0){
		print "multiply error in frem\n";
		return $err ;
    }

    #fill in full matrix to avoid sorrows outside this function 
    my $dim = scalar(@{$result});
    for (my $row=0; $row<$dim; $row++){
		for (my $col=0; $col<$dim; $col++){
			$result->[$col][$row]=$result->[$row][$col];
		}
    }

    return 0;

}

if (0){
    my @Amatrix=();
    push(@Amatrix,[9.6900000e-02,6.7600000e-02,7.0400000e-02,-9.3500000e-01,1.9500000e+00,3.4300000e+00,-8.9000000e-03,-4.2900000e-02,3.6100000e-02,7.7700000e-03]);
    push(@Amatrix,[0,6.0600000e-02,-4.2100000e-03,-4.1300000e-01,2.5300000e+00,2.4500000e+00,-3.6600000e-02,-1.9100000e-02,1.3600000e-02,-7.8100000e-03]);
    push(@Amatrix,[0,0,2.3400000e+00,9.7000000e-01,-4.0800000e-01,-2.2500000e+00,-6.9700000e-02,-2.2500000e-01,-9.0900000e-02,7.2200000e-03]);
    push(@Amatrix,[0,0,0,6.0500000e+01,-1.7000000e+01,-7.9500000e+01,-3.5900000e-01,9.3000000e-01,-2.4200000e-01,-1.1400000e-01]);
    push(@Amatrix,[0,0,0,0,2.4800000e+02,2.3500000e+02,-3.1300000e+00,-2.6600000e-01,-4.0300000e-01,-1.6000000e+00]);
    push(@Amatrix,[0,0,0,0,0,4.7100000e+02,-2.0100000e+00,-2.1000000e+00,1.4100000e+00,-1.0600000e+00]);
    push(@Amatrix,[0,0,0,0,0,0,1.6200000e-01,-4.5400000e-03,2.0200000e-02,3.0700000e-02]);
    push(@Amatrix,[0,0,0,0,0,0,0,2.4900000e-01,-5.5100000e-02,1.8800000e-02]);
    push(@Amatrix,[0,0,0,0,0,0,0,0,2.3200000e-01,2.0500000e-02]);
    push(@Amatrix,[0,0,0,0,0,0,0,0,0,2.2800000e-01]);
    
    my $b = [1,2,3,4,5,6,7,8,9,10];

    my $result = [];
    my $err = frem_conditional_omega_block(\@Amatrix,3,$result);
    
    if (0){
	my $Rmat=[];
	my $err1 = QR_factorize(\@Amatrix,$Rmat);
	my $err2 = upper_triangular_transpose_solve($Rmat,$b);
    }

    for (my $row=0; $row<3; $row++){
	for (my $col=0; $col<3; $col++){
	    printf("  %.4f",$result->[$col][$row]); #matlab format
	}
	print "\n";
    }
    print "\n";

}
if (0){
    #to verify column_cov function
    my @Bmatrix=();
    push(@Bmatrix,[9.6900000e-02,6.7600000e-02,7.0400000e-02,-9.3500000e-01,1.9500000e+00,3.4300000e+00,-8.9000000e-03,-4.2900000e-02,3.6100000e-02,7.7700000e-03]);
    push(@Bmatrix,[0.01,6.0600000e-02,-4.2100000e-03,-4.1300000e-01,2.5300000e+00,2.4500000e+00,-3.6600000e-02,-1.9100000e-02,1.3600000e-02,-7.8100000e-03]);
    push(@Bmatrix,[0.01,0.01,2.3400000e+00,9.7000000e-01,-4.0800000e-01,-2.2500000e+00,-6.9700000e-02,-2.2500000e-01,-9.0900000e-02,7.2200000e-03]);

    my $covmatrix=[];
    my $err1 = column_cov(\@Bmatrix,$covmatrix);
    for (my $row=0; $row<3; $row++){
	for (my $col=0; $col<3; $col++){
	    printf("  %.4f",$covmatrix->[$row][$col]); #matlab format
	}
	print "\n";
    }
    print "\n";


}

if (0){
    #to verify row_cov_median function
    my @Bmatrix=();

    push(@Bmatrix,[-99,6.7600000e-02,7.0400000e-02,-9.3500000e-01,1.9500000e+00,3.4300000e+00,-8.9000000e-03,-4.2900000e-02,3.6100000e-02,7.7700000e-03]);
    push(@Bmatrix,[0.01,-99,-4.2100000e-03,-4.1300000e-01,2.5300000e+00,2.4500000e+00,-3.6600000e-02,-1.9100000e-02,1.3600000e-02,-7.8100000e-03]);
    push(@Bmatrix,[0.01,0.01,-99,9.7000000e-01,-4.0800000e-01,-2.2500000e+00,-6.9700000e-02,-2.2500000e-01,-9.0900000e-02,7.2200000e-03]);
    push(@Bmatrix,[9.6900000e-02,6.0600000e-02,2.3400000e+00,9.7000000e-01,-4.0800000e-01,-2.2500000e+00,-6.9700000e-02,-2.2500000e-01,-9.0900000e-02,7.2200000e-03]);


    my $covmatrix=[];
    my $median=[];
    my $err1 = row_cov_median(\@Bmatrix,$covmatrix,$median,'-99');
#    my $err1 = row_cov(\@Bmatrix,$covmatrix);
    for (my $row=0; $row<10; $row++){
	for (my $col=0; $col<10; $col++){
	    printf("  %.4f",$covmatrix->[$row][$col]); #matlab format
	}
	print "\n";
    }
    print "\n";

    for (my $row=0; $row<10; $row++){
	printf("  %.4f",$median->[$row]); #matlab format
    }
    print "\n";
}

1;
