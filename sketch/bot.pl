#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Config::Pit;
use Redmine::Chan;
use utf8;

my $minechan = Redmine::Chan->new(%{pit_get('redmine', require => {
    redmine_url     => '',
    redmine_api_key => '',
})},
    skype_chats => {
        '#t.akiym/$akiym_bot;f8efe7736e507088' => {project_id => 1}
    },
    status_commands => {
        1 => [qw/new/], # 新規
        2 => [qw/ongoing doing/], # 進行中
        3 => [qw/レビューお願いします レビューおねがいします/], # レビュー待ち
        4 => [qw/レビューします/], # レビュー中
        7 => [qw/レビューしました/], # リリース待ち
        6 => [qw/done/], # 終了
    },
    custom_field_prefix => {
        2 => [qw(origin/)], # branch
    },
    issue_fields => [qw/subject assigned_to status 1/],
    nick => 'minechan',
);
$minechan->cook;
