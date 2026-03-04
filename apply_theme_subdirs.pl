#!/usr/bin/perl
use strict; use warnings;
use File::Find;

my $BASE = "C:/Users/walhu/websites/firth.com";
my ($fixed, $skipped) = (0, 0);

my $NAV = '<nav class="top-nav">
  <a href="/" class="site-link">Colin<em>Firth</em>.com</a>
  <a href="/films.html">Films</a>
  <a href="/tv.html">TV</a>
  <a href="/theater.html">Theatre</a>
  <a href="/news.html">News</a>
  <a href="/boutiq.html">Boutique</a>
</nav>
';

my $FOOTER = '<footer class="page-footer">
  <div class="footer-logo">Colin<em>Firth</em>.com</div>
  <p>A fan site &mdash; not affiliated with or endorsed by Colin Firth in any way.</p>
  <nav class="nav-links">
    <a href="/">Home</a>
    <a href="/films.html">Films</a>
    <a href="/articleindex.html">Articles</a>
    <a href="/news.html">News</a>
    <a href="/boutiq.html">Boutique</a>
  </nav>
</footer>
<script src="/nav.js"></script>
';

my $CSS = '  <style>
    .legacy { max-width: 900px; margin: 0 auto; padding: 2rem 1.5rem; }
    .legacy table { border-color: var(--border) !important; width: 100% !important; max-width: 100%; }
    .legacy td, .legacy th { background-color: var(--dark-mid) !important; color: var(--text) !important; border-color: var(--border) !important; font-family: "Lato", sans-serif !important; }
    .legacy font { color: inherit !important; font-family: inherit !important; }
    .legacy small { font-size: .9em; }
    .legacy big   { font-size: 1.1em; }
    .legacy a { color: var(--accent) !important; }
    .legacy a:hover { color: var(--gold) !important; }
    .legacy img { max-width: 100%; height: auto; }
    .legacy hr  { border-color: var(--border); }
    .legacy b, .legacy strong { color: #fff; }
    .legacy p, .legacy li { font-size: .93rem; line-height: 1.75; color: var(--muted); }
    .legacy h1, .legacy h2, .legacy h3, .legacy h4 { font-family: "Playfair Display", serif; color: #fff; }
    .legacy blockquote { border-left: 3px solid var(--gold); padding-left: 1rem; margin: 1rem 0; color: var(--muted); font-style: italic; }
  </style>
';

find(sub {
    return unless -f && /\.html?$/i;
    my $file = $File::Find::name;
    return unless $file =~ m{/(articles|int|pe)/};

    open(my $fh, "<:raw", $file) or return;
    local $/; my $content = <$fh>; close $fh;

    if ($content =~ /new\.css/) { $skipped++; return; }

    my ($title) = $content =~ /<title>([^<]*)<\/title>/i;
    $title //= "ColinFirth.com";
    $title =~ s/^\s+|\s+$//g;
    $title = "ColinFirth.com &mdash; $title" unless $title =~ /colin.?firth/i;

    my ($body) = $content =~ /<body[^>]*>(.*?)<\/body>/si;
    $body //= $content;
    $body =~ s/<script[^>]*>.*?<\/script>//gsi;

    my $head = "<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n"
        . "  <meta charset=\"UTF-8\">\n"
        . "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n"
        . "  <title>$title</title>\n"
        . "  <link rel=\"preconnect\" href=\"https://fonts.googleapis.com\">\n"
        . "  <link rel=\"preconnect\" href=\"https://fonts.gstatic.com\" crossorigin>\n"
        . "  <link href=\"https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght\@0,400;0,700;1,400;1,700&family=Lato:wght\@300;400;700&display=swap\" rel=\"stylesheet\">\n"
        . "  <link rel=\"stylesheet\" href=\"/new.css\">\n"
        . $CSS
        . "</head>\n<body>\n";

    my $out_html = $head . $NAV . "\n<div class=\"legacy\">\n" . $body . "\n</div>\n" . $FOOTER . "</body>\n</html>\n";

    open(my $out, ">:raw", $file) or do { warn "Cannot write $file\n"; return };
    print $out $out_html; close $out;
    $fixed++;
    print "OK: $_\n";

}, $BASE);

print "\nDone. Converted: $fixed  Skipped (already done): $skipped\n";
