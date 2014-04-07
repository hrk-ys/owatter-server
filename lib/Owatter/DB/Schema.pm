package Owatter::DB::Schema;
use strict;
use warnings;
use Teng::Schema::Declare;
table {
    name 'device';
    pk 'user_id';
    columns (
        {name => 'user_id', type => 4},
        {name => 'token', type => 12},
        {name => 'is_debug', type => 4},
        {name => 'updated_at', type => 4},
    );
};

table {
    name 'inbox';
    pk 'tweet_id','user_id';
    columns (
        {name => 'user_id', type => 4},
        {name => 'tweet_id', type => 4},
        {name => 'updated_at', type => 4},
    );
};

table {
    name 'message';
    pk 'message_id';
    columns (
        {name => 'message_id', type => 4},
        {name => 'user_id', type => 4},
        {name => 'tweet_id', type => 4},
        {name => 'content', type => 12},
        {name => 'created_at', type => 4},
    );
};

table {
    name 'reply';
    pk 'reply_id';
    columns (
        {name => 'reply_id', type => 4},
        {name => 'tweet_id', type => 4},
        {name => 'user_id', type => 4},
        {name => 'sex_type', type => 1},
        {name => 'content', type => 12},
        {name => 'location', type => 12},
        {name => 'created_at', type => 4},
        {name => 'updated_at', type => 4},
    );
};

table {
    name 'tweet';
    pk 'tweet_id';
    columns (
        {name => 'tweet_id', type => 4},
        {name => 'user_id', type => 4},
        {name => 'content', type => 12},
        {name => 'created_at', type => 4},
        {name => 'message_num', type => 4},
    );
};

table {
    name 'user';
    pk 'user_id';
    columns (
        {name => 'user_id', type => 4},
        {name => 'name', type => 12},
        {name => 'login_hash', type => 12},
        {name => 'facebook_id', type => 4},
        {name => 'facebook_oauth_token', type => 12},
        {name => 'twitter_oauth_token', type => 12},
        {name => 'twitter_oauth_token_secret', type => 12},
        {name => 'sex_type', type => 1},
        {name => 'created_at', type => 4},
    );
};


1;