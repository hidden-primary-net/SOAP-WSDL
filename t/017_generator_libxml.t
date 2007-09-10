#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More;
use lib '../lib';
use SOAP::WSDL::SAX::WSDLHandler;
use SOAP::WSDL::SAX::MessageHandler;
use File::Path;
use File::Basename;

if (eval "require XML::LibXML") {
     plan tests => 18;
}
else {
    plan skip_all => "Cannot test without XML::LibXML";
}

my $path = dirname __FILE__;

my $filter = SOAP::WSDL::SAX::WSDLHandler->new();
my $parser = XML::LibXML->new();
$parser->set_handler( $filter );
$parser->parse_string( xml() );

my $wsdl;
ok( $wsdl = $filter->get_data() , "get object tree");

$wsdl->create({
  base_path => "$path/testlib",
  typemap_prefix => "Test::Typemap::",
  type_prefix => "Test::Type::",
  element_prefix => "Test::Element::",
  interface_prefix => "Test::Interface::",
});

eval "use lib '$path/testlib'";

use_ok qw(Test::Element::EnqueueMessage);
use_ok qw(Test::Type::TMessage);
use_ok qw(Test::Typemap::MessageGateway);

my $data = {
    MMessage => {
        MRecipientURI => 'anyURI',
        MSenderAddress => 'a string',
        MMessageContent => 'a string',
        MSubject => 'a string',
        MDeliveryReportRecipientURI => 'anyURI',
        MKeepalive => {
            MKeepaliveTimeout => 1234567,
            MKeepaliveErrorPolicy => ' ( suppress | report ) ',
        }
    }
};

ok Test::Element::EnqueueMessage->new( $data ) , '(generated) object constructor';

my $handler = SOAP::WSDL::SAX::MessageHandler->new({
    class_resolver => 'Test::Typemap::MessageGateway'
});
$parser->set_handler( $handler );

TODO: {
  local $TODO = 'support embedded atomic simpleType/complexType definitions';
  eval { $parser->parse_string( xml_message() ) };
  ok ( !$@, 'parse XML message into object tree');
};


SKIP: {
    eval "require Test::Pod";
    skip 'Cannot test generated POD without Test::POD' , 12 if $@;
    
    foreach my $module (Test::Pod::all_pod_files( "$path/testlib")) {
        Test::Pod::pod_file_ok( $module )
    }
}

# cleanup
rmtree "$path/testlib";

# print $wsdl->explain();

sub xml_message {
	return
q{<EnqueueMessage xmlns="http://www.example.org/MessageGateway2/">
	<MMessage>
		<MRecipientURI>anyURI</MRecipientURI>
		<MSenderAddress>a string</MSenderAddress>
		<MMessageContent>a string</MMessageContent>
		<MSubject>a string</MSubject>
		<MDeliveryReportRecipientURI>anyURI</MDeliveryReportRecipientURI>
		<MKeepalive>
			<MKeepaliveTimeout>1234567</MKeepaliveTimeout>
			<MKeepaliveErrorPolicy> ( suppress | report ) </MKeepaliveErrorPolicy>
		</MKeepalive>
	</MMessage>
</EnqueueMessage>
};

}

