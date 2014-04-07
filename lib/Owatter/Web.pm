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
    'Web::JSON',
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
            return $c->render_json(
                +{ error => 'auth error', error_code => 4 } );
        }
        else {
            return $c->res_404();
        }
    },
);

1;
