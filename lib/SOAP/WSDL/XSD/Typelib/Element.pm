#!/usr/bin/perl
package SOAP::WSDL::XSD::Typelib::Element;
use strict;

our $VERSION = '2.00_24';

my %NAME;
my %NILLABLE;
my %REF;
my %MIN_OCCURS;
my %MAX_OCCURS;

# TODO replace by generated methods?
#
# Class data - remember, we're the base class for a class factory or for
# generated code...
# use BLOCK: for scoping
BLOCK: {
    my %method_lookup = (
        _name => \%NAME,
        _nillable => \%NILLABLE,
        _ref => \%REF,
        _minOccurs => \%MIN_OCCURS,
        _maxOccurs => \%MAX_OCCURS,
    );

    no strict qw(refs);
    while (my ($name, $value) = each %method_lookup ) {
        *{ "__set$name" } = sub {
            my $class = ref $_[0] || $_[0] or die "Cannot call __set$name without parameter";
            $value->{ $class } = $_[1];
        };
        *{ "__get$name" } = sub {
            my $class = ref $_[0] || $_[0] or die "Cannot call __get$name as function";
            return $value->{ $class };
        };
    }
};

# use $_[0] and $_[1] for speed.

sub start_tag {
    # my ($self, $opt, $value) = @_;
    my $ending = ($_[1]->{ empty }) ? '/>' : '>';
    my @attr_from = ();

    if ($_[1]->{ nil }) {
        return q{} if not $NILLABLE{ ref $_[0] };
        push @attr_from, 'xsi:nil="true"';
        $ending = '/>';
    }
    if ($_[1]->{qualified}) {
        push @attr_from, 'xmlns="' . $_[0]->get_xmlns . '"';
    }

    # do we need to check for name ? Element ref="" should have it's own
    # start_tag. If we don't need to check, we can speed things up
    return join q{ }, "<$_[1]->{ name }" , @attr_from , $ending if $_[1]->{ name };
    return join q{ }, "<$NAME{ ref $_[0]}" , @attr_from , $ending;
}

# use $_[0] and $_[1] for speed.
#
# read it as:
#
# my ($self, $opt)  = @_;
# my $class = ref $self;
# return "</$opt->{name}>" if $opt->{name};
# return "</"$NAME{$class}>";
#
# do we need to check for name ? Element ref="" should have it's own
# end_tag. If we don't need to check, we can speed things up by defining
# end tag with () prototype - perl will inline it for us if we do...
sub end_tag {
    return "</$_[1]->{name}>" if $_[1]->{name};
    return "</$NAME{ ref $_[0] }>";
}

1;

=pod

=head1 NAME

SOAP::WSDL::XSD::Typelib::Element - element base clase

=head1 SYNOPSIS

This example creates a class for this XML schema definition:

 <element name="MyElement" type="xsd:string" nillable="1"
   minOccurs="1" maxOccurs="1"/>

 package MyElement;
 use strict;
 use Class::Std::Storable;
 use base (
    'SOAP::WSDL::XSD::Typelib::Element',
    'SOAP::WSDL::XSD::Typelib::Builtin::string',
 );

 __PACKAGE__->__set_name('MyElementName');
 __PACKAGE__->__set_nillable(1);
 __PACKAGE__->__set_minOccurs(1);
 __PACKAGE__->__set_maxOccurs(1);
 __PACKAGE__->__set_ref(0);

Now we create this XML schema definition type class:

 <element name="MyElement2" ref="tns:MyElement"/>
 
 package MyElement2;
 use strict;
 use Class::Std::Storable;
 use base (
    'SOAP::WSDL::XSD::Typelib::Element',
    'MyElement'
 );

 __PACKAGE__->__set_name('MyElementName');
 __PACKAGE__->__set_nillable(0);
 __PACKAGE__->__set_ref(1);

=head1 NOTES

=over

=item * type="Foo"

Implemented via inheritance.

=item * ref="Foo"

Implemented via inheritance, too. Calling

__PACKAGE__->__set_ref(1) is highly encouraged, though it has no
effect yet - it will probably be needed for serialization to XML
Schema definitions some day.

=back

=head1 BUGS AND LIMITATIONS

=over

=item * minOccurs maxOccurs not implemented

These attributes are not yet supported, though they may be set as class
properties via __PACKAGE__->__set_FOO methods.

=item * 'http://www.w3.org/2001/XMLSchema-instance prefix is hardcoded

The prefix for 'http://www.w3.org/2001/XMLSchema-instance (used as namespace
for the {http://www.w3.org/2001/XMLSchema-instance}nil="true" attribute
is hardcoded as 'xsi'.

You should definitly provide your XML envelope generator with the same prefix
namespace combination (Default for SOAP::WSDL::Envelope).

=back

=cut
