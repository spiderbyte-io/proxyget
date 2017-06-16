#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use AnyEvent;
use AnyEvent::HTTP;
use List::MoreUtils qw(uniq);

my @blogs = qw(
    live-socks.net
    socks24.org
    socks5-proxy-list.blogspot.com
    sock5us.blogspot.com
    sockproxy.blogspot.com
    socksproxylist24.blogspot.com
    sslproxies24.blogspot.com
    vip-socks24.blogspot.com
);

my @posts;
my @proxies;

# loop 1
my $cv = AnyEvent->condvar;

foreach my $blog (@blogs) {
    $cv->begin;
    http_get "http://".$blog, sub {
        my ($body, $hdr) = @_;
        my @p = $body =~ /<h3 class='post-title entry-title' itemprop='name'>\n<a href='(.*?)'>.*?<\/a>\n<\/h3>/img;
        #
        # TODO: instead of pushing to @posts, do the foreach $post here
        #
        push @posts, $_ foreach @p;
        $cv->end;
    }
}
print $cv->recv;


# loop 2
$cv = AnyEvent->condvar;

foreach my $post (@posts) {
    $cv->begin;
    http_get $post, sub {
        my ($body, $hdr) = @_;
        my @matches = $body =~ /([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+)/mg;

        return warn "No proxies found on $post" unless @matches;

        push @proxies, @matches;
        $cv->end;
    };
}

print $cv->recv;

# save proxies to file
open my $fh, '>', "proxies.txt" or die "Cannot open proxies.txt: $!";
print $fh "$_\n" foreach uniq(@proxies);
close $fh;

print uniq(@proxies) . " proxies found";
