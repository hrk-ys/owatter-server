package Owatter::Web::C::Root;
use strict;
use warnings;
use utf8;

sub index {
    my ( $class, $c ) = @_;

    my $counter = $c->session->get('counter') || 0;
    $counter++;
    $c->session->set( 'counter' => $counter );
    return $c->render(
        'index.tx',
        {
            counter => $counter,
        }
    );
}

sub data_sync {
    my ( $class, $c ) = @_;

	$c->debug('data_sync');
	my $db = $c->db;
    my $last_sync_time = $c->req->param('last_sync_time');
    my $user_id = $c->session->get('user_id') or die;
	$c->debug('user_id:%d', $user_id);

    my @rows = $db->search(
        'inbox',
        +{
            user_id      => $user_id,
            'updated_at' => +{ '>', $last_sync_time },
        },
        +{
            'order_by' => 'updated_at'
        }
    );

	my $update_time = 0;
    my @tweet_ids;
	my %tweetId2updated;
    for my $row (@rows) {
        push @tweet_ids, $row->tweet_id;
		$tweetId2updated{ $row->tweet_id} = $update_time = $row->updated_at;
    }

	$c->debug('tweet_ids : %s', \@tweet_ids);

	my @add_user_list;
    @rows = $db->search( 'tweet', +{ tweet_id => \@tweet_ids } );
    my %tweets;
    for my $row (@rows) {
        $tweets{ $row->tweet_id } = $row->{row_data};
		push @add_user_list, $tweets{ $row->tweet_id };
    }

	$c->debug('tweets : %s', \%tweets);

	my %messages;
	@rows = $db->search( 'message', +{ tweet_id => \@tweet_ids }, +{ order_by => 'created_at' });
	for my $row (@rows) {
		my $hash = $row->{row_data};
		push @{ $messages{ $hash->{tweet_id } } }, $hash;
		push @add_user_list, $hash;
	}

	$c->debug('messages : %s', \%messages);

	my $ret;
	for my $tweet_id ( @tweet_ids ) {
		my $tweet = $tweets{ $tweet_id };
		$tweet->{messages} = $messages{ $tweet_id };
		$tweet->{updated_at} = $tweetId2updated{ $tweet_id };
		push @{ $ret->{tweets} }, $tweet;

		if ($tweet->{user_id} == $user_id) {
			if ($tweet->{message_num} < 3 && $tweet->{messages}) {
				$tweet->{messages}[0]{user_id} = '0';
			}
		}
	}

	$ret->{last_sync_time} = $update_time;

	$c->debug('ret : %s', $ret);
	Owatter::Model::User->add_user_info( \@add_user_list );

	return $c->render_json( $ret) ;
}

1;
