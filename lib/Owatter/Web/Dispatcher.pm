package Owatter::Web::Dispatcher;
use strict;
use warnings;
use utf8;
use Amon2::Web::Dispatcher::RouterBoom;

use Module::Find qw(useall);

useall('Owatter::Web::C');

base 'Owatter::Web::C';

get '/'                      => 'Root#index';
post '/login/'               => 'Login#index';
post '/login/update_session' => 'Login#update_session';
post '/login/token'          => 'Login#token';

post '/data_sync' => 'Root#data_sync';

post '/tweet/'        => 'Tweet#index';
post '/tweet/thanks'  => 'Tweet#thanks';
post '/tweet/message' => 'Tweet#message';

get  '/api/twitter/login'    => 'Twitter#login';
get  '/api/twitter/callback' => 'Twitter#callback';

post '/api/login/'               => 'Login#index';
post '/api/login/update_session' => 'Login#update_session';
post '/api/login/token'          => 'Login#token';

post '/api/data_sync' => 'Root#data_sync';

post '/api/tweet/'        => 'Tweet#index';
post '/api/tweet/thanks'  => 'Tweet#thanks';
post '/api/tweet/message' => 'Tweet#message';

get '/api/preview' => 'Preview#index';

1;
