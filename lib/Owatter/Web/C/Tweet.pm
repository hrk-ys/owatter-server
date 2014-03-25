package Owatter::Web::C::Tweet;
use strict;
use warnings;
use utf8;

use Owatter::Model::User;

sub index {
    my ( $class, $c ) = @_;

    $c->debug('tweet');
    my $tweet_message = $c->req->param('tweet');
    my $reply_message = $c->req->param('reply');

    my $user_id = $c->session->get('user_id') or die;

    # validate

    my $error_message;
    if ( !$tweet_message || length($tweet_message) > 140 ) {
        $error_message = 'Owatterメッセージが不正です';
    }
    elsif ( !$reply_message || length($reply_message) > 140 ) {
        $error_message = 'Otsukareメッセージが不正です';
    }
    if ($error_message) {
        return $c->render_json( +{ error_message => $error_message } );
    }

    my $db      = $c->db;
    my $user    = $db->single( 'user', +{ user_id => $user_id } );
    my $reply = $db->single(
        'reply',
        +{
            user_id  => +{ '!=' => $user_id },
            tweet_id => 0,
            sex_type => +{ '!=' => $user->sex_type },
        },
        +{ order_by => 'created_at' }
    );

    if ( !$reply ) {
        $reply = $db->single(
            'reply',
            +{
                user_id  => +{ '!=' => $user_id },
                tweet_id => 0,
            },
            +{ order_by => 'created_at' }
        );
    }

    $db->txn_begin;
    my $tweet = $db->insert(
        'tweet',
        +{
            user_id     => $user_id,
            content     => $tweet_message,
            message_num => 1,
            created_at  => time(),
        }
    );

    $db->fast_insert(
        'reply',
        +{
            user_id    => $user_id,
            tweet_id   => 0,
            sex_type   => $user->sex_type,
            content    => $reply_message,
            location   => \"GeomFromText('POINT(139.762573 35.720253)')",
            created_at => time,
            updated_at => time,
        }
    );

	my $message;
    if ($reply) {
        $reply->update(
            +{ tweet_id => $tweet->tweet_id, updated_at => time() } );

		 $message = $db->insert(
            'message',
            +{
                user_id    => $reply->user_id,
                tweet_id   => $tweet->tweet_id,
                content    => $reply->content,
                created_at => time,
            }
        );

    }

    $db->txn_commit;

    my $ret = +{ tweet => $tweet->{row_data} };
    Owatter::Model::User->add_user_info( $ret->{tweet} );
    if ($message) {
        $ret->{message} = $message->{row_data};
        Owatter::Model::User->add_user_info( $ret->{message} );
    }
    else {
        $ret->{message} = +{ content => _random_reply_message() };
    }

    return $c->render_json($ret);
}

sub _random_reply_message {
    my @messages = (
"おつかれさま!今日も一日がんばったね。帰りにアイス買っていいよ！",
        "疲れたね。まぁそんな日もあるよね。",
    );

    return $messages[ int rand(@messages) ];
}

sub thanks {
    my ( $class, $c ) = @_;

    $c->debug('thanks');
    my $tweet_id = $c->req->param('tweet_id');
    my $user_id = $c->session->get('user_id') or die;

    # validate
    my $db = $c->db;
    my $reply = $db->single( 'reply', +{ tweet_id => $tweet_id } );
    if ( !$reply ) {
    	$c->debug('not found reply');
	    my $ret = +{ message => +{ user_id => $user_id, 'content' => 'Thanks' } };
	    Owatter::Model::User->add_user_info( $ret->{message} );
	    return $c->render_json($ret);
        return $c->render_json(
            +{ error_message => '不正アクセスです(1)' } );
    }

    my $tweet =
      $db->single( 'tweet', +{ tweet_id => $tweet_id, user_id => $user_id } );
    if ( !$tweet ) {
        return $c->render_json(
            +{ error_message => '不正アクセスです(2)' } );
    }

    my $message;
    if ( $tweet->message_num == 1 ) {
        $db->txn_begin;
        $message = $db->insert(
            'message',
            +{
                user_id    => $user_id,
                tweet_id   => $tweet_id,
                content    => "Thanks",
                created_at => time,
            }
        );
        $db->update(
            'tweet',
            +{
                message_num => 2,
            },
            +{
                tweet_id => $tweet_id,
            }
        );

        $db->insert(
            'inbox',
            +{
                user_id   => $reply->user_id,
                tweet_id  => $tweet_id,
                updated_at => time
            }
        );
        $db->txn_commit;
    }
    else {
        $message = $db->single(
            'message',
            +{
                'tweet_id' => $tweet_id,
                'user_id'  => $user_id,
            },
            +{ order_by => 'created_at' },
        );
    }

    my $ret = +{ message => $message->{row_data} };
    Owatter::Model::User->add_user_info( $ret->{message} );
    return $c->render_json($ret);
}

sub message {
    my ( $class, $c ) = @_;

    $c->debug('message');
    my $tweet_id = $c->req->param('tweet_id');
	my $content  = $c->req->param('content');
    my $user_id = $c->session->get('user_id') or die;

    my $error_message;
    if ( !$content || length($content) > 140 ) {
        $error_message = 'メッセージが不正です';
    }
    if ($error_message) {
        return $c->render_json( +{ error_message => $error_message } );
    }


    # validate
    my $db = $c->db;
    my $tweet =
      $db->single( 'tweet', +{ tweet_id => $tweet_id } );
    if ( !$tweet ) {
        return $c->render_json(
            +{ error_message => '不正アクセスです(2)' } );
    }
	my $reply = $db->single('reply', +{ tweet_id => $tweet_id });
    if ( !$reply ) {
        return $c->render_json(
            +{ error_message => '不正アクセスです(3)' } );
    }

    my $message;
    if ( $tweet->message_num == 2  && $reply->user_id == $user_id
		|| $tweet->message_num == 3 && $tweet->user_id == $user_id
	 ) {
		my $target_user_id = $reply->user_id == $user_id ? $tweet->user_id : $reply->user_id;
        $db->txn_begin;
        $message = $db->insert(
            'message',
            +{
                user_id    => $user_id,
                tweet_id   => $tweet_id,
                content    => $content,
                created_at => time,
            }
        );
        $db->update(
            'tweet',
            +{
                message_num => \'message_num+1',,
            },
            +{
                tweet_id => $tweet_id,
            }
        );

        $db->insert(
            'inbox',
            +{
                user_id   => $target_user_id,
                tweet_id  => $tweet_id,
                updated_at => time
            }
        );
        $db->txn_commit;
    }
    else {
        $message = $db->single(
            'message',
            +{
                'tweet_id' => $tweet_id,
                'user_id'  => $user_id,
            },
            +{ order_by => 'created_at desc' },
        );
    }

    my $ret = +{ message => $message->{row_data} };
    Owatter::Model::User->add_user_info( $ret->{message} );
    return $c->render_json($ret);
}

1;
