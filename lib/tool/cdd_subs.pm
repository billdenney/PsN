# {{{ include statements

start include statements
#use Carp;
	use include_modules;
use Cwd;
use File::Copy 'cp';
use tool::llp;
use tool::modelfit;
use Math::Random;
use ext::Math::MatrixReal;
use Data::Dumper;

end include statements

# }}} include statements

# {{{ new

start new
      {
	  for my $accessor ('logfile','raw_results_file','raw_nonp_file'){
	      my @new_files=();
	      my @old_files = ();
	      @old_files = @{$this->$accessor} if (defined $this->$accessor);
	      for (my $i=0; $i < scalar(@old_files); $i++){
		  my $name;
		  my $ldir;
		  ( $ldir, $name ) =
		      OSspecific::absolute_path( $this ->directory(), $old_files[$i] );
		  push(@new_files,$ldir.$name) ;
	      }
	      $this->$accessor(\@new_files);
	  }	

      }
end new

# }}} new



# {{{ read_cdd_log
start read_cdd_log
{
  if( -e $self -> directory.'object.txt' ) {
    $found_log = 1;
    open( OLOG, '<'.$self -> directory.'object.txt' );
    my @olog = <OLOG>;
    my $str = "(";
    for ( my $i = 1; $i < $#olog; $i++ ) {
      $str = $str.$olog[$i];
    }
    $str = $str.")";
    my %tmp = eval( $str );
    
    if( exists $tmp{'cdd_id'} ) {
      $self -> cdd_id($tmp{'cdd_id'});
      $found_cdd_id = 1;
    }
    close( OLOG );
  }
}
end read_cdd_log
# }}} read_cdd_log

# {{{ llp_pre_fork_setup

start llp_pre_fork_setup
      {
	$self -> modelfit_pre_fork_setup;
      }
end llp_pre_fork_setup

# }}} llp_pre_fork_setup

# {{{ modelfit_pre_fork_setup

start modelfit_pre_fork_setup
      {

	  unless ( defined $self->bins ) {
	      $self->bins($self->models->[0]->datas->[0]->count_ind);
	  }
	  
      }
end modelfit_pre_fork_setup

# }}} modelfit_pre_fork_setup

# {{{ modelfit_setup

start modelfit_setup
      {
	$self -> general_setup( model_number => $model_number,
				class        => 'tool::modelfit',
			        subm_threads => $self->threads );
      }
end modelfit_setup

# }}} modelfit_setup

# {{{ llp_setup
start llp_setup
      {
	my @subm_threads;
	if (ref( $self -> threads ) eq 'ARRAY') {
	  @subm_threads = @{$self -> threads};
	  unshift(@subm_threads);
	} else {
	  @subm_threads = ($self -> threads);
	}
	$self -> general_setup( model_number => $model_number,
				class        => 'tool::llp',
			        subm_threads => \@subm_threads );
      }
end llp_setup
# }}} llp_setup

# {{{ general_setup

