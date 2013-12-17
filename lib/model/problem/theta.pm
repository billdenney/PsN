package model::problem::theta;
#use Carp;
use include_modules;
use model::problem::record::theta_option;

use Moose;
use MooseX::Params::Validate;

extends 'model::problem::init_record';

sub _read_options
{
	my $self = shift;

      {
	$self->same(0);
	my @row = ();
	$self->comment([]);
	my $global_index= $self->n_previous_rows()+1;
	if ( defined $self->record_arr ) {
	  for ( @{$self->record_arr} ) {
	    chomp;
	    s/^\s+//;
	    s/\s+$//;
	    # get rid of $THETA
	    s/^\s*\$\w+//;
	    next unless( length($_) > 0 );

	    if ( /^\s*\;/ ) {
	      # This is a comment row
	      push( @{$self->comment}, $_."\n" );
	    } else {
	      # Make sure that the labels and units are in one string
	      s/\;\s+/\;/g;

	      # Get rid of unwanted spaces
	      s/\s*\,\s*/\,/g;
	      s/\s+FIX/FIX/g;
	      s/\s+\)/\)/g;
	      s/\(\s+/\(/g;
	      #if there is no space between ) and ( then add one
	      s/\)\(/\) \(/g;

	      # Split thetas and labels/units
	      my ( $line, $comment ) = split( ";", $_, 2 );
	      
	      if ($line =~ /\)(x\d+)/){
					croak("Model parsing error: PsN does not support ".$1." notation in " . '$THETA');
	      }

	      # commas are optional in ([low,] init [,up] [FIXED])
	      #if there are spaces inside parentheses, they need to be replaced
	      #by commas. Optional for NONMEM but necessary for PsN
	      #remove all spaces before closing parentheses
	      #any number then space should be replaced by match without space with,
	      $line =~ s/(\([0-9.\-+eE]+)\s+/$1,/g; #first space
	      $line =~ s/(\([0-9.\-+eE,]+)\s+/$1,/g; #second
	      # Split the theta string to see if we have more than one theta.
	      @row = split( " ",$line );
	      if ( $#row <=0 ) {
		# If we only have one theta, send the whole row to option
		#comment will be label/unit
		#FIXED are attached to init
		$self->options([]) unless defined $self->options;
		push( @{$self->options},
		      model::problem::record::theta_option ->
		      new ( option_string => $line.';'.$comment,
			    coordinate_string => 'THETA'.$global_index));
		$global_index++;
	      } else {
		# If we have more than one theta, send one theta at a time to option
		#add comment to global comment
		push( @{$self->comment}, ';'.$comment."\n" ) if ($comment =~ /[^\s]+/);
		$self->options([]) unless defined $self->options;
		for my $li ( @row ) {
		  push( @{$self->options},
			model::problem::record::theta_option ->
			new ( option_string => $li ,
			      coordinate_string => 'THETA'.$global_index));
		  $global_index++;
		}
	      }
	    }
	  }
	}
      }

}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