sub xml {
	return q{<?xml version="1.0" encoding="UTF-8"?>
<wsdl:definitions name="MessageGateway"
  targetNamespace="http://www.example.org/MessageGateway2/"
  xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/"
  xmlns:tns="http://www.example.org/MessageGateway2/"
  xmlns:xsd="http://www.w3.org/2001/XMLSchema"
  xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/">
  <wsdl:types>
    <xsd:schema xmlns:xsd="http://www.w3.org/2001/XMLSchema"
      targetNamespace="http://www.example.org/MessageGateway2/">

      <xsd:element name="EnqueueMessage" type="tns:TEnqueueMessage"
        xmlns:tns="http://www.example.org/MessageGateway2/">
        <xsd:annotation>
          <xsd:documentation>Enqueue message request element</xsd:documentation>
        </xsd:annotation>
      </xsd:element>

      <xsd:complexType name="TMessage">
        <xsd:annotation>
          <xsd:documentation>
            A type containing all elements of a message to enqueue.
          </xsd:documentation>
        </xsd:annotation>
        <xsd:sequence>
          <xsd:element name="MRecipientURI" type="xsd:anyURI" minOccurs="1"
            maxOccurs="1">
            <xsd:annotation>

              <xsd:documentation>
                The recipient in URI notaitions. Valid URI schemas are: mailto:, sms:,
                phone:. Not all URI schemas need to be implemented at the current
                implementation stage.
              </xsd:documentation>
            </xsd:annotation>
          </xsd:element>
          <xsd:element name="MSenderAddress" type="xsd:string" minOccurs="0"
            maxOccurs="1">
            <xsd:annotation>
              <xsd:documentation>
                E-Mail sender address. Ignored for all but mailto: recipient URIs.
              </xsd:documentation>

            </xsd:annotation>
          </xsd:element>
          <xsd:element name="MMessageContent" type="xsd:string" minOccurs="1"
            maxOccurs="1">
            <xsd:annotation>
              <xsd:documentation>Message Content.</xsd:documentation>
            </xsd:annotation>
          </xsd:element>
          <xsd:element name="MSubject" type="xsd:string" minOccurs="0" maxOccurs="1">

            <xsd:annotation>
              <xsd:documentation>
                Message Subject. Ignored for all but mailto: URIs
              </xsd:documentation>
            </xsd:annotation>
          </xsd:element>
          <xsd:element name="MDeliveryReportRecipientURI" type="xsd:anyURI" minOccurs="0"
            maxOccurs="1">
            <xsd:annotation>
              <xsd:documentation>

                URI to send a delivery report to. May be of one of the following schemes:
                mailto:, http:, https:. Reports to mailto: URIs are sent as plaintext,
                reports to http(s) URIs are sent as SOAP requests following the
                MessageGatewayClient service definition.
              </xsd:documentation>
            </xsd:annotation>
          </xsd:element>
          <xsd:element name="MKeepalive" type="tns:TKeepalive" minOccurs="0"
            maxOccurs="1">
            <xsd:annotation>
              <xsd:documentation>
                Container for keepalive information. May be missing.
              </xsd:documentation>
            </xsd:annotation>

          </xsd:element>
        </xsd:sequence>
      </xsd:complexType>

      <xsd:complexType name="TKeepalive">
        <xsd:annotation>
          <xsd:documentation>Type containing keeplive information.</xsd:documentation>
        </xsd:annotation>
        <xsd:sequence>

          <xsd:element name="MKeepaliveTimeout" type="xsd:double">
            <xsd:annotation>
              <xsd:documentation>
                Keepalive timeout. The keepalive timeout spezifies how long the sending of
                a message will be delayed waiting for keepalive updates. If a keepalive
                update is received during this period, the timeout will be reset. If not,
                the message will be sent after the timeout has expired.
              </xsd:documentation>
            </xsd:annotation>
          </xsd:element>
          <xsd:element name="MKeepaliveErrorPolicy" minOccurs="0" maxOccurs="1">
            <xsd:annotation>

              <xsd:documentation>
                Policy to comply to in case of system errors. Valid values are "suppress"
                and "report". If the policy is set to "suppress", keepalive messages will
                not be sent to their recipients in case of partial system failure, even if
                the keepalive has expired. This may result in "false negatives", i.e.
                messages may not be sent, even though their keepalive has expired. If the
                value is "report", keepalive messages will be sent from any cluster node.
                This may result in "false positive" alerts.
              </xsd:documentation>
            </xsd:annotation>
            <xsd:simpleType>
              <xsd:restriction base="xsd:string">
                <xsd:enumeration value="suppress"></xsd:enumeration>
                <xsd:enumeration value="report"></xsd:enumeration>
              </xsd:restriction>
            </xsd:simpleType>
          </xsd:element>
        </xsd:sequence>
      </xsd:complexType>

      <xsd:complexType name="TMessageID">
        <xsd:annotation>
          <xsd:documentation>Type containing a message ID.</xsd:documentation>
        </xsd:annotation>

        <xsd:sequence>
          <xsd:element name="MMessageID" type="xsd:string" minOccurs="1" maxOccurs="1"></xsd:element>
        </xsd:sequence>
      </xsd:complexType>

      <xsd:complexType name="TKeepliveMessage">
        <xsd:annotation>
          <xsd:documentation>
            Type containing all elements of a keppalive update / remove request.
          </xsd:documentation>
        </xsd:annotation>
        <xsd:sequence>
          <xsd:element name="MMessageID" type="xsd:string" minOccurs="1" maxOccurs="1">
            <xsd:annotation>
              <xsd:documentation>
                The ID for the message to update / remove
              </xsd:documentation>
            </xsd:annotation>
          </xsd:element>

          <xsd:element name="MAction" minOccurs="1" maxOccurs="1">
            <xsd:annotation>
              <xsd:documentation>
                The action to perform. Valid values are: "remove", "update". On "remove",
                the message with the ID specified will be removed from the queue, thus it
                will never be sent, even if it's timeout expires. On "update" the
                keepalive timeout of the corresponding message will be reset.
              </xsd:documentation>
            </xsd:annotation>
            <xsd:simpleType>
              <xsd:restriction base="xsd:string">
                <xsd:enumeration value="remove"></xsd:enumeration>
                <xsd:enumeration value="update"></xsd:enumeration>
              </xsd:restriction>
            </xsd:simpleType>
          </xsd:element>
        </xsd:sequence>
      </xsd:complexType>
      <xsd:element name="KeepaliveMessage" type="tns:TKeepaliveMessageRequest">
        <xsd:annotation>
          <xsd:documentation>Keepalive message request element</xsd:documentation>
        </xsd:annotation>
      </xsd:element>
      <xsd:element name="KeepaliveMessageResponse" type="tns:TMessageID">
        <xsd:annotation>
          <xsd:documentation>Response element for a keepalive request</xsd:documentation>
        </xsd:annotation>
      </xsd:element>
      <xsd:element name="EnqueueMessageResponse" type="tns:TMessageID">
        <xsd:annotation>
          <xsd:documentation>Enqueue message response element</xsd:documentation>
        </xsd:annotation>
      </xsd:element>


      <xsd:complexType name="TEnqueueMessage">
        <xsd:annotation>
          <xsd:documentation>
            A complex type containing one element: The message to enqueue.
          </xsd:documentation>
        </xsd:annotation>
        <xsd:sequence>
          <xsd:element name="MMessage" type="tns:TMessage">
            <xsd:annotation>
              <xsd:documentation>
                Element containing a message to enqueue.
              </xsd:documentation>
            </xsd:annotation>

          </xsd:element>
        </xsd:sequence>
      </xsd:complexType>


      <xsd:complexType name="TKeepaliveMessageRequest">
        <xsd:annotation>
          <xsd:documentation>
            A complex type containing one element: The keepalive message to process.
          </xsd:documentation>

        </xsd:annotation>
        <xsd:sequence>
          <xsd:element name="MKeepaliveMessage" type="tns:TKeepliveMessage">
            <xsd:annotation>
              <xsd:documentation>
                Element containing a keepalive message to process.
              </xsd:documentation>
            </xsd:annotation>
          </xsd:element>

        </xsd:sequence>
      </xsd:complexType>
    </xsd:schema>
  </wsdl:types>
  <wsdl:message name="EnqueueMessageRequest">
    <wsdl:part name="parameters" element="tns:EnqueueMessage">
      <wsdl:documentation>inputparameters for EnqueueMessag</wsdl:documentation>
    </wsdl:part>

  </wsdl:message>
  <wsdl:message name="EnqueueMessageResponse">
    <wsdl:part name="parameters" element="tns:EnqueueMessageResponse">
      <wsdl:documentation>outputparameters for EnqueueMessag</wsdl:documentation>
    </wsdl:part>
  </wsdl:message>
  <wsdl:message name="KeepaliveMessageRequest">
    <wsdl:part name="parameters" element="tns:KeepaliveMessage">

      <wsdl:documentation>input parameters for KeepaliveMessag</wsdl:documentation>
    </wsdl:part>
  </wsdl:message>
  <wsdl:message name="KeepaliveMessageResponse">
    <wsdl:part name="parameters" element="tns:KeepaliveMessageResponse">
      <wsdl:documentation>output parameters for KeepaliveMessag</wsdl:documentation>
    </wsdl:part>
  </wsdl:message>

  <wsdl:portType name="MGWPortType">
    <wsdl:documentation>
      generic port type for all methods required for sending messages over the mosaic
      message gatewa
    </wsdl:documentation>
    <wsdl:operation name="EnqueueMessage">
      <wsdl:documentation>
        This method is used to enqueue a normal (immediate send) or a delayed message with
        keepalive functionality.
      </wsdl:documentation>
      <wsdl:input message="tns:EnqueueMessageRequest"></wsdl:input>
      <wsdl:output message="tns:EnqueueMessageResponse"></wsdl:output>

    </wsdl:operation>
    <wsdl:operation name="KeepaliveMessage">
      <wsdl:documentation>
        This method is used to update or remove a
        keepalive message.
      </wsdl:documentation>
      <wsdl:input message="tns:KeepaliveMessageRequest"></wsdl:input>
      <wsdl:output message="tns:KeepaliveMessageResponse"></wsdl:output>
    </wsdl:operation>
  </wsdl:portType>

  <wsdl:binding name="MGWBinding" type="tns:MGWPortType">
    <wsdl:documentation>Generic binding for all (SOAP) port</wsdl:documentation>
    <soap:binding style="document" transport="http://schemas.xmlsoap.org/soap/http" />
    <wsdl:operation name="EnqueueMessage">
      <soap:operation soapAction="http://www.example.org/MessageGateway2/EnqueueMessage" />
      <wsdl:input>
        <soap:body use="literal" />
      </wsdl:input>
      <wsdl:output>
        <soap:body use="literal" />
      </wsdl:output>
    </wsdl:operation>
    <wsdl:operation name="KeepaliveMessage">
      <soap:operation
        soapAction="http://www.example.org/MessageGateway2/KeepaliveMessage" />
      <wsdl:input>
        <soap:body use="literal" />
      </wsdl:input>

      <wsdl:output>
        <soap:body use="literal" />
      </wsdl:output>
    </wsdl:operation>
  </wsdl:binding>
  <wsdl:service name="MessageGateway">
    <wsdl:documentation>
      Web Service for sending messages over the message gatewa
    </wsdl:documentation>

    <wsdl:port name="HTTPPort" binding="tns:MGWBinding">
      <wsdl:documentation>HTTP(S) port for the message gateway</wsdl:documentation>
      <soap:address location="https://www.example.org/MessageGateway/" />
    </wsdl:port>
  </wsdl:service>
</wsdl:definitions>};
}
