package SOAP::WSDL::XSD::Typelib::Builtin::integer;
use strict;
use warnings;

# Speed up. Class::Std::new is slow - and we don't need it's functionality...
BEGIN {
    use Class::Std::Storable;
    use base qw(SOAP::WSDL::XSD::Typelib::Builtin::decimal);

    no warnings qw(redefine);
    no strict qw(refs);

    # Yes, I know it's ugly - but this is the fastest constructor to write 
    # for Class::Std-Style inside out objects..
    *{ __PACKAGE__ . '::new' } = sub {   
        my $self = bless \do { my $foo } , shift;
        if (@_) {
            $self->set_value( $_[0]->{ value } )
                if exists $_[0]->{ value }
        }
        return $self;
    };

};


sub as_num :NUMERIFY {
    return $_[0]->get_value();
}

Class::Std::initialize();       # make :NUMERIFY overloading serializable

1;

__END__

=pod

=head1 NAME

SOAP::WSDL::XSD::Typelib::Builtin::integer - integer objects

=head1 LICENSE

This file is part of SOAP-WSDL. You may distribute/modify it under 
the same terms as perl itself

=head1 AUTHOR

Martin Kutter E<lt>martin.kutter fen-net.deE<gt>

=cut