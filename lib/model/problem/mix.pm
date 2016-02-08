package model::problem::mix;

use Moose;
use MooseX::Params::Validate;

extends 'model::problem::code_record';
sub nspop
{
	my $self = shift;
	my $nspop;
	if ( defined $self->code ) {
		foreach my $line (@{$self->code}){
			if ( $line =~ /^\s*NSPOP\s*=\s*(\d+)/){
				$nspop = $1;
			}
		}
	}
	return $nspop;
}
no Moose;
__PACKAGE__->meta->make_immutable;
1;
