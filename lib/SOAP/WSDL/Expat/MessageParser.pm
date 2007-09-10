#!/usr/bin/perl
package SOAP::WSDL::Expat::MessageParser;
use strict;
use warnings;
use SOAP::WSDL::XSD::Typelib::Builtin;
use XML::Parser::Expat;

sub new {
    my ($class, $args) = @_;
    my $self = {
        class_resolver => $args->{ class_resolver },
    };
    bless $self, $class;
    return $self;
}

sub class_resolver {
    my $self = shift;
    $self->{ class_resolver } = shift;
}

sub _initialize {
    my ($self, $parser) = @_;

    delete $self->{ data };                     # remove potential old results
    
    my $characters;
    my $current = undef;
    my $ignore = [ 'Envelope', 'Body' ];        # top level elements to ignore
    my $list = [];                              # node list
    my $path = [];                              # current path 
    my $skip = 0;                               # skip elements

    # use "globals" for speed
    my ($_prefix, $_localname, $_element, $_method, 
        $_class, $_parser, %_attrs) = ();

    no strict qw(refs);     
    $parser->setHandlers(
        Start => sub {
            ($_parser, $_element, %_attrs) = @_;
            ($_prefix, $_localname) = split m{:}xms , $_element;

            $_localname ||= $_element;          # for non-prefixed elements          
            
            # ignore top level elements
            if (@{ $ignore } && $_localname eq $ignore->[0]) {
                CHECK_ENVELOPE: {
                    last CHECK_ENVELOPE if $_localname ne 'Envelope';
                    last CHECK_ENVELOPE if exists $_attrs{ 'xmlns' } 
                      && $_attrs{ 'xmlns' } eq 'http://schemas.xmlsoap.org/soap/envelope/';
                    last CHECK_ENVELOPE if $_attrs{ "xmlns:$_prefix"} 
                      eq 'http://schemas.xmlsoap.org/soap/envelope/';
                    die "Bad namespace for SOAP envelope: " . $parser->recognized_string();
                }
                shift @{ $ignore };
                return;
            }

            push @{ $path }, $_localname;       # step down in path
            return if $skip;                    # skip inside __SKIP__

            # resolve class of this element
            $_class = $self->{ class_resolver }->get_class( $path )
                or die "Cannot resolve class for "
                    . join('/', @{ $path }) . " via " . $self->{ class_resolver };

            # maybe write as "return $skip = join ... if (...)" ?
            # would save a BLOCK...
            return $skip = join('/', @{ $path }) if ($_class eq '__SKIP__');
             
            push @$list, $current;   # step down in tree ()remember current)
                
            $characters = q{};      # empty characters
   
            # Check whether we have a primitive - we implement them as classes
            # We could replace this with UNIVERSAL->isa() - but it's slow...
            # match is a bit faster if the string does not match, but WAY slower 
            # if $class matches...
                    
            if (index $_class, 'SOAP::WSDL::XSD::Typelib::Builtin', 0 < 0) {           
                # check wheter there is a non-empty ARRAY reference for $_class::ISA
                # or a "new" method
                # If not, require it - all classes required here MUST
                # define new()
                # This is not exactly the same as $class->can('new'), but it's way faster  
                defined *{ "$_class\::new" }{ CODE }
                  or scalar @{ *{ "$_class\::ISA" }{ ARRAY } }
                    or eval "require $_class"   ## no critic qw(ProhibitStringyEval)
                      or die $@;                        
            }
            
            $current = $_class->new({ %_attrs });   # set new current object
        
            # remember top level element
            exists $self->{ data } 
                or ($self->{ data } = $current); 
        },
        
        Char => sub {
            return if $skip;
            $characters .= $_[1];
        },
        
        End => sub {        
            $_element = $_[1];

            ($_prefix, $_localname) = split m{:}xms , $_element;          
            $_localname ||= $_element;          # for non-prefixed elements            

            pop @{ $path };                     # step up in path
       
            if ($skip) {
                return if $skip ne join '/', @{ $path }, $_localname;
                $skip = 0;
                return;
            }
      
            # This one easily handles ignores for us, too...
            return if not ref $$list[-1];
    
            # set characters in current if we are a simple type
            # we may have characters in complexTypes with simpleContent,
            # too - maybe we should rely on the presence of characters ?
            # may get a speedup by defining a ident method in anySimpleType 
            # and looking it up via exists &$class::ident;
            if ( $current->isa('SOAP::WSDL::XSD::Typelib::Builtin::anySimpleType') ) {
                $current->set_value( $characters );
            }
            # currently doesn't work, as anyType does not implement value - 
            # maybe change ?
#            $current->set_value( $characters ) if ($characters);
        
            # set appropriate attribute in last element
            # multiple values must be implemented in base class
            $_method = "add_$_localname";
            $$list[-1]->$_method( $current );
            
            $current = pop @$list;           # step up in object hierarchy...
        }
    );
    return $parser;
}

sub parse {
    $_[0]->_initialize( XML::Parser::Expat->new() )->parse( $_[1] );
    return $_[0]->{ data };     
}

sub parsefile {
    $_[0]->_initialize( XML::Parser::Expat->new() )->parsefile( $_[1] );
    return $_[0]->{ data };     
}

# SAX-like aliases
sub parse_string;
*parse_string = \&parse;

sub parse_file;
*parse_file = \&parsefile;

sub get_data {
    return $_[0]->{ data };
}

1;

=pod

=head1 NAME

SOAP::WSDL::Expat::MessageParser - Convert SOAP messages to custom object trees

=head1 SYNOPSIS

 my $parser = SOAP::WSDL::Expat::MessageParser->new({
    class_resolver => 'My::Resolver'   
 });
 $parser->parse( $xml );
 my $obj = $parser->get_data();

=head1 DESCRIPTION

Real fast expat based SOAP message parser.

See L<SOAP::WSDL::Parser> for details.

=head2 Skipping unwanted items

Sometimes there's unneccessary information transported in SOAP messages.

To skip XML nodes (including all child nodes), just edit the type map for 
the message and set the type map entry to '__SKIP__'. 

=head1 Bugs and Limitations

=over

=item * Ignores all namespaces

=item * Does not handle mixed content

=item * The SOAP header is ignored

=back

=head1 AUTHOR

Replace the whitespace by @ for E-Mail Address.

 Martin Kutter E<lt>martin.kutter fen-net.deE<gt>

=head1 COPYING

This module may be used under the same terms as perl itself.

=head1 Repository information

 $ID: $

 $LastChangedDate: 2007-09-10 18:19:23 +0200 (Mo, 10 Sep 2007) $
 $LastChangedRevision: 218 $
 $LastChangedBy: kutterma $

 $HeadURL: https://soap-wsdl.svn.sourceforge.net/svnroot/soap-wsdl/SOAP-WSDL/trunk/lib/SOAP/WSDL/Expat/MessageParser.pm $

