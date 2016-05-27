#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../../.."; #location of includes.pm
use includes; #file with paths to PsN packages


SKIP: {
    eval { require XML::LibXML };
    skip "XML::LibXML not installed",1 if $@;

    require so::soblock::taskinformation::message;

    my $msg = so::soblock::taskinformation::message->new(
        type => 'ERROR',
        Toolname => 'myTool',
        Name => 'myName',
        Content => 'TheContent',
        Severity => 3,
    );

    my $xml = $msg->xml();
    my $xml_string = $xml->toString();
    is ($xml_string, '<Message type="ERROR"><Toolname>myTool</Toolname><Name>myName</Name><Content>TheContent</Content><Severity>3</Severity></Message>', "Message");
}

done_testing();
