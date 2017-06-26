package tool::qa;

use strict;
use Moose;
use MooseX::Params::Validate;
use File::Copy 'cp';
use include_modules;
use log;
use model_transformations;
use utils::file;
use tool::modelfit;
use tool::resmod;
use tool::linearize;
use tool::frem;
use tool::cdd;
use tool::simeval;
use PsN;

extends 'tool';

has 'model' => ( is => 'rw', isa => 'model' );
has 'groups' => ( is => 'rw', isa => 'Int', default => 10 );       # The number of groups to use for quantiles in the time_varying model
has 'idv' => ( is => 'rw', isa => 'Str', default => 'TIME' );
has 'dv' => ( is => 'rw', isa => 'Str', default => 'CWRES' );
has 'dvid' => ( is => 'rw', isa => 'Str', default => 'DVID' );
has 'occ' => ( is => 'rw', isa => 'Str', default => 'OCC' );
has 'covariates' => ( is => 'rw', isa => 'Str' );       # A comma separated list of continuous covariate symbols
has 'categorical' => ( is => 'rw', isa => 'Str' );       # A comma separated list of categorical covariate symbols
has 'parameters' => ( is => 'rw', isa => 'Str' );       # A comma separated list of parameter symbols
has 'fo' => ( is => 'rw', isa => 'Bool', default => 0 );
has 'lst_file' => ( is => 'rw', isa => 'Str' );
has 'cmd_line' => ( is => 'rw', isa => 'Str' );         # Used as a work around for calling scm via system
has 'nointer' => ( is => 'rw', isa => 'Bool', default => 0 );

has 'resmod_idv_table' => ( is => 'rw', isa => 'Str' ); # The table used by resmod

sub BUILD
{
    my $self = shift;

	my $model = $self->models()->[0];
    $self->model($model);
}

