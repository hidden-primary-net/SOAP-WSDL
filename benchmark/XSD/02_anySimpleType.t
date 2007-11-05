use strict;
use warnings;
use Benchmark;
use lib '../../lib';
use SOAP::WSDL::XSD::Typelib::Builtin::anySimpleType;

my $obj = SOAP::WSDL::XSD::Typelib::Builtin::anySimpleType->new();

timethese 10000, {
    'new' => sub { SOAP::WSDL::XSD::Typelib::Builtin::anySimpleType->new() },
    'new + params' => sub { SOAP::WSDL::XSD::Typelib::Builtin::anySimpleType->new({
        value => 'Teststring'
    }) },
    'set_FOO' => sub { $obj->set_value('Test') },
};

my $data;
timethese 1000000, {
    'set_FOO' => sub { $obj->set_value('Test') },
    'get_FOO' => sub { $data = $obj->get_value() },
};
