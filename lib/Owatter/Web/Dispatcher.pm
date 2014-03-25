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

post '/data_sync' => 'Root#data_sync';

post '/tweet/'        => 'Tweet#index';
post '/tweet/thanks'  => 'Tweet#thanks';
post '/tweet/message' => 'Tweet#message';

1;