sub modelfit_setup
{
	my $self = shift;
    my $model_copy = $self->model->copy(filename => $self->model->filename, directory => $self->model->directory, write_copy => 0, output_same_directory => 1);
    $model_copy->_write(filename => $self->directory . $self->model->filename);
    $model_copy->phi_file($self->model->get_phi_file());

	my $vers = $PsN::version;
	my $dev = $PsN::dev;

    print "*** Running linearize ***\n";
    my $linearized_model_name = $self->model->filename;
    $linearized_model_name =~ s/(\.[^.]+)$/_linbase.mod/;
    ui->category('linearize');

    my @table_columns = ( 'ID', $self->idv, 'CWRES', 'PRED', 'CIPREDI' );
    if ($model_copy->defined_variable(name => 'TAD')) {
        push @table_columns, 'TAD';
    }

    my $lst_file;
    if (defined $self->lst_file) {
        $lst_file = '../../../' . $self->lst_file;
    }

    # $model_copy->set_records(type => 'covariance', record_strings => [ "UNCONDITIONAL" ]);     # Might need this for FREM CIs
    # cov step execution in non-linear model (derivatives.mod) might take hours or days, just omit for now
    $model_copy->set_records(type => 'covariance', record_strings => [ "OMITTED" ]);

    my $old_nm_output = common_options::get_option('nm_output');    # Hack to set clean further down
    common_options::set_option('nm_output', 'phi,ext,cov,cor,coi');
    my $linearize = tool::linearize->new(
        %{common_options::restore_options(@common_options::tool_options)},
        models => [ $model_copy ],
        directory => 'linearize_run',
        estimate_fo => $self->fo,
        extra_table_columns => \@table_columns,
        lst_file => $lst_file,
        nointer => $self->nointer,
        keep_covariance => 1,
        nm_output => 'phi,ext,cov,cor,coi',
    );

    $linearize->run();
    $linearize->print_results();
    ui->category('qa');

    common_options::set_option('nm_output', $old_nm_output);

    my $linearized_model = model->new(
        filename => $linearized_model_name,
    );

    #if ($self->fo) {
    #    $linearized_model->remove_option(record_name => 'estimation', option_name => 'METHOD');
    #    $linearized_model->_write();
    #}

    print "*** Running full omega block, add etas and boxcox model ***\n";
    eval {
        my @models;
        my $full_block_model = $linearized_model->copy(filename => "fullblock.mod");
        my $was_full_block = model_transformations::full_omega_block(model => $full_block_model);
        if ($was_full_block) {
            unlink("fullblock.mod");        # Why was this created in the first place?
        } else {
            $full_block_model->_write();
            push @models, $full_block_model;
        }
        my $boxcox_model = $linearized_model->copy(filename => "boxcox.mod");
        model_transformations::boxcox_etas(model => $boxcox_model);
        $boxcox_model->_write();
        push @models, $boxcox_model;
        my $add_etas_model = $linearized_model->copy(filename => "add_etas.mod");
        my $was_added = $add_etas_model->unfix_omega_0_fix();
        if ($was_added) {
            $add_etas_model->_write();
            push @models, $add_etas_model;
        } else {
            unlink("add_etas.mod");
        }
        my $modelfit = tool::modelfit->new(
            %{common_options::restore_options(@common_options::tool_options)},
            models => \@models,
            directory => 'modelfit_run',
            top_tool => 1,
        );
        $modelfit->run();
    };
    $self->_to_qa_dir();

    if (defined $self->covariates or defined $self->categorical) {
        print "\n*** Running FREM ***\n";
        my $frem_model = model->new(filename => $linearized_model_name);
        my @covariates;
        if (defined $self->covariates) {
            @covariates = split(',', $self->covariates);
        }
        my @categorical;
        if (defined $self->categorical) {
            @categorical = split(',', $self->categorical);
        }

        my $old_clean = common_options::get_option('clean');    # Hack to set clean further down
        common_options::set_option('clean', 1);
        eval {
            my $frem = tool::frem->new(
                %{common_options::restore_options(@common_options::tool_options)},
                models => [ $frem_model ],
                covariates => [ @covariates, @categorical ],
                categorical => [ @categorical ],
                directory => 'frem_run',
                rescale => 1,
                run_sir => 1,
                rplots => 1,
                top_tool => 1,
                clean => 1,
            );
            $frem->run();
            $frem->print_options(   # To get skip_omegas over to postfrem
                toolname => 'frem',
                local_options => [ 'skip_omegas' ],
                #common_options => \@common_options::tool_options
            );
        };
        common_options::set_option('clean', $old_clean);


        $self->_to_qa_dir();
        if (-d "frem_run") {
            print "\n*** Running POSTFREM ***\n";
            eval {
				if ($dev) {
					system("postfrem -frem_directory=frem_run -directory=postfrem_run -force_posdef_covmatrix");
				} else {
					system("postfrem-".$vers." -force_posdef_covmatrix -frem_directory=frem_run -directory=postfrem_run");
				}
            };
        }
        $self->_to_qa_dir();

        if (defined $self->parameters) {
            print "\n*** Running scm ***\n";
            my $scm_model = $self->model->copy(filename => "m1/scm.mod");
            if ($self->model->is_run()) {
                cp($self->model->outputs->[0]->full_name(), 'm1/scm.lst');
            }
            model_transformations::add_tv(model => $scm_model, parameters => [split /,/, $self->parameters]);
            $scm_model->_write();
            $self->_create_scm_config(model_name => "m1/scm.mod");
            my %tool_options = %{common_options::restore_options(@common_options::tool_options)};
            my $scm_options = "";
            for my $cmd (split /\s+/, $self->cmd_line) {
                if ($cmd =~ /^--?/) {
                    my $option = $cmd;
                    $option =~ s/^--?(no-)?(.*)/$2/;
                    $option =~ s/=(.*)//;
                    if (grep { $_ eq $option } @common_options::tool_options) {
                        $scm_options .= " $cmd";
                    }
                }
            }
            my $fo = "";
            if ($self->fo) {
                $fo = "-estimate_fo";
            }
            my $nointer = "";
            if ($self->nointer) {
                $nointer = "-nointer";
            }

            eval {
				if($dev) {
					system("scm config.scm $scm_options $fo $nointer");       # FIXME: system for now
				} else {
					system("scm-".$vers." config.scm $scm_options $fo $nointer");       # FIXME: system for now
				}
            };
            $self->_to_qa_dir();
        }
    }
    print "\n*** Running cdd ***\n";
    my $cdd_model = model->new(filename => $linearized_model_name);
    eval {
        my $cdd = tool::cdd->new(
            %{common_options::restore_options(@common_options::tool_options)},
            models => [ $cdd_model ],
            directory => 'cdd_run',
            rplots => 1,
            etas => 1,
            top_tool => 1,
        );
        $cdd->run();
    };
    $self->_to_qa_dir();

    print "\n*** Running simeval ***\n";
    my $simeval_model = $linearized_model->copy(filename => "m1/simeval.mod");
    $simeval_model->remove_records(type => 'etas');
    $simeval_model->remove_option(record_name => 'estimation', option_name => 'MCETA');
    $simeval_model->_write();
    eval {
        my $simeval = tool::simeval->new(
            %{common_options::restore_options(@common_options::tool_options)},
            models => [ $simeval_model ],
            rplots => 1,
            n_simulation_models => 5,
            directory => "simeval_run",
            top_tool => 1,
        );
        $simeval->run();
    };
    $self->_to_qa_dir();

    print "*** Running resmod ***\n";
    my $resmod_model = model->new(filename => 'linearize_run/scm_dir1/derivatives.mod');

    my $resmod_idv;
    eval {
        $resmod_idv = tool::resmod->new(
            %{common_options::restore_options(@common_options::tool_options)},
            models => [ $resmod_model ],
            dvid => $self->dvid,
            idv => $self->idv,
            dv => $self->dv,
            occ => $self->occ,
            groups => $self->groups,
            iterative => 0,
            directory => 'resmod_'.$self->idv,
            top_tool => 1,
        );
        $self->resmod_idv_table($resmod_idv->table_file);
    };
    if (not $@) {
        eval {
            $resmod_idv->run();
        };
    } else {
        rmdir "resmod_".$self->idv;
    }

    $self->_to_qa_dir();

    my $resmod_tad;
    eval {
        $resmod_tad = tool::resmod->new(
            %{common_options::restore_options(@common_options::tool_options)},
            models => [ $resmod_model ],
            dvid => $self->dvid,
            idv => 'TAD',
            dv => $self->dv,
            occ => $self->occ,
            groups => $self->groups,
            iterative => 0,
            directory => 'resmod_TAD',
            top_tool => 1,
        );
    };
    if (not $@) {
        eval {
            $resmod_tad->run();
        };
    } else {
        rmdir 'resmod_TAD';
    }
    $self->_to_qa_dir();

    my $resmod_pred;
    eval {
        $resmod_pred = tool::resmod->new(
            %{common_options::restore_options(@common_options::tool_options)},
            models => [ $resmod_model ],
            dvid => $self->dvid,
            idv => 'PRED',
            dv => $self->dv,
            occ => $self->occ,
            groups => $self->groups,
            iterative => 0,
            directory => 'resmod_PRED',
            top_rool => 1,
            clean => 0,         # Should not be need as top_tool is 1, but top_tool gets reset somehow for this run
        );
    };
    if (not $@) {
        eval {
            $resmod_pred->run();
        };
    } else {
        rmdir 'resmod_PRED';
    }
    $self->_to_qa_dir();
}

