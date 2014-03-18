package Owatter::Web::C::Tweet;
use strict;
use warnings;
use utf8;

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
    my $message = $db->single(
        'reply',
        +{
            user_id  => +{ '!=' => $user_id },
            tweet_id => 0,
            sex_type => +{ '!=' => $user->sex_type },
        },
        +{ order_by => 'created_at' }
    );

    if ( !$message ) {
        $message = $db->single(
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
            user_id    => $user_id,
            content    => $tweet_message,
            created_at => time(),
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

	if ($message) {
    	$message->update( +{ tweet_id => $tweet->tweet_id, updated_at => time() } );
	}

    $db->txn_commit;

	my $ret = +{ tweet => $tweet->{row_data} };
	if ($message) {
		$ret->{message} = $message->{row_data};
	} else {
		$ret->{message} = +{ content => _random_reply_message() };
	}

    return $c->render_json($ret);
}

sub _random_reply_message {
	my @messages = (
		"おつかれさま!今日も一日がんばったね。帰りにアイス買っていいよ！",
		"疲れたね。まぁそんな日もあるよね。",
	);

	return $messages[int rand( @messages )];
}

1;
