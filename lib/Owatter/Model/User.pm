package Owatter::Model::User;

use strict;
use warnings;
use utf8;

use Owatter;

sub add_user_info {
    my ( $class, $args, $opt ) = @_;

    $opt ||= +{};
    my $db = $opt->{db} || Owatter->bootstrap->db;
    my @list = ref $args eq 'HASH' ? ($args) : @$args;

    my @user_ids = map { $_->{user_id} } @list;

    my @rows = $db->search( 'user', +{ user_id => \@user_ids } );
    my %users;
    for my $row (@rows) {
        $users{ $row->user_id } = $row->{row_data};
    }

    for my $user (@list) {
        my $row = $users{ $user->{user_id} };
        next unless $row;

        $user->{name} = $row->{name};
        #$class->add_facebook_info( $user, $row->{facebook_id} );
        $user->{prof_image_path} = $row->{profile_image};
    }
}

sub add_facebook_info {
    my ( $class, $user, $facebook_id ) = @_;

    $user->{prof_image_path} =
      "https://graph.facebook.com/${facebook_id}/picture?width=100&height=100";
}

1;
