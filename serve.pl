#!/usr/bin/perl
use strict;
use warnings;
use HTTP::Daemon;
use HTTP::Status;
use File::Basename;
use MIME::Base64;

my $root = $ARGV[0] || '.';
my $port = $ARGV[1] || 8080;

# MIME types
my %mime = (
    html  => 'text/html; charset=utf-8',
    htm   => 'text/html; charset=utf-8',
    css   => 'text/css',
    js    => 'application/javascript',
    jpg   => 'image/jpeg',
    jpeg  => 'image/jpeg',
    gif   => 'image/gif',
    png   => 'image/png',
    ico   => 'image/x-icon',
    svg   => 'image/svg+xml',
    mp3   => 'audio/mpeg',
    mp4   => 'video/mp4',
    txt   => 'text/plain',
    pdf   => 'application/pdf',
);

my $d = HTTP::Daemon->new(
    LocalPort => $port,
    ReuseAddr => 1,
) or die "Cannot start server on port $port: $!\n";

print "=" x 50 . "\n";
print "  ColinFirth.com local server running\n";
print "  URL: http://localhost:$port/\n";
print "  Root: $root\n";
print "  Press Ctrl+C to stop\n";
print "=" x 50 . "\n";

while (my $c = $d->accept) {
    while (my $r = $c->get_request) {
        my $path = $r->url->path;
        $path =~ s|[.][.]/||g;  # basic traversal protection
        $path = '/index.html' if $path eq '/';
        $path =~ s|/$|/index.html|;

        my $file = $root . $path;
        $file =~ s|/+|/|g;

        if (-f $file) {
            my ($ext) = $file =~ /\.([^.]+)$/;
            $ext = lc($ext // '');
            my $type = $mime{$ext} || 'application/octet-stream';

            open(my $fh, '<:raw', $file) or do {
                $c->send_error(RC_FORBIDDEN);
                next;
            };
            local $/;
            my $body = <$fh>;
            close $fh;

            my $res = HTTP::Response->new(RC_OK);
            $res->header('Content-Type'   => $type);
            $res->header('Content-Length' => length($body));
            $res->content($body);
            $c->send_response($res);
        } else {
            $c->send_error(RC_NOT_FOUND, "Not found: $path");
        }
    }
    $c->close;
}
