#package - declare a separate global namespace 
package My::Protein;

#use - load a module, moose extension for object orientated programing
use Moose;
#moosex?
use MooseX::Params::Validate;
use My::Domain;
#carp?
use Carp qw/ croak /;

#sequence, is read only, is a string
has sequence => (
  is => 'ro',
  isa => 'Str',
);

#md5, is read only, is a string
has md5 => (
  is => 'ro',
  isa => 'Str',
);


#sequence length, is read only, is a number
has sequence_length => (
  is => 'ro',
  isa => 'Num',
);

#domains, is read only, is an array , Array reference is [My::Domain]
has domains => (
  traits => ['Array'],
  is => 'ro',
#arrayref?  
  isa => 'ArrayRef[My::Domain]',
  #handles: extra commands
  handles => {
    add_domain    => 'push',
    get_domain    => 'get',
    list_domains  => 'elements',
    count_domains => 'count',
    find_domain   => 'first',
  },
  
  #sub?
  default => sub { [] },
);

#subroutine for getting domain by id
sub get_domain_by_id {
  #@_?
  my ($self, $id) = @_;
  # find_domain?
  my ($domain) = $self->find_domain( sub { $_->domain_id eq $id } );
  return $domain;
}

sub list_all_domain_segments {
 #shift - remove the first element of an array, and return it 
  my $self = shift;
  my @segments;
  for my $dom ( $self->list_domains ) {
    push @segments, $dom->list_segments;
  }
  # order the segments by the start residue
  @segments = sort { $a->uni_start <=> $b->uni_start } @segments;
  return @segments;
}

sub list_largest_domain_segments {
  my $self = shift;
  my @segments;
  for my $dom ( $self->list_domains ) {
    push @segments, $dom->largest_segment;
  }
  # order the segments by the start residue
  @segments = sort { $a->uni_start <=> $b->uni_start } @segments;
  return @segments;
}

sub to_mda_string {
  my ($self, %params) = validated_hash( \@_,
    type => { isa => 'Str', default => 'largest_segment' },
  );

  my %get_mda_ids_lookup = (
    'largest_segment' => sub {
      my @mda_ids;
      for my $segment ( $self->list_largest_domain_segments ) {
        push @mda_ids, $segment->domain_id;
      }
      return @mda_ids;
    },
    'all_segments' => sub {
      my @mda_ids;
      my %segments_by_domain_id;
      my $domain_count;
      for my $segment ( $self->list_all_domain_segments ) {
        my $domain_id = $segment->domain_id;
        $segments_by_domain_id{ $domain_id }++;
        push @mda_ids, $segments_by_domain_id{ $domain_id }
      }
      my @order_of_domain_ids;
      for my $domain_id ( @order_of_domain_ids ) {
        my $domain = $segments_by_domain_id{ $domain_id };
        push @mda_ids, $domain;
      }
      return @mda_ids;

    }
  );

  my $mda_type = $params{type};
  my $get_mda_ids = $get_mda_ids_lookup{ $mda_type }
    or croak "! Error: string '$mda_type' is not a valid MDA id processor";

  my @mda_ids = $get_mda_ids->();
  my $mda = join( '__', @mda_ids );

  return $mda;
}

__PACKAGE__->meta->make_immutable;
1;
