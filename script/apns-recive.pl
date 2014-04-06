#!/bin/perl

use strict;
use warnings;

use AnyEvent::APNS;
use AnyEvent::HTTPD;
use Encode;
use JSON::XS;
use Log::Minimal;

my $last_connect_at = 0;
my $last_send_at    = 0;
my @message_queue;

my $cv = AnyEvent->condvar;
my $apns;

_connect();

sub _connect {
    return if $apns;
    infof 'connect';
    $apns = AnyEvent::APNS->new(
        certificate => 'config/apns-dev.cer',
        private_key => 'config/apns-dev.key',
        sandbox     => 1,
        on_error    => sub {
            my ( $handle, $fatal, $message ) = @_;
            infof "apns connect error:$message";

            my $t;
            $t = AnyEvent->timer(
                after    => 0,
                interval => 10,
                cb       => sub {
                    undef $t;
                    $last_connect_at = time;
                    $apns->connect;
                },
            );
        },

        on_connect => sub {
            infof 'apns on_connect';

            if (@message_queue)
            {    #未送信メッセージがあれば送信する
                while ( my $q = shift @message_queue ) {
                    $apns->send(@$q);
                    $last_send_at = time;
                }
            }
        },
    );
	$apns->connect;
}

sub _send {
    my $q = shift;
    if ( $apns && $apns->connected ) {
        infof 'message send';
        $apns->send(@$q);
    }
    else {
        infof 'message queue';
        push @message_queue, $q;
        _connect();
    }
	$last_send_at = time;
}


my $httpd = AnyEvent::HTTPD->new( port => 9090 );

$httpd->reg_cb(
    '/' => sub {
        my ( $httpd, $req ) = @_;

        $req->respond(
            {
                content => [ 'application/json', '{"ok":1}', ]
            }
        );
    },
    '/send' => sub {
        my ( $httpd, $req ) = @_;

        my $token = $req->parm('token');
        my $alert = decode_utf8( $req->parm('alert') || 'notification' );

        my %params = map { $_ => $req->parm($_) } $req->params;
        $params{ok} = 1;
        my $body = JSON::XS->new->utf8->encode( \%params );

        _send( [ pack( "H*", $token ) => +{ aps => +{ alert => $alert } } ] );

        $req->respond(
            {
                content => [ 'application/json', $body ]
            }
        );
    },
);

my $t;
$t = AnyEvent->timer(
    after    => 60,
    interval => 60,
    cb       => sub {
        if ($apns) {
            if ( time - $last_send_at > 60 ) {
                eval { $apns = undef; };
                infof "[apns] close apns";
            }
        }

    },
);

$cv->recv;

