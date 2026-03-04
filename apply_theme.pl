#!/usr/bin/perl
use strict;
use warnings;
use File::Find;

my $base = $ARGV[0] || 'C:/Users/walhu/websites/firth.com';
my $fixed = 0;
my $skipped = 0;

# Skip these — already converted or not content pages
my %skip = map { $_ => 1 } qw(
    index.html comingsoon.html films.html lockerbie.html upcoming.html
    news.html mincemeat.html staircase.html 1917.html bjbaby.html
    ksgc.html mamm2.html mpr.html supernova.html bjbaby.html
    rumor.html extras.html
);

my $nav = <<'NAV';
<nav class="top-nav">
  <a href="/" class="site-link">Colin<em>Firth</em>.com</a>
  <a href="/films.html">Films</a>
  <a href="/tv.html">TV</a>
  <a href="/theater.html">Theatre</a>
  <a href="/news.html">News</a>
  <a href="/upcoming.html">Upcoming</a>
  <a href="/boutiq.html">Boutique</a>
</nav>
NAV

my $footer = <<'FOOT';
<footer class="page-footer">
  <div class="footer-logo">Colin<em>Firth</em>.com</div>
  <p>A fan site &mdash; not affiliated with or endorsed by Colin Firth in any way.</p>
  <nav class="nav-links">
    <a href="/">Home</a>
    <a href="/films.html">Films</a>
    <a href="/tv.html">TV</a>
    <a href="/theater.html">Theatre</a>
    <a href="/news.html">News</a>
    <a href="/upcoming.html">Upcoming</a>
    <a href="/boutiq.html">Boutique</a>
  </nav>
</footer>
FOOT

find(sub {
    return unless -f && /\.html?$/i;
    my $file = $File::Find::name;
    my $name = $_;

    # Skip already-converted pages and non-root pages
    return if $skip{$name};
    return if $file =~ m{/(articles|int|pe|audio|video|admin|filmdis)/};

    open(my $fh, '<:raw', $file) or return;
    local $/; my $content = <$fh>; close $fh;

    # Skip if already using new.css
    if ($content =~ /new\.css/) {
        $skipped++;
        return;
    }

    # Extract title
    my ($title) = $content =~ /<title>([^<]*)<\/title>/i;
    $title //= 'ColinFirth.com';
    $title =~ s/\s*[-|]\s*colin firth.*//i;
    $title =~ s/colin firth[^-|]*[-|]\s*//i;
    $title = "ColinFirth.com &mdash; $title" unless $title =~ /colinfirth/i;

    # Build new head
    my $new_head = <<HEAD;
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$title</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght\@0,400;0,700;1,400;1,700&family=Lato:wght\@300;400;700&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="/new.css">
  <style>
    /* Legacy content overrides */
    .legacy { max-width: 1080px; margin: 0 auto; padding: 2rem; }
    .legacy table  { border-color: var(--border) !important; width: 100% !important; max-width: 100%; }
    .legacy td, .legacy th { background-color: var(--dark-mid) !important; color: var(--text) !important; border-color: var(--border) !important; font-family: 'Lato', sans-serif !important; }
    .legacy font   { color: inherit !important; font-family: inherit !important; }
    .legacy small  { font-size: .9em; }
    .legacy big    { font-size: 1.1em; }
    .legacy a      { color: var(--accent) !important; }
    .legacy a:hover { color: var(--gold) !important; }
    .legacy img    { max-width: 100%; height: auto; }
    .legacy hr     { border-color: var(--border); }
    .legacy b, .legacy strong { color: #fff; }
    .legacy h1, .legacy h2, .legacy h3 { font-family: 'Playfair Display', serif; color: #fff; }
  </style>
</head>
<body>
HEAD

    # Extract body content (everything between <body...> and </body>)
    my ($body_content) = $content =~ /<body[^>]*>(.*?)<\/body>/si;
    $body_content //= $content;

    # Strip old update dates at top (e.g. "(updated 12/04/07)")
    $body_content =~ s{^\s*<small[^>]*>\s*<span[^>]*>\s*\(updated[^)]+\)\s*</span>\s*</small>\s*<br>\s*<br>}{}si;

    my $new_content = $new_head
        . $nav
        . "\n<div class=\"legacy\">\n"
        . $body_content
        . "\n</div>\n"
        . $footer
        . "\n</body>\n</html>\n";

    open(my $out, '>:raw', $file) or do { warn "Cannot write $file: $!"; return };
    print $out $new_content;
    close $out;

    $fixed++;
    print "Converted: $name\n";

}, $base);

print "\nDone. Converted: $fixed  Skipped: $skipped\n";