start general_setup
      {
	# Sub tool threads can be given as scalar or reference to an array?
	my $subm_threads = $parm{'subm_threads'};
	my $own_threads = ref( $self -> threads ) eq 'ARRAY' ? 
	    $self -> threads -> [0]:$self -> threads;
	# case_column names are matched in the model, not the data!

	my $model = $self   -> models -> [$model_number-1];

	# Check which models that hasn't been run and run them
	# This will be performed each step but will only result in running
	# models at the first step, if at all.

	# If more than one process is used, there is a VERY high risk of interaction
	# between the processes when creating directories for model fits. Therefore
	# the directory attribute is given explicitly below.


	unless ( $model -> is_run ) {

	  # -----------------------  Run original run  ------------------------------

	  # {{{ orig run

	  my %subargs = ();
	  if ( defined $self -> subtool_arguments ) {
	    %subargs = %{$self -> subtool_arguments};
	  }
	  if( $self -> nonparametric_etas or
	      $self -> nonparametric_marginals ) {
	    $model -> add_nonparametric_code;
	  }
	  
	  my $orig_fit = tool::modelfit ->
	      new( %{common_options::restore_options(@common_options::tool_options)},
		   models                => [$model],
		   threads               => 1,
		   directory             => $self -> directory.'/orig_modelfit_dir'.$model_number,
		   subtools              => [],
		   parent_threads        => $own_threads,
		   parent_tool_id        => $self -> tool_id,
		   logfile	         => undef,
		   raw_results           => undef,
		   prepared_models       => undef,
		   top_tool              => 0,
		   %subargs );


	  ui -> print( category => 'cdd',
		       message => 'Executing base model.' );


	  $orig_fit -> run;

	  # }}} orig run

	}
	
	# ------------------------  Print a log-header  -----------------------------

	# {{{ log header

	open( LOG, ">>".$self -> logfile->[$model_number-1] );
	my $ui_text = sprintf("%-5s",'RUN').','.sprintf("%20s",'FILENAME  ').',';
	print LOG sprintf("%-5s",'RUN'),',',sprintf("%20s",'FILENAME  '),',';
	foreach my $param ( 'ofv', 'theta', 'omega', 'sigma' ) {
#	  my $accessor    = $param eq 'ofv' ? $param : $param.'s';
#	  my $orig_ests   = $model -> outputs -> [0] -> $accessor;
	  my $orig_ests;
	  my $name = $param;
	  if ($param eq 'ofv'){
	    $orig_ests   = $model -> outputs -> [0] -> ofv();
	    $name = 'DIC' 
		if (defined $model -> outputs -> [0]->get_single_value(attribute => 'dic'));
	  }else{
	    $orig_ests   = $model -> get_values_to_labels(category => $param);
	  }
	  # Loop the problems
	  if( defined $orig_ests ){
	    for ( my $j = 0; $j < scalar @{$orig_ests}; $j++ ) {
	      if ( $param eq 'ofv' ) {
		my $label = uc($name)."_".($j+1);
		$ui_text = $ui_text.sprintf("%12s",$label).',';
		print LOG sprintf("%12s",$label),',';
	      } else {
		# Loop the parameter numbers (skip sub problem level)
		if( defined $orig_ests -> [$j] and 
		    defined $orig_ests -> [$j][0] ){
		  for ( my $num = 1; $num <= scalar @{$orig_ests -> [$j][0]}; $num++ ) {
		    my $label = uc($param).$num."_".($j+1);
		    $ui_text = $ui_text.sprintf("%12s",$label).',';
		    print LOG sprintf("%12s",$label),',';
		  }
		}
	      }
	    }
	  }
	}

	print LOG "\n";

	# }}} log header

	# ------------------------  Log original run  -------------------------------

	# {{{ log orig

	open( LOG, ">>".$self -> logfile->[$model_number-1] );
	$ui_text = sprintf("%5s",'0').','.sprintf("%20s",$model -> filename).',';
	print LOG sprintf("%5s",'0'),',',sprintf("%20s",$model -> filename),',';
	foreach my $param ( 'ofv', 'theta', 'omega', 'sigma' ) {
#	  my $accessor    = $param eq 'ofv' ? $param : $param.'s';
#	  my $orig_ests   = $model -> outputs -> [0] -> $accessor;
	  my $orig_ests;
	  if ($param eq 'ofv'){
	    $orig_ests   = $model -> outputs -> [0] -> ofv();
	  }else{
	    $orig_ests   = $model -> get_values_to_labels(category => $param);
	  }
	  # Loop the problems
	  if( defined $orig_ests ) {
	    for ( my $j = 0; $j < scalar @{$orig_ests}; $j++ ) {
	      if ( $param eq 'ofv' ) {
		$ui_text = $ui_text.sprintf("%12f",$orig_ests -> [$j][0]).',';
		print LOG sprintf("%12f",$orig_ests -> [$j][0]),',';
	      } else {
		# Loop the parameter numbers (skip sub problem level)
		if( defined $orig_ests -> [$j] and 
		    defined $orig_ests -> [$j][0] ){
		  for ( my $num = 0; $num < scalar @{$orig_ests -> [$j][0]}; $num++ ) {
		    $ui_text = $ui_text.sprintf("%12f",$orig_ests -> [$j][0][$num]).',';
		    print LOG sprintf("%12f",$orig_ests -> [$j][0][$num]),',';
		  }
		}
	      }
	    }
	  }
	}

	print LOG "\n";

	# }}} log orig

	# ---------------------  Initiate some variables ----------------------------

	# {{{ inits

	# Case-deletion Diagnostics will only work for models with one problem.
	my $orig_data = $model -> datas -> [0];

	if ( not defined $orig_data ) {
	  croak("No data file to resample from found in ".$model -> full_name );
	}

	my @problems   = @{$model -> problems};
	my @new_models = ();

	my ( @skipped_ids, @skipped_keys, @skipped_values );

	my %orig_factors = %{$orig_data -> factors( column => $self->case_column )};
	my $maxbins      = scalar keys %orig_factors;
	my $pr_bins      = ( defined $self->bins and $self->bins <= $maxbins ) ? $self->bins : $maxbins;
	
	my $done = ( -e $self -> directory."/m$model_number/done" ) ? 1 : 0;

	my ( @seed, $new_datas, $skip_ids, $skip_keys, $skip_values, $remainders );

	# }}} inits

	if ( not $done ) {

	  # --------------  Create new case-deleted data sets  ----------------------

	  # {{{ create new

	  # Keep the new sample data objects i memory and write them to disk later
	  # with a proper name.

	  ( $new_datas, $skip_ids, $skip_keys, $skip_values, $remainders )
	    = $orig_data -> case_deletion( case_column => $self->case_column,
					   selection   => $self -> selection_method,
					   bins        => $pr_bins,
					   target      => 'mem',
					   directory   => $self -> directory.'/m'.$model_number );
	  my $ndatas = scalar @{$new_datas};
	  for ( my $j = 1; $j <= $ndatas; $j++ ) {
	    my @names = ( 'cdd_'.$j, 'rem_'.$j );
	    my @datasets = ( $new_datas -> [$j-1], $remainders -> [$j-1] );
	    foreach my $i ( 0, 1 ) {
	      my $dataset = $datasets[$i];
	      my ($data_dir, $data_file) = OSspecific::absolute_path( $self -> directory.'/m'.$model_number,
								      $names[$i].'.dta' );
	      my $skip_data_parsing = 1;
	      if ($self->drop_dropped) {
		$skip_data_parsing = 0 ;
	      }
	      $dataset->skip_parsing($skip_data_parsing);
	      my $newmodel = $model -> copy( filename => $data_dir.$names[$i].'.mod',
					     copy_data   => 0,
					     copy_output => 0);
	      $newmodel -> ignore_missing_files(1);
	      $newmodel -> datafiles( new_names => [$names[$i].'.dta'] );
	      $newmodel -> outputfile( $data_dir.$names[$i].".lst" );
	      $newmodel -> datas -> [0] = $dataset;
	      if( $i == 1 ) {
		# set MAXEVAL=0. Again, CDD will only work for one $PROBLEM
		my $warn = 0;
		$warn = 1 if ($j == 1);
		my $ok = $newmodel -> set_maxeval_zero(need_ofv => 1,print_warning => $warn,
						       niter_eonly => $self->niter_eonly,
						       last_est_complete => $self->last_est_complete());
	      }

	      if( $self -> nonparametric_etas or
		  $self -> nonparametric_marginals ) {
		$newmodel -> add_nonparametric_code;
	      }
	  
	      $newmodel -> _write;
	      push( @{$new_models[$i]}, $newmodel );
	    }
	  }

	  # Create a checkpoint. Log the samples and individuals.
	  open( DONE, ">".$self -> directory."/m$model_number/done" ) ;
	  print DONE "Sampling from ",$orig_data -> filename, " performed\n";
	  print DONE "$pr_bins bins\n";
	  print DONE "Skipped individuals:\n";
	  for( my $k = 0; $k < scalar @{$skip_ids}; $k++ ) {
	    print DONE join(',',@{$skip_ids -> [$k]}),"\n";
	  }
	  print DONE "Skipped keys:\n";
	  for( my $k = 0; $k < scalar @{$skip_keys}; $k++ ) {
	    print DONE join(',',@{$skip_keys -> [$k]}),"\n";
	  }
	  print DONE "Skipped values:\n";
	  for( my $k = 0; $k < scalar @{$skip_values}; $k++ ) {
	    print DONE join(',',@{$skip_values -> [$k]}),"\n";
	  }
	  @seed = random_get_seed;
	  print DONE "seed: @seed\n";
	  close( DONE );

	  open( SKIP, ">".$self -> directory."skipped_individuals".$model_number.".csv" ) ;
	  for( my $k = 0; $k < scalar @{$skip_ids}; $k++ ) {
	    print SKIP join(',',@{$skip_ids -> [$k]}),"\n";
	  }
	  close( SKIP );
	  open( SKIP, ">".$self -> directory."skipped_keys".$model_number.".csv" ) ;
	  for( my $k = 0; $k < scalar @{$skip_keys}; $k++ ) {
	    print SKIP join(',',@{$skip_keys -> [$k]}),"\n";
	  }
	  close( SKIP );

	  # }}} create new

	} else {

	  # ---------  Recreate the datasets and models from a checkpoint  ----------

	  # {{{ resume

	  ui -> print( category => 'cdd',
		       message  => "Recreating models from a previous run" );
	  open( DONE, $self -> directory."/m$model_number/done" );
	  my @rows = <DONE>;
	  close( DONE );
	  my ( $junk, $junk, $stored_filename, $junk ) = split(' ',$rows[0],4);
	  my ( $stored_bins, $junk ) = split(' ',$rows[1],2);
	  my ( @stored_ids, @stored_keys, @stored_values );
	  for ( my $k = 3; $k < 3+$stored_bins; $k++ ) {
	    chomp($rows[$k]);
	    my @bin_ids = split(',', $rows[$k] );
	    push( @stored_ids, \@bin_ids );
	  }
	  for ( my $k = 4+$stored_bins; $k < 4+2*$stored_bins; $k++ ) {
	    chomp($rows[$k]);
	    my @bin_keys = split(',', $rows[$k] );
	    push( @stored_keys, \@bin_keys );
	  }
	  for ( my $k = 5+2*$stored_bins; $k < 5+3*$stored_bins; $k++ ) {
	    chomp($rows[$k]);
	    my @bin_values = split(',', $rows[$k] );
	    push( @stored_values, \@bin_values );
	  }
	  @seed = split(' ',$rows[5+3*$stored_bins]);
	  $skip_ids    = \@stored_ids;
	  $skip_keys   = \@stored_keys;
	  $skip_values = \@stored_values;
	  shift( @seed ); # get rid of 'seed'-word

	  # Reinitiate the model objects
#	  my @model_ids;
#	  my $reg_relations = 0;
#	  if ( -e $self -> directory."m$model_number/done.database.models" ) {
#	    open( DB, $self -> directory."m$model_number/done.database.models" );
#	    @model_ids = <DB>;
#	    chomp( @model_ids );
#	  } else {
#	    open( DB, ">".$self -> directory."m$model_number/done.database.models" );
#	    $reg_relations = 1;
#	  }
	  for ( my $j = 1; $j <= $stored_bins; $j++ ) {
	    my @names = ( 'cdd_'.$j, 'rem_'.$j );
	    foreach my $i ( 0, 1 ) {
	      my ($model_dir, $filename) = OSspecific::absolute_path( $self -> directory.'/m'.
								      $model_number,
								      $names[$i].'.mod' );
	      my ($out_dir, $outfilename) = OSspecific::absolute_path( $self -> directory.'/m'.
								       $model_number,
								       $names[$i].'.lst' );
	      my $new_mod = model ->
		  new( directory   => $model_dir,
		       filename    => $filename,
		       outputfile  => $outfilename,
		       extra_files => $model -> extra_files,
		       target      => 'disk',
		       ignore_missing_files => 1,
		       quick_reload => 1);
	      push( @{$new_models[$i]}, $new_mod );
	    }

	    my $nl = $j == $stored_bins ? "" : "\r"; 
	    ui -> print( category => 'cdd',
			 message  => ui -> status_bar( sofar => $j+1,
						       goal  => $stored_bins+1 ).$nl,
			 wrap     => 0,
			 newline  => 0 );
	  }
#	  close( DB );
#	  if ( not -e $self -> directory."m$model_number/done.database.tool_models" ) {
#	    open( DB, ">".$self -> directory."m$model_number/done.database.tool_models" );
#	    print DB "";
#	    close( DB );
#	  }
	  ui -> print( category => 'cdd',
		       message  => " ... done." );
	  random_set_seed( @seed );
	  ui -> print( category => 'cdd',
		       message  => "Using $stored_bins previously sampled case-deletion sets ".
		       "from $stored_filename" )
	    unless $self -> parent_threads > 1;

	  # }}} resume

	}
	push( @skipped_ids,    $skip_ids );
	push( @skipped_keys,   $skip_keys );
	push( @skipped_values, $skip_values );

	# Use only the first half (the case-deleted) of the data sets.
	$self -> prepared_models->[$model_number-1]{'own'} = $new_models[0];

	# The remainders are left until the analyze step, only run if xv

	$self -> prediction_models->[$model_number-1]{'own'} = $new_models[1];

	# ---------------------  Create the sub tools  ------------------------------

	# {{{ sub tools

	#this is just a modelfit
	my $subdir = $class;
	$subdir =~ s/tool:://;
	my @subtools;
	@subtools = @{$self -> subtools} if (defined $self->subtools);
	shift( @subtools );
	my %subargs = ();
	if ( defined $self -> subtool_arguments ) {
	  %subargs = %{$self -> subtool_arguments};
	}
	$self->tools([]) unless (defined $self->tools);
	push( @{$self -> tools},
	      $class ->
	      new( %{common_options::restore_options(@common_options::tool_options)},
			   models                => $new_models[0],
			   threads               => $subm_threads,
			   nmtran_skip_model => 2,
			   directory             => $self -> directory.'/'.$subdir.'_dir'.$model_number,
			   _raw_results_callback => $self ->
			   _modelfit_raw_results_callback( model_number => $model_number ),
			   subtools              => \@subtools,
			   parent_threads        => $own_threads,
			   parent_tool_id        => $self -> tool_id,
			   logfile	         => undef,
			   raw_results           => undef,
			   prepared_models       => undef,
			   top_tool              => 0,
			   %subargs ) );



	# }}} sub tools

	open( SKIP, ">".$self -> directory."skipped_values".$model_number.".csv" ) ;
	for( my $k = 0; $k < scalar @{$skip_values}; $k++ ) {
	  print SKIP join(',',@{$skip_values -> [$k]}),"\n";
	}
	close( SKIP );

      }
