package Redmine::Chan;

use warnings;
use strict;
our $VERSION = '0.01';

use Skype::Any;

use Redmine::Chan::API;
use Redmine::Chan::Recipe;

use Class::Accessor::Lite (
    rw => [ qw(
        skype_chats
        nick
        redmine_url
        redmine_api_key
        api
        recipe
        issue_fields
        status_commands
        custom_field_prefix
     ) ],
);

sub new {
    my $class = shift;
    my $self = bless {@_}, $class;
    $self->init;
    $self;
}

sub init {
    my $self = shift;
    my $skype = Skype::Any->new(
        name => 'Redmine::Chan',
    );

    my $api = Redmine::Chan::API->new;
    $api->base_url($self->redmine_url);
    $api->api_key($self->redmine_api_key);
    $api->issue_fields($self->issue_fields);
    $api->status_commands($self->status_commands);
    $api->custom_field_prefix($self->custom_field_prefix);
    $api->reload;
    $self->api($api);

    my $recipe = Redmine::Chan::Recipe->new(
        api   => $self->api,
        nick  => $self->nick,
        chats => $self->skype_chats,
    );
    $self->recipe($recipe);

    $skype->message_received(sub {
        my ($msg) = @_;

        my $chat = $msg->chat;
        my $status = $chat->status;
        if ($status eq 'DIALOG') {
            my $msg = $api->set_api_key($msg->from_handle, $msg->body);
            $chat->send_message($msg);
        } elsif ($status eq 'MULTI_SUBSCRIBED') {
            my $msg = $self->recipe->cook(
                skype => $skype,
                chat  => $msg->chatname,
                body  => $msg->body,
                who   => $msg->from_handle,
            );
            $chat->send_message($msg) if $msg;
        }
    });

    $self->{skype} = $skype;
}

sub cook {
    my $self = shift;
    $self->{skype}->run;
}

*run = \&cook;

1;

__END__

=head1 NAME

Redmine::Chan

=head1 SYNOPSIS

    use Redmine::Chan;
    my $minechan = Redmine::Chan->new(
        irc_server      => 'irc.example.com', # irc
        irc_port        => 6667,
        irc_password    => '',
        irc_channels    => {
            '#channel' => { # irc channel name
                key        => '', # irc channel key
                project_id => 1,  # redmine project id
                charset    => 'iso-2022-jp',
            },
        },
        redmine_url     => $redmine_url,
        redmine_api_key => $redmine_api_key,

        # optional config
        status_commands => {
            1 => [qw/hoge/], # change status command
        },
        custom_field_prefix => {
            1 => [qw(prefix)], # prefix to change custome field
        },
        issue_fields => [qw/subject/], # displayed issue fields
    );
    $minechan->cook;

=head1 AUTHOR

Yasuhiro Onishi  C<< <yasuhiro.onishi@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012, Yasuhiro Onishi C<< <yasuhiro.onishi@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

