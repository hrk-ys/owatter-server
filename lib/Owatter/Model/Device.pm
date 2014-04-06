package Owatter::Model::Device;

use strict;
use warnings;
use utf8;

use WWW::Curl::Easy;
use Owatter;

sub notification {
    my ( $class, $user_id, $message, $opt ) = @_;

    my $db = $opt->{db} || Owatter->bootstrap->db;
    my $device = $db->single( 'device', +{ user_id => $user_id } );
    return if !$device;

    my $token = $device->token;

    my $curl = WWW::Curl::Easy->new;

    $curl->setopt( CURLOPT_HEADER, 1 );
    $curl->setopt( CURLOPT_URL,
        "http://localhost:9090/send?token=$token&alert=$message" );

    my $response_body;
    $curl->setopt( CURLOPT_WRITEDATA, \$response_body );

    # Starts the actual request
    my $retcode = $curl->perform;

	my $c = Owatter->bootstrap();
	$c->debug("retcode:$retcode");
	$c->debug("response:" . $response_body || '');
}

1;
