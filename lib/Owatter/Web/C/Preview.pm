package Owatter::Web::C::Preview;
use strict;
use warnings;
use utf8;

sub index {
    my ( $class, $c ) = @_;

    my $hash_key = $c->req->param('h');
    my $db       = $c->db;
    my $tweet    = $db->single( 'tweet', +{ hash_key => $hash_key } );

    my $ret = {};

    if ($tweet) {
        my $tweet_data = $tweet->{row_data};
        $c->debug($tweet_data);
        my $message = $db->single(
            'message',
            +{ tweet_id => $tweet_data->{tweet_id} },
            +{ order_by => 'created_at' }
        );

        if ($message) {
            my $message_data = $message->{row_data};
            $message_data->{user_id} = 0;

            $tweet_data->{messages} = [$message_data];
        }

        Owatter::Model::User->add_user_info(
            [ $tweet_data, @{ $tweet_data->{messages} || [] } ] );

        $ret->{tweet} = $tweet_data;
    }

    return $c->render_json($ret);
}

1;
