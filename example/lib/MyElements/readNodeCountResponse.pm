package MyElements::readNodeCountResponse;
use strict;
use warnings;

{ # BLOCK to scope variables

sub get_xmlns { 'http://www.fullerdata.com/FortuneCookie/FortuneCookie.asmx' }

__PACKAGE__->__set_name('readNodeCountResponse');
__PACKAGE__->__set_nillable();
__PACKAGE__->__set_minOccurs();
__PACKAGE__->__set_maxOccurs();
__PACKAGE__->__set_ref();

use base qw(
    SOAP::WSDL::XSD::Typelib::Element
    SOAP::WSDL::XSD::Typelib::ComplexType
);
use Class::Std::Fast::Storable constructor => 'none';
use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables

my %readNodeCountResult_of :ATTR(:get<readNodeCountResult>);

__PACKAGE__->_factory(
    [ qw(
        readNodeCountResult
    ) ],
    {
        readNodeCountResult => \%readNodeCountResult_of,
    },
    {
        readNodeCountResult => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
    }
);

} # end BLOCK







} # end of BLOCK
1;

# __END__

=pod

=head1 NAME

MyElements::readNodeCountResponse

=head1 DESCRIPTION

Perl data type class for the XML Schema defined element
readNodeCountResponse from the namespace http://www.fullerdata.com/FortuneCookie/FortuneCookie.asmx.

=head1 METHODS

=head2 new

 my $element = MyElements::readNodeCountResponse->new($data);

Constructor. The following data structure may be passed to new():

 {
   readNodeCountResult =>  $some_value, # int
 },

=head1 AUTHOR

Generated by SOAP::WSDL

=cut

