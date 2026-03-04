#!/usr/bin/perl
use strict;
use warnings;
use File::Find;

my $dir = $ARGV[0] or die "Usage: $0 <directory>\n";
my $fixed = 0;
my $skipped = 0;

find(sub {
    return unless -f && /\.(html?|htm)$/i;
    my $file = $File::Find::name;

    open(my $fh, '<:raw', $file) or do { warn "Cannot read $file: $!"; return };
    local $/; my $content = <$fh>; close $fh;
    my $orig = $content;

    # 1. Remove Wayback JS/CSS injection block at top of file
    #    Spans from first web-static.archive.org script tag up to
    #    <!-- End Wayback Rewrite JS Include -->
    $content =~ s{<script[^>]*web-static\.archive\.org[^>]*>.*?</script>\s*}{}gsi;
    $content =~ s{<script[^>]*>\s*window\.RufflePlayer.*?</script>\s*}{}gsi;
    $content =~ s{<script[^>]*>\s*__wm\.(init|wombat)\(.*?</script>\s*}{}gsi;
    $content =~ s{<link[^>]*web-static\.archive\.org[^>]*/>\s*}{}gsi;
    $content =~ s{<!--\s*End Wayback Rewrite JS Include\s*-->\s*}{}gsi;

    # 2. Remove trailing Wayback archive comments and playback timings
    $content =~ s{<!--\s*FILE ARCHIVED ON.*?-->}{}gsi;
    $content =~ s{<!--\s*JAVASCRIPT APPENDED BY WAYBACK MACHINE.*?-->}{}gsi;
    $content =~ s{<!--\s*playback timings \(ms\):.*?-->}{}gsi;

    # 3. Strip Wayback URL wrappers from href/src/action attributes
    #    Pattern: https://web.archive.org/web/TIMESTAMP[flags]/http://www.firth.com/PATH
    #    -> /PATH  (internal links become root-relative)
    $content =~ s{https?://web\.archive\.org/web/[^/]*/https?://(?:www\.)?firth\.com(/[^"' >]*)}{$1}gi;
    $content =~ s{https?://web\.archive\.org/web/[^/]*/https?://(?:www\.)?firth\.com([^/"' >]*)}{/$1}gi;

    #    External sites: strip Wayback wrapper, keep original URL
    $content =~ s{https?://web\.archive\.org/web/[^/]*/}{http://}gi;

    # 4. Fix mangled mailto links (mailro: -> mailto:)
    $content =~ s{mailro:}{mailto:}gi;

    if ($content ne $orig) {
        open(my $out, '>:raw', $file) or do { warn "Cannot write $file: $!"; return };
        print $out $content; close $out;
        $fixed++;
        print "Fixed: $file\n";
    } else {
        $skipped++;
    }
}, $dir);

print "\nDone. Fixed: $fixed files, Skipped (no changes): $skipped files.\n";
