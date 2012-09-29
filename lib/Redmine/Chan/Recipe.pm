package Redmine::Chan::Recipe;
use strict;
use warnings;

use Encode qw/decode encode/;

use Class::Accessor::Lite (
    new => 1,
    rw  => [ qw( api nick chats ) ],
);

sub cook {
    my ($self, %args) = @_;
    my $skype = $args{skype} or return;
    my $body  = $args{body} or return;
    my $who   = $args{who} or return;
    my $chat  = $self->chat($args{chat}) or return;
    my $api   = $self->api;
    my $nick  = $self->nick;
    $api->who($who);

    my $reply = '';

    if ($body =~ /^(users|trackers|projects|issue_statuses)$/) {
        # API サマリ
        my $method = $1 . '_summary';
        my $summary = $api->$method;
        $skype->chat($chat)->send_message($summary);
        return;
    }

    if ($body eq 'reload') {
        # 設定再読み込み
        $api->reload;
        $reply = 'reloaded';
    } elsif ($body eq '..') {
        # 上の行をissue登録
        $reply = $api->create_issue(delete $self->{buffer} || '', $chat->{project_id});
    } elsif ($body =~ /^\Q$nick\E:?\s+(.+)/) {
        # issue 登録
        $reply = $api->create_issue($1, $chat->{project_id});
    } elsif ($body =~ /^(.+?)\s*>\s*\#(\d+)$/) {
        # note 追加
        my ($note, $issue_id) = ($1, $2);
        $api->note_issue($issue_id, $note);
        $reply = $api->issue_detail($issue_id);
    } elsif ($body =~ /\#(\d+)/) {
        # issue 確認/update
        my $issue_id = $1;
        $api->update_issue($issue_id, $body);
        $reply = $api->issue_detail($issue_id);
    } else {
        # 何もしない
        # 1行バッファにためる
        $self->{buffer} = $body;
        return;
    }
    $reply or return;
    return $reply;
}

sub chat {
    my $self = shift;
    my $name = shift or return;
    my $chat = $self->chats->{$name};
    $chat->{name} = $name;
    return $chat;
}

1;