end general_setup

# }}} general_setup

# {{{ llp_analyze

start llp_analyze
      {
	print "POSTFORK\n";
	my %proc_results;

	
	push( @{$self -> results -> {'own'}}, \%proc_results );
      }
end llp_analyze

# }}} llp_analyze

# {{{ _modelfit_raw_results_callback

start _modelfit_raw_results_callback
      {

	# Use the cdd's raw_results file.  
	# The cdd and the bootstrap's callback methods are identical
	# in the beginning, then the cdd callback adds cook.scores and
	# cov.ratios.

	my ($dir,$file) = 
	  OSspecific::absolute_path( $self -> directory,
				     $self -> raw_results_file->[$model_number-1] );
	my $orig_mod = $self -> models->[$model_number-1];
	my $xv = $self -> cross_validate;
	$subroutine = sub {
	  my $modelfit = shift;
	  my $mh_ref   = shift;
	  my %max_hash = %{$mh_ref};
	  $modelfit -> raw_results_file( [$dir.$file] );

	  if( $cross_validation_set ) {
	    $modelfit -> raw_results_append( 1 ) if( not $self -> bca_mode ); # overwrite when doing a jackknife
	    my ( @new_header, %param_names );
	    foreach my $row ( @{$modelfit -> raw_results} ) {
	      unshift( @{$row}, 'cross_validation' );
	    }
	    $modelfit -> {'raw_results_header'} = undef; # May be a bit silly to do... #FIXME for Moose
	  } else {

	    my %dummy;

	    my ($raw_results_row,$nonp_rows) = $self -> create_raw_results_rows( max_hash => $mh_ref,
										 model => $orig_mod,
										 raw_line_structure => \%dummy );

	    $orig_mod -> outputs -> [0] -> flush;

	    unshift( @{$modelfit -> raw_results}, @{$raw_results_row} );
	    
	    &{$self -> _raw_results_callback}( $self, $modelfit )
		if ( defined $self -> _raw_results_callback ); #true from bootstrap jackknife

	    $self->raw_line_structure($modelfit -> raw_line_structure);
	    if( $xv and not $self -> bca_mode ) {
	      foreach my $row ( @{$modelfit -> raw_results} ) {
		unshift( @{$row}, 'cdd' );
	      }
	      unshift( @{$modelfit -> raw_results_header}, 'method' );
	      foreach my $mod (sort({$a <=> $b} keys %{$self->raw_line_structure})){
		foreach my $category (keys %{$self->raw_line_structure -> {$mod}}){
		  next if ($category eq 'line_numbers');
		  my ($start,$len) = split(',',$self->raw_line_structure -> {$mod}->{$category});
		  $self->raw_line_structure -> {$mod}->{$category} = ($start+1).','.$len; #+1 for method
		}
		$self->raw_line_structure -> {$mod}->{'method'} = '0,1';
	      }
	    }
	    $self->raw_line_structure -> {'0'} = $self->raw_line_structure -> {'1'};
	    $self->raw_line_structure -> write( $dir.'raw_results_structure' );
	  }
	}; 
	return $subroutine;
      }