sub modelfit_analyze
{
    my $self = shift;
}

sub _create_scm_config
{
    my $self = shift;
	my %parm = validated_hash(\@_,
        model_name => { isa => 'Str' }
    );
	my $model_name = $parm{'model_name'};

    open my $fh, '>', 'config.scm';

    #my $model_name = $self->model->full_name();

    my $covariates = "";
    if (defined $self->covariates) {
        $covariates = "continuous_covariates=" . $self->covariates;
    }

    my $categorical = "";
    if (defined $self->categorical) {
        $categorical = "categorical_covariates=" . $self->categorical;
    }

    my $all = "";
    if (defined $self->categorical and not defined $self->covariates) {
        $all = $self->categorical;
    } elsif (not defined $self->categorical and defined $self->covariates) {
        $all = $self->covariates;
    } else {
        $all = $self->covariates . ',' . $self->categorical;
    }

    my $relations;
    for my $param (split(',', $self->parameters)) {
        $relations .= "$param=" . $all . "\n";
    }

my $content = <<"END";
model=$model_name

directory=scm_run

search_direction=forward
linearize=1
foce=1

p_forward=0.05
max_steps=1
;p_backward=0.01

$covariates
$categorical

do_not_drop=$all


[test_relations]
$relations

[valid_states]
continuous = 1,4
categorical = 1,2
END
	print $fh $content;
    close $fh;
}

sub _to_qa_dir
{
    my $self = shift;

    chdir $self->directory;
}

sub create_R_plots_code
{
	my $self = shift;
	my %parm = validated_hash(\@_,
        rplot => { isa => 'rplots', optional => 0 }
    );
	my $rplot = $parm{'rplot'};

	$rplot->pdf_title('Quality assurance');

    my @covariates;
    if (defined $self->covariates) {
        @covariates = split(/,/, $self->covariates);
    }
    my @categorical;
    if (defined $self->categorical) {
        @categorical = split(/,/, $self->categorical);
    }
    my @parameters;
    if (defined $self->parameters) {
        @parameters = split(/,/, $self->parameters);
    }
	my $CWRES_table_path = $self->resmod_idv_table;
	$CWRES_table_path =~ s/\\/\//g;
    $rplot->add_preamble(
        code => [
            '# qa specific preamble',
			"groups <- " . $self->groups,
            "idv_name <- '" . $self->idv . "'",
            "covariates <- " . rplots::create_r_vector(array => \@covariates),
            "categorical <- " . rplots::create_r_vector(array => \@categorical),
            "parameters <- " . rplots::create_r_vector(array => \@parameters),
            "CWRES_table <- '" . $CWRES_table_path . "'",
			"cdd_dofv_cutoff <- 3.84 ",
			"cdd_max_rows <- 10",
			"type <- 'latex' # set to 'html' if want to create a html file "
        ]
    );
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
