package Owatter::Web;
use strict;
use warnings;
use utf8;
use parent qw/Owatter Amon2::Web/;
use File::Spec;

# dispatcher
use Owatter::Web::Dispatcher;

sub dispatch {
    return (
        Owatter::Web::Dispatcher->dispatch( $_[0] )
          or die "response is not generated"
    );
}

# load plugins
__PACKAGE__->load_plugins(

    #    'Web::FillInFormLite',
    #    'Web::JSON',
    '+Owatter::Web::Plugin::Session',
);

# setup view
use Owatter::Web::View;
{

    sub create_view {
        my $view = Owatter::Web::View->make_instance(__PACKAGE__);
        no warnings 'redefine';
        *Owatter::Web::create_view = sub { $view };    # Class cache.
        $view;
    }
}

# for your security
__PACKAGE__->add_trigger(
    AFTER_DISPATCH => sub {
        my ( $c, $res ) = @_;

# http://blogs.msdn.com/b/ie/archive/2008/07/02/ie8-security-part-v-comprehensive-protection.aspx
        $res->header( 'X-Content-Type-Options' => 'nosniff' );

        # http://blog.mozilla.com/security/2010/09/08/x-frame-options/
        $res->header( 'X-Frame-Options' => 'DENY' );

        # Cache control.
        $res->header( 'Cache-Control' => 'private' );
    },
);

__PACKAGE__->add_trigger(
    BEFORE_DISPATCH => sub {
        my ($c) = @_;

        my $user_id = $c->session->get('user_id');
        $c->debug( 'session user_id:%d', $user_id );
        return undef if ($user_id);

        if (   $c->req->path =~ m{^/$}
            || $c->req->path =~ m{^/login/$}
            || $c->req->path =~ m{^/login/update_session$}
            || $c->req->path =~ m{^/api/login/$}
            || $c->req->path =~ m{^/api/login/update_session$} )
        {
            return;
        }

        $c->debug( 'auth error:%s %s', $c->req->path, $c->req->content_type );

        if (
            $c->req->param('json')
            || (   $c->req->content_type
                && $c->req->content_type =~ m{application/json} )
          )
        {
            return $c->render_json( +{ error_code => 4 } );
        }
        else {
            return $c->res_404();
        }
    },
);

my %_ESCAPE = (
    '+' => '\\u002b',    # do not eval as UTF-7
    '<' => '\\u003c',    # do not eval as HTML
    '>' => '\\u003e',    # ditto.
);

sub render_json {
    my ( $c, $stuff ) = @_;

    # for IE7 JSON venularity.
    # see http://www.atmarkit.co.jp/fcoding/articles/webapp/05/webapp05a.html
    my $output = $c->json->encode($stuff);
    $output =~ s!([+<>])!$_ESCAPE{$1}!g;

    my $user_agent = $c->req->user_agent || '';

    # defense from JSON hijacking
    if (   ( !$c->request->header('X-Requested-With') )
        && $user_agent =~ /android/i
        && defined $c->req->header('Cookie')
        && ( $c->req->method || 'GET' ) eq 'GET' )
    {
        my $res = $c->create_response(403);
        $res->content_type('text/html; charset=utf-8');
        $res->content(
"Your request may be JSON hijacking.\nIf you are not an attacker, please add 'X-Requested-With' header to each request."
        );
        $res->content_length( length $res->content );
        return $res;
    }

    my $res = $c->create_response(200);

    my $encoding = $c->encoding();
    $encoding = lc( $encoding->mime_name ) if ref $encoding;
    $res->content_type("application/json; charset=$encoding");
    $res->header( 'X-Content-Type-Options' => 'nosniff' );    # defense from XSS
    $res->content_length( length($output) );
    $res->body($output);

    return $res;
}


1;