end _modelfit_raw_results_callback

# }}} _modelfit_raw_results_callback

# {{{ modelfit_analyze

start modelfit_analyze
      {
	# Only valid for one problem and one sub problem.

	if ( $self -> cross_validate ) {

	  # ---  Evaluate the models on the remainder data sets  ----

	  # {{{ eval models

	  for ( my $i = 0;
		$i < scalar @{$self -> prediction_models->[$model_number-1]{'own'}};
		$i++ ) {
	    $self -> prediction_models->[$model_number-1]{'own'}[$i] ->
		update_inits( from_model => $self ->
			      prepared_models->[$model_number-1]{'own'}[$i]);
	    $self -> prediction_models->[$model_number-1]{'own'}[$i] ->
		remove_records( type => 'covariance' );
	    $self -> prediction_models->[$model_number-1]{'own'}[$i] -> _write;
	  }
	  my ($dir,$file) = 
	      OSspecific::absolute_path( $self -> directory,
					 $self -> raw_results_file->[$model_number-1] );
	  my $xv_threads = ref( $self -> threads ) eq 'ARRAY' ? 
	      $self -> threads -> [1]:$self -> threads;
	  my $mod_eval = tool::modelfit ->
	      new( %{common_options::restore_options(@common_options::tool_options)},
			   models           => $self -> prediction_models->[$model_number-1]{'own'},
			   base_directory   => $self -> directory,
			   nmtran_skip_model => 2,
			   directory        => $self -> directory.'evaluation_dir'.$model_number, 
			   threads          => $xv_threads,
			   _raw_results_callback => $self -> _modelfit_raw_results_callback( model_number => $model_number,
																				 cross_validation_set => 1 ),
			   parent_tool_id   => $self -> tool_id,
			   logfile	    => undef,
			   raw_results      => undef,
			   prepared_models  => undef,
			   top_tool         => 0,
			   retries          => 1 );
	  $Data::Dumper::Maxdepth = 2;
	  print "Running xv runs\n";
	  $mod_eval -> run;

	  # }}} eval models

	}

	# ------------  Cook-scores and Covariance-Ratios  ----------

	# {{{ Cook-scores and Covariance-Ratios

	# ----------------------  Cook-score  -----------------------
	
	# {{{ Cook-score

	my ( @cook_score, @cov_ratio );
	my $do_pca = 1;
	if( $self -> models -> [$model_number-1] ->
	    outputs -> [0] -> get_single_value(attribute=> 'covariance_step_successful')) {

	  ui -> print( category => 'cdd',
		       message  => "Calculating diagnostics" );
	  my @orig_ests;
	  my @changes;

	  #get the estimated theta names from self outputs, model 0 subprob 0 
	  my %est_names;
	  my $ref = $self -> models -> [$model_number-1] ->
	      outputs -> [0] -> get_single_value(attribute=> 'est_thetanames');
	  $est_names{'theta'} = $ref if (defined $ref);
	  $ref = $self -> models -> [$model_number-1] ->
	      outputs -> [0] -> get_single_value(attribute=> 'est_omeganames');
	  $est_names{'omega'} = $ref if (defined $ref);
	  $ref = $self -> models -> [$model_number-1] ->
	      outputs -> [0] -> get_single_value(attribute=> 'est_sigmanames');
	  $est_names{'sigma'} = $ref if (defined $ref);
	  
	  #when loop over prepared models $i, get thetacoordval, select values from 
	  #hash with estimated  names

	  # Calculate the changes
	  foreach my $param ('theta','omega','sigma' ) {
	    my $attr = $param.'coordval';
	    my $orig_est = $self -> models -> [$model_number-1] -> 
		outputs -> [0] -> get_single_value(attribute=> $attr);
	    next unless ( defined $est_names{$param});

	    my %original;
	    %original = %{$orig_est} if (defined $orig_est);
	    next unless (%original); #if empty hash then skip

	    for ( my $i=0; $i<scalar @{$self -> prepared_models->[$model_number-1]{'own'}}; $i++ ) {
	      my $est = $self -> prepared_models->[$model_number-1]{'own'}->[$i]->
		  outputs -> [0] -> get_single_value(attribute=> $attr);
	      if ( defined $est and %{$est}) {
		my %casedeleted = %{$est};
		foreach my $name (@{$est_names{$param}}){
		  if (defined $casedeleted{$name} and $original{$name}){
		    push( @{$changes[$i]}, $original{$name}-$casedeleted{$name});
		  }
		}
	      }	# if $est undefined do nothing
	    }		  
	  }

	  my $inverse_covariance_matrix  = $self -> models -> [$model_number-1]->outputs -> [0] -> inverse_covariance_matrix(problems=>[1],subproblems => [1]); 
	  # Equation: sqrt((orig_est-est(i))'*inv_cov_matrix*(orig_est-est(i)))


 	  for ( my $i = 0; $i <= $#changes; $i++ ) {
	    if( defined $changes[$i] and
		scalar @{$changes[$i]} > 0 and 
		defined $inverse_covariance_matrix
		and defined $inverse_covariance_matrix->[0]
		and defined $inverse_covariance_matrix->[0]->[0]) {
	      my $vec_changes = Math::MatrixReal ->
		  new_from_cols( [$changes[$i]] );
	      $cook_score[$i] = ($inverse_covariance_matrix->[0]->[0])*$vec_changes;
	      $cook_score[$i] = ~$vec_changes*$cook_score[$i];
	    } else {
	      $do_pca = 0;
	      $cook_score[$i] = undef;
	    }

	    my $nl = $i == $#changes ? "" : "\r"; 
	    ui -> print( category => 'cdd',
			 message  => ui -> status_bar( sofar => $i+1,
						       goal  => $#changes+1 ).$nl,
			 wrap     => 0,
			 newline  => 0 );
	  }
	    
	  # Calculate the square root 
	  # The matrixreal object holds a 1x1 matrix in the first position of its array.
	  for ( my $i = 0; $i <= $#cook_score; $i++ ) {
	    if( defined $cook_score[$i] and 
		$cook_score[$i][0][0][0] >= 0 ) {
	      $cook_score[$i] = sqrt($cook_score[$i][0][0][0]);
	    } else {
	      open( LOG, ">>".$self -> logfile->[$model_number-1] );
	      my $mes;
	      if( defined $cook_score[$i] ) {
		$mes = "Negative squared cook-score ",$cook_score[$i][0][0][0];
	      } else {
		$mes = "Undefined squared cook-score";
	      }
	      $mes .= "; can't take the square root.\n",
	      "The cook-score for model $model_number and cdd bin $i was set to zero\n";
	      print LOG $mes;
	      close( LOG );
	      carp($mes );
	      
	      $cook_score[$i] = 0;
	    }
	  }
	}
	
	$self -> cook_scores(\@cook_score);
	$do_pca = 0 if (scalar(@cook_score)==0);

	ui -> print( category => 'cdd',
		     message  => " ... done." );

	# }}} Cook-score

	# -------------------  Covariance Ratio  --------------------

	# {{{ Covariance Ratio

	if( $self -> models -> [$model_number-1] ->
	    outputs -> [0] -> get_single_value(attribute=> 'covariance_step_successful')) {

	  # {{{ sub clear dots

	  sub clear_dots {
	    my $m_ref = shift;
	    my @matrix = @{$m_ref};
	    # get rid of '........'
	    my @clear;
	    foreach ( @matrix ) {
	      push( @clear, $_ ) unless ( $_ eq '.........' );
	    }
	    return \@clear;
	  }

	  # }}}
	  
	  # {{{ sub make square
	  
	  sub make_square {
	    my $m_ref = shift;
	    my @matrix = @{$m_ref};
	    # Make the matrix square:
	    my $elements = scalar @matrix; # = M*(M+1)/2
	    my $M = -0.5 + sqrt( 0.25 + 2 * $elements );
	    my @square;
	    for ( my $m = 1; $m <= $M; $m++ ) {
	      for ( my $n = 1; $n <= $m; $n++ ) {
		push( @{$square[$m-1]}, $matrix[($m-1)*$m/2 + $n - 1] );
		unless ( $m == $n ) {
		  push( @{$square[$n-1]}, $matrix[($m-1)*$m/2 + $n - 1] );
		}
	      }
	    }
	    return \@square;
	  }
	  
	  # }}}

	  ui -> print( category => 'cdd',
		       message  => "Calculating the covariance-ratios" );
	  
	  # Equation: sqrt(det(cov_matrix(i))/det(cov_matrix(orig)))
	  my $cov_linear  = $self -> models -> [$model_number-1] ->
	      outputs -> [0] ->  raw_covmatrix(problems=>[1],subproblems => [1]);
	  my $orig_det;
	  if( defined $cov_linear and defined $cov_linear->[0] and defined $cov_linear->[0]->[0]) {
	    my $orig_cov = Math::MatrixReal ->
		new_from_cols( make_square( clear_dots( $cov_linear->[0]->[0] ) ) );
	    $orig_det = $orig_cov -> det();
	  }
	  # AUTOLOAD: raw_covmatrix

	  my $output_harvest = $self -> harvest_output( accessors => ['raw_covmatrix'],
							search_output => 1 );
	  
	  my $est_cov = defined $output_harvest -> {'raw_covmatrix'} ? $output_harvest -> {'raw_covmatrix'} -> [$model_number-1]{'own'} : [];

	  my $mods = scalar @{$est_cov};
	  for ( my $i = 0; $i < scalar @{$est_cov}; $i++ ) {
	    if ( $orig_det != 0 and defined $est_cov->[$i][0][0] ) {
	      my $cov = Math::MatrixReal ->
		  new_from_cols( make_square( clear_dots( $est_cov->[$i][0][0] ) ) );
	      my $ratio = $cov -> det() / $orig_det;
	      if( $ratio > 0 ) {
		push( @cov_ratio, sqrt( $ratio ) );
	      } else {
		open( LOG, ">>".$self -> logfile->[$model_number-1] );
		print LOG "Negative covariance ratio ",$ratio,
		"; can't take the square root.\n",
		"The covariance ratio for model $model_number and cdd bin $i was set to one (1)\n";
		close( LOG );
		push( @cov_ratio, 1 );
	      }	      
	    } else {
	      open( LOG, ">>".$self -> logfile->[$model_number-1] );
	      print LOG "The determinant of the cov-matrix of the original run was zero\n",
	      "or the determinant of cdd bin $i was undefined\n",
	      "The covariance ratio for model $model_number and cdd bin $i was set to one (1)\n";
	      close( LOG );
	      push( @cov_ratio, 1 );
	    }
	    
	    my $nl = $i == $mods-1 ? "" : "\r"; 
	    ui -> print( category => 'cdd',
			 message  => ui -> status_bar( sofar => $i+1,
						       goal  => $mods ).$nl,
			 wrap     => 0,
			 newline  => 0 );
	  }
	}

	$self -> covariance_ratios(\@cov_ratio);

	ui -> print( category => 'cdd',
		     message  => " ... done." );
	
	# }}} Covariance Ratio

	# -  Perform a PCA on the cook-score:covariance-ratio data --

	# {{{ PCA

	my ( @outside_n_sd, $eig_ref, $eig_vec_ref, $proj_ref, $std_ref );

	if( $self -> models -> [$model_number-1] ->
	    outputs -> [0] -> get_single_value(attribute=> 'covariance_step_successful')
	    and $do_pca){
	  
	  ( $eig_ref, $eig_vec_ref, $proj_ref, $std_ref ) =
	      $self -> pca( data_matrix => [\@cook_score,\@cov_ratio] );
	  my @projections = @{$proj_ref};
	  my @standard_deviation = @{$std_ref};

	  # }}}

	  # ----  Mark the runs with CS-CR outside N standard deviations of the PCA ----

	  # {{{ mark runs

	  for( my $i = 0; $i <= $#projections; $i++ ) {
	    my $vector_length = 0;
	    for( my $j = 0; $j <= 1; $j++ ) {
	      $vector_length += $projections[$i][$j]**2;
	    }
	    $vector_length = sqrt( $vector_length );
	    my $n_sd = 0;
	    for( my $j = 0; $j <= 1; $j++ ) {
	      $n_sd += (($projections[$i][$j]/$vector_length)*$standard_deviation[$j])**2;
	    }
	    $n_sd = ( $self -> outside_n_sd_check * sqrt( $n_sd ) );
	    $outside_n_sd[$i] = $vector_length > $n_sd ? 1 : 0;
	  }
        }

	$self -> outside_n_sd(\@outside_n_sd);

	# }}} mark runs

	my %run_info_return_section;
	my @run_info_labels=('Date','PsN version','NONMEM version');
	my @datearr=localtime;
	my $the_date=($datearr[5]+1900).'-'.($datearr[4]+1).'-'.($datearr[3]);
  	my @run_info_values =($the_date,'v'.$PsN::version,'v'.$self->nm_version);
	$run_info_return_section{'labels'} =[[],\@run_info_labels];
	$run_info_return_section{'values'} = [\@run_info_values];

	my %covariance_return_section;
	$covariance_return_section{'name'} = 'Diagnostics';
	$covariance_return_section{'labels'} = [[],['cook.scores','covariance.ratios','outside.n.sd']];

	my @res_array;
	for( my $i = 0; $i <= $#cov_ratio; $i ++ ){
	  push( @res_array , [$cook_score[$i],$cov_ratio[$i],$outside_n_sd[$i]] );
	}

	$covariance_return_section{'values'} = \@res_array;

	push( @{$self -> results->[$model_number-1]{'own'}},\%covariance_return_section );

	# }}}

	# ---------  Relative estimate change and Jackknife bias  ----------

	# {{{ Relative change of the parameter estimates

	my $output_harvest = $self -> harvest_output( accessors => ['ofv', 'thetas', 'omegas', 'sigmas','sethetas', 'seomegas', 'sesigmas'],
						      search_output => 1 );

	my %return_section;
	$return_section{'name'} = 'relative.changes.percent';
	$return_section{'labels'} = [[],[]];

	my %bias_return_section;
	$bias_return_section{'name'} = 'Jackknife.bias.estimate';
	$bias_return_section{'labels'} = [['bias','relative.bias'],[]];

	my $print_debug=0;
	my ( @bias, @bias_num, @b_orig, @rel_bias );
	my $k = 0;


	my $coordslabelsref = $self -> models -> [$model_number-1] 
	    -> get_coordslabels( parameter_type => 'omega' );
	my %coordslabels;
	if (defined $coordslabelsref ->[0]){
	  %coordslabels = %{$coordslabelsref->[0]};
	}else{
	  croak("failed to call get_coordslabels for omega from cdd");
	}
	$coordslabelsref = $self -> models -> [$model_number-1] 
	    -> get_coordslabels( parameter_type => 'sigma' );
	if (defined $coordslabelsref ->[0]){
	  my %tmp = %{$coordslabelsref->[0]};
	  foreach my $key (keys %tmp) {
	    $coordslabels{$key} = $tmp{$key};
	  }
	}else{
	  croak("failed to call get_coordslabels for sigma from cdd");
	}
	$coordslabelsref = $self -> models -> [$model_number-1] 
	    -> get_coordslabels( parameter_type => 'theta' );
	if (defined $coordslabelsref ->[0]){
	  my %tmp = %{$coordslabelsref->[0]};
	  foreach my $key (keys %tmp){
	    $coordslabels{$key} = $tmp{$key};
	  }
	}else{
	  croak("failed to call get_coordslabels for theta from cdd");
	}


	foreach my $param ( 'thetas', 'omegas', 'sigmas' ) {
	  print $param."\n" if ($print_debug);
	  my $orig_est = $self -> models -> [$model_number-1] -> outputs -> [0] -> $param;
	  my $access = $param;
	  $access =~ s/s$//;
	  $access .= 'names';
	  my $names = $self -> models -> [$model_number-1] -> outputs -> [0] -> $access;
	  if ( defined $orig_est->[0][0] ) {
	    for ( my $j = 0; $j < scalar @{$orig_est->[0][0]}; $j++ ) {
	      next unless (defined $coordslabels{($names->[0][0][$j])}); #only defined if param in model
	      $b_orig[$k++] = $orig_est->[0][0][$j];
	      print $b_orig[$k++]." " if ($print_debug);
	    }
	    print "\n" if ($print_debug);
	  }
	}

	my @rel_ests;	

	for ( my $i = 0; $i < scalar @{$output_harvest -> {'ofv'} -> [$model_number-1]{'own'}}; $i++ ) {
	  #loop $i over case deleted datasets
	  my @values;
	  my $k = 0;
	  foreach my $param ( 'ofv', 'thetas', 'omegas', 'sigmas',
			      'sethetas', 'seomegas', 'sesigmas',) {
	    
	    my $orig_est = $self -> models -> [$model_number-1] -> outputs -> [0] -> $param;
	    my $est = defined $output_harvest -> {$param} ? $output_harvest -> {$param} -> [$model_number-1]{'own'} : [];
	    if ( $param eq 'ofv' ) {
	      if ( defined $orig_est->[0][0] and $orig_est->[0][0] != 0 ) {
		push( @values, ($est->[$i][0][0]-$orig_est->[0][0])/$orig_est->[0][0]*100 );
	      } else {
		push( @values, 'INF' );
	      }
	      if( $i == 0 ){
		my $name = $param;
		$name = 'DIC' 
		    if (defined $self -> models -> [$model_number-1] -> outputs -> [0]
			->get_single_value(attribute => 'dic'));

		push( @{$return_section{'labels'} -> [1]}, $name );
	      }
	    } else {
	      my $access = $param;
	      $access =~ s/^se//;
	      $access =~ s/s$//;
	      $access = $access.'names';
	      my $names = $self -> models -> [$model_number-1] -> outputs -> [0] -> $access;
	      my @in_rel_ests;
	      if( defined $est->[$i][0][0] ){
		for ( my $j = 0; $j < scalar @{$est->[$i][0][0]} ; $j++ ) {
		  next unless (defined $coordslabels{($names->[0][0][$j])}); #only defined if param in model
		  if ( defined $orig_est->[0][0][$j] and $orig_est->[0][0][$j] != 0 ) {
		    print $param." ".$orig_est->[0][0][$j]." ".$est->[$i][0][0][$j]."\n" if ($print_debug);
		    push( @values, ($est->[$i][0][0][$j]-$orig_est->[0][0][$j])/$orig_est->[0][0][$j]*100);
		    if( substr($param,0,2) ne 'se' ) {
		      $bias[$k] += $est->[$i][0][0][$j];
		      $bias_num[$k++]++;
		    }
		  } else {
		    push( @values, 'INF' );
		    if( substr($param,0,2) ne 'se' ) {
		      $k++;
		    }		  
		  }
		  if( $i == 0 ){
		    if( substr($param,0,2) eq 'se' ) {
		      push( @{$return_section{'labels'} -> [1]}, 'se'.$coordslabels{($names->[0][0][$j])} );
		    } else {
		      my $lbl = $coordslabels{($names->[0][0][$j])} ;
		      push( @{$bias_return_section{'labels'} -> [1]}, $lbl );
		      push( @{$return_section{'labels'} -> [1]}, $lbl );
		    }
		  }
		}
	      }
	    }
	    
	  }
	  push( @rel_ests, \@values );
	}
	
	# Jackknife bias

	for( my $i = 0; $i <= $#bias_num; $i++ ) {

	  next if( not defined $bias[$i] );
	  $bias[$i] = ($self->bins-1)*
	      ($bias[$i]/$bias_num[$i]-$b_orig[$i]);
	  if( defined $b_orig[$i] and $b_orig[$i] != 0 ) {
	    $rel_bias[$i] = $bias[$i]/$b_orig[$i]*100;
	  } else {
	    $rel_bias[$i] = undef;
	  }
	}
	$bias_return_section{'values'} = [\@bias,\@rel_bias];

	$return_section{'values'} = \@rel_ests ;
	push( @{$self -> results->[$model_number-1]{'own'}},\%return_section );
	push( @{$self -> results->[$model_number-1]{'own'}},\%bias_return_section );

	# }}} Relative change of the parameter estimates


	$self -> update_raw_results(model_number => $model_number);

	# -------------  Register the results in a Database  ----------------

#	if( not -e $self -> directory."m$model_number/done.database.results" ) {
#	  open( DB, ">".$self -> directory."m$model_number/done.database.results" );
#	  my ( $start_id, $last_id ) = $self ->
#	      register_mfit_results( model_number     => $model_number,
#				     cook_score       => \@cook_score,
#				     covariance_ratio => \@cov_ratio,
#				     projections      => $proj_ref,
#				     outside_n_sd      => \@outside_n_sd );
#	  print DB "$start_id-$last_id\n";
#	  close( DB );
#	}

	# experimental: to save memory
	$self -> prepared_models->[$model_number-1]{'own'} = undef;
	if( defined $PsN::config -> {'_'} -> {'R'} and
	    -e $PsN::lib_dir . '/R-scripts/cdd.R' ) {
	  # copy the cdd R-script
	  cp ( $PsN::lib_dir . '/R-scripts/cdd.R', $self -> directory );
	  # Execute the script
	  system( $PsN::config -> {'_'} -> {'R'}." CMD BATCH cdd.R" );
	}
      }
end modelfit_analyze

# }}} modelfit_analyze

# {{{ pca
start pca

my $D = Math::MatrixReal ->  new_from_rows( \@data_matrix );
my @n_dim = @{$data_matrix[0]};
my @d_dim = @data_matrix;
my $n = scalar @n_dim;
my $d = scalar @d_dim;
map( $_=(1/$n), @n_dim );
my $frac_vec_n = Math::MatrixReal ->  new_from_cols( [\@n_dim] );
map( $_=1, @n_dim );
map( $_=1, @d_dim );
my $one_vec_n = Math::MatrixReal -> new_from_cols( [\@n_dim] );
my $one_vec_d = Math::MatrixReal -> new_from_cols( [\@d_dim] );
my $one_vec_d_n = $one_vec_d * ~$one_vec_n;
my $M = $D*$frac_vec_n;
my $M_matrix = $M * ~$one_vec_n;

# Calculate the mean-subtracted data
my $S = $D-$M_matrix;

# compue the empirical covariance matrix
my $C = $S * ~$S;

# compute the eigenvalues and vectors
my ($l, $V) = $C -> sym_diagonalize();

# Project the original data on the eigenvectors
my $P = ~$V * $S;


# l, V and projections are all MatrixReal objects.
# We need to return the normal perl equivalents.
@eigenvalues = @{$l->[0]};
@eigenvectors = @{$V->[0]};
@std = @{$self -> std( data_matrix => $P -> [0] )};
# Make $P a n * d matrix
$P = ~$P;
@projections = @{$P->[0]};

end pca
# }}} pca

# {{{ std
start std

my ( @sum, @pow_2_sum );
if ( defined $data_matrix[0] ) {
  my $n = scalar @{$data_matrix[0]};
  for( my $i = 0; $i <= $#data_matrix; $i++ ) {
    for( my $j = 0; $j < $n; $j++ ) {
      $sum[$i] = $sum[$i]+$data_matrix[$i][$j];
      $pow_2_sum[$i] += $data_matrix[$i][$j]*$data_matrix[$i][$j];
    }
    $std[$i] = sqrt( ( $n*$pow_2_sum[$i] - $sum[$i]*$sum[$i] ) / ($n*$n) );
  }
}

end std
# }}} std

# {{{ modelfit_post_fork_analyze

start modelfit_post_fork_analyze
      {
	my @modelfit_results = @{ $self -> results };
	
	ui -> print( category => 'cdd',
		     message => "Soon done" );
      }
end modelfit_post_fork_analyze

# }}} modelfit_post_fork_analyze

# {{{ modelfit_results

start modelfit_results
      {
	my @orig_models  = @{$self -> models};
	my @orig_raw_results = ();
	foreach my $orig_model ( @orig_models ) {
	  my $orig_output = $orig_model -> outputs -> [0];
	  push( @orig_raw_results, $orig_output -> $accessor );
	}
#	my @models  = @{$self -> prepared_models};
	my @outputs = @{$self -> results};
	
	my @raw_results = ();

	foreach my $mod ( @outputs ) {
	  my @raw_inner = ();
	  foreach my $output ( @{$mod -> {'subset_outputs'}} ) {
	    push( @raw_inner, $output -> $accessor );
	  }
	  push( @raw_results, \@raw_inner );
	}
	if ( $format eq 'relative' or $format eq 'relative_percent' ) {
	  @results = ();
	  for ( my $i = 0; $i <= $#orig_raw_results; $i++ ) {
	    print "Model\t$i\n";
	    my @rel_subset = ();
	    for ( my $i2 = 0; $i2 < scalar @{$raw_results[$i]}; $i2++ ) {
	      print "Subset Model\t$i2\n";
	      my @rel_prob = ();
	      for ( my $j = 0; $j < scalar @{$orig_raw_results[$i]}; $j++ ) {
		print "Problem\t$j\n";
		if( ref( $orig_raw_results[$i][$j] ) eq 'ARRAY' ) {
		  my @rel_subprob = ();
		  for ( my $k = 0; $k < scalar @{$orig_raw_results[$i][$j]}; $k++ ) {
		    print "Subprob\t$k\n";
		    if( ref( $orig_raw_results[$i][$j][$k] ) eq 'ARRAY' ) {
		      my @rel_instance = ();
		      for ( my $l = 0; $l < scalar @{$orig_raw_results[$i][$j][$k]}; $l++ ) {
			print "Instance\t$l\n";
			my $orig = $orig_raw_results[$i][$j][$k][$l];
			my $res  = $raw_results[$i][$i2][$j][$k][$l];
			if( defined $orig and ! $orig == 0 ) {
			  print "ORIGINAL $orig\n";
			  print "SUBSET   $res\n";
			  print "RELATIVE ",$res/$orig,"\n";
			  if ( $format eq 'relative_percent' ) {
			    push( @rel_instance, ($res/$orig-1)*100 );
			  } else {
			    push( @rel_instance, $res/$orig );
			  }
			} else {
			  push( @rel_instance, 'NA' );
			}
			push( @rel_subprob,\@rel_instance );
		      }
		    } elsif( ref( $orig_raw_results[$i][$j][$k] ) eq 'SCALAR' ) {
		      print "One instance per problem\n";
		      my $orig = $orig_raw_results[$i][$j][$k];
		      my $res  = $raw_results[$i][$i2][$j][$k];
		      if( defined $orig and ! $orig == 0 ) {
			print "ORIGINAL $orig\n";
			print "SUBSET   $res\n";
			print "RELATIVE ",$res/$orig,"\n";
			if ( $format eq 'relative_percent' ) {
			  push( @rel_subprob, ($res/$orig-1)*100 );
			} else {
			  push( @rel_subprob, $res/$orig );
			}
		      } else {
			push( @rel_subprob, 'NA' );
		      }
		    } else {
		      print "WARNING: tool::cdd -> modelfit_results: neither\n\t".
			"array or scalar reference found at layer 4 in result data\n\t".
			  "structure (found ",ref( $orig_raw_results[$i][$j][$k] ),")\n";
		    }
		  }
		  push( @rel_prob, \@rel_subprob );
		} elsif( ref( $orig_raw_results[$i][$j] ) eq 'SCALAR' ) {
		  print "One instance per problem\n";
		  my $orig = $orig_raw_results[$i][$j];
		  my $res  = $raw_results[$i][$i2][$j];
		  if( defined $orig and ! $orig == 0 ) {
		    print "ORIGINAL $orig\n";
		    print "SUBSET   $res\n";
		    print "RELATIVE ",$res/$orig,"\n";
		    if ( $format eq 'relative_percent' ) {
		      push( @rel_prob, ($res/$orig-1)*100 );
		    } else {
		      push( @rel_prob, $res/$orig );
		    }
		  } else {
		    push( @rel_prob, 'NA' );
		  }
		} else {
		  print "WARNING: tool::cdd -> modelfit_results: neither\n\t".
		    "array or scalar reference found at layer 3 in result data\n\t".
		      "structure (found ",ref( $orig_raw_results[$i][$j] ),")\n";
		}
	      }
	      push( @rel_subset, \@rel_prob );
	    }
	    push( @results, \@rel_subset );
	  }
	} else {
	  @results = @raw_results;
	}
      }
end modelfit_results

# }}} modelfit_results

# {{{ relative_estimates

start relative_estimates
      {
	my $accessor = $parameter.'s';
	my @params = $self -> $accessor;

# 	print "Parameter: $parameter\n";
# 	sub process_inner_results {
# 	  my $res_ref = shift;
# 	  my $pad     = shift;
# 	  $pad++;
# 	  foreach my $res ( @{$res_ref} ) {
# 	    if ( ref ( $res ) eq 'ARRAY' ) {
# 	      process_inner_results( $res, $pad );
# 	    } else {
# 	      print "RELEST $pad\t$res\n";
# 	    }
# 	  }
# 	}
# 	process_inner_results( \@params, 0 );

	my @orig_params = $self -> $accessor( original_models => 1 );
	#                       [?][model][prob][subp][#]
	# print "ORIG TH1: ",$orig_params[0][0][0][0][0],"\n";
	for ( my $i = 0; $i < scalar @params; $i++ ) {
	  # Loop over models
	  my @mod = ();
	  for ( my $j = 0; $j < scalar @{$params[$i]}; $j++ ) {
	    # Loop over data sets
	    my @prep = ();
	    for ( my $k = 1; $k < scalar @{$params[$i]->[$j]}; $k++ ) {
	      # Loop over problems (sort of, at least)
	      my @prob = ();
	      for ( my $l = 0; $l < scalar @{$params[$i]->[$j]->[$k]}; $l++ ) {
		# Loop over sub problems (sort of, at least)
		my @sub = ();
		for ( my $m = 0; $m < scalar @{$params[$i]->[$j]->[$k]->[$l]}; $m++ ) {
		  # Loop over the params
		  my @par = ();
		  for ( my $n = 0; $n < scalar @{$params[$i][$j][$k][$l][$m]}; $n++ ) {
		    my $orig = $orig_params[$i][$j][$l][$m][$n];
#		    my $orig = $params[$i][$j][0][$l][$m][$n];
		    my $prep = $params[$i][$j][$k][$l][$m][$n];
		    if ( $orig != 0 ) {
		      if ( $percentage ) {
			push( @par, ($prep/$orig*100)-100 );
		      } else {
			push( @par, $prep/$orig );
		      }
		    } else {
		      push( @par, $PsN::out_miss_data );
		    }
		  }
		  push( @sub, \@par );
		}
		push( @prob, \@sub );
	      }
	      push( @prep, \@prob );
	    }
	    push( @mod, \@prep );
	  }
	  push( @relative_estimates, \@mod );
	}
      }
end relative_estimates

# }}} relative_estimates

# {{{ relative_confidence_limits

start relative_confidence_limits
      {
	my @params = @{$self -> confidence_limits( class     => 'tool::llp',
						   parameter => $parameter )};
	for ( my $i = 0; $i < scalar @params; $i++ ) {
	  # Loop over models
	  my @mod = ();
	  for ( my $j = 1; $j < scalar @{$params[$i]}; $j++ ) {
	    # Loop over data sets
	    my %num_lim;
	    my @nums = sort {$a <=> $b} keys %{$params[$i][$j]};
	    foreach my $num ( @nums ) {
	      my @prob_lim = ();
	      for ( my $n = 0; $n < scalar @{$params[$i][$j]->{$num}}; $n++ ) {
		my @side_lim = ();
		for ( my $o = 0; $o < scalar @{$params[$i][$j]->{$num}->[$n]}; $o++ ) {
		  # OBS: the [0] in the $j position points at the first element i.e
		  # the results of the tool run on the original model 
		  my $orig = $params[$i][0]->{$num}->[$n][$o];
		  my $prep = $params[$i][$j]->{$num}->[$n][$o];
		  print "ORIG: $orig, PREP: $prep\n";
		  if ( $orig != 0 ) {
		    if ( $percentage ) {
		      push( @side_lim, ($prep/$orig*100)-100 );
		    } else {
		      push( @side_lim, $prep/$orig );
		    }
		  } else {
		    push( @side_lim, $PsN::out_miss_data );
		  }
		}
		push( @prob_lim, \@side_lim );
	      }
	      $num_lim{$num} = \@prob_lim;
	    }
	    push( @mod, \%num_lim );
	  }
	  push( @relative_limits, \@mod );
	}
      }
end relative_confidence_limits

# }}} relative_confidence_limits


# {{{ prepare_results

start prepare_results
{
  if ( not defined $self -> raw_results ) {
    $self -> read_raw_results();
  }
}
end prepare_results

# }}}


# {{{ update_raw_results

start update_raw_results
    {
      my $cook_scores;
      my $cov_ratios;
      my $outside_n_sd;

      
      my ($dir,$file) =
	  OSspecific::absolute_path( $self -> directory,
				     $self -> raw_results_file->[$model_number-1] );
      open( RRES, $dir.$file );
      my @rres = <RRES>;
      close( RRES );
      open( RRES, '>',$dir.$file );

      chomp( $rres[0] );
      print RRES $rres[0] . ",cook.scores,cov.ratios,outside.n.sd\n";
      chomp( $rres[1] );
      my @tmp = split(',',$rres[1]);
      my $cols = scalar(@tmp);
      print RRES $rres[1] . ",0,1,0\n";


      foreach my $mod (sort({$a <=> $b} keys %{$self->raw_line_structure})){
	$self->raw_line_structure -> {$mod}->{'cook.scores'} = $cols.',1';
	$self->raw_line_structure -> {$mod}->{'cov.ratios'} = ($cols+1).',1';
	$self->raw_line_structure -> {$mod}->{'outside.n.sd'} = ($cols+2).',1';
      }

      $self->raw_line_structure -> write( $dir.'raw_results_structure' );


      my @new_rres;
      for( my $i = 2 ; $i <= $#rres; $i ++ ) {
	my $row_str = $rres[$i];
	chomp( $row_str );
	$row_str .= sprintf( ",%.5f,%.5f,%1f\n" ,
			     $self -> cook_scores -> [$i-2],
			     $self -> covariance_ratios -> [$i-2],
			     $self -> outside_n_sd -> [$i-2] );
	print RRES $row_str;
      }
      close( RRES );
    }
end update_raw_results

# }}} update_raw_results

# {{{ create_R_scripts
start create_R_scripts
    {
      unless( -e $PsN::lib_dir . '/R-scripts/cdd.R' ){
	croak('CDD R-script are not installed, no matlab scripts will be generated.' );
	return;
      }
      cp ( $PsN::lib_dir . '/R-scripts/cdd.R', $self -> directory );
    }
end create_R_scripts
# }}}
