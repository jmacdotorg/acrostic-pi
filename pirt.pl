#!/usr/bin/env perl

use warnings;
use strict;
use utf8;

use Net::Twitter;
use Config::Tiny;
use Getopt::Mini;
use DB_File;
use Perl6::Slurp;
use FindBin;
use Lingua::EN::Numbers::Ordinate;
use Bad::Words;
use Scalar::Util 'blessed';

use Readonly;
Readonly my $LWP_TIMEOUT => 10;
Readonly my $NEXT_DIGIT_FILENAME => 'next_digit.txt';
Readonly my $PI_FILENAME => 'pi.txt';
Readonly my $SEEN_FILENAME => 'seen.db';
Readonly my $SEARCH_LIMIT => 130;
Readonly my %WORD_FOR => (
    1 => 'one',
    2 => 'two',
    3 => 'three',
    4 => 'four',
    5 => 'five',
    6 => 'six',
    7 => 'seven',
    8 => 'eight',
    9 => 'nine',
    0 => 'zero',
    '.' => 'point',
);
Readonly my $BIO_PLACEHOLDER => 'Nth';
Readonly my $BIO_TEMPLATE =>
    qq{Just what the name says. By \@JmacDotOrg. }
    . qq {We're now up to the $BIO_PLACEHOLDER digit of π. }
    . qq {Tweets may be NSFW.};
Readonly my $NAUGHTY_WORDS => 
    join '|', @{ Bad::Words->new( qw( masturbating ) ) };
Readonly my $QUERY_FILTERS => '-#mtvhottest';

my $config_file = $ARGV{ config } or die "Usage: $0 --config=path/to/config.file\n";
my $twitter_config = Config::Tiny->read( $config_file )
    or die "$Config::Tiny::errstr\n";

my $twitter = Net::Twitter->new(
    traits   => [qw/API::RESTv1_1/],
    ssl => 1,
    %{ $twitter_config->{ _ } },
    useragent_args => { timeout => $LWP_TIMEOUT },
);

my $next_digit_filename = "$FindBin::Bin/$NEXT_DIGIT_FILENAME";
my $pi_filename         = "$FindBin::Bin/$PI_FILENAME";
my $seen_filename       = "$FindBin::Bin/$SEEN_FILENAME";

tie my %seen_status, 'DB_File', $seen_filename, O_RDWR|O_CREAT, 0666, $DB_HASH
        or die "Can't open $seen_filename: $!\n";

my $next_digit;
if ( -e $next_digit_filename ) {
    chomp( $next_digit = slurp $next_digit_filename );
}

unless ( defined $next_digit ) {
    die "Cowardly refusing to run because I can't determine the next digit."
        . "(Does $next_digit_filename exist?)\n";
}

open my $pi_fh, '<', $pi_filename
    or die "Can't read $pi_filename: $!";

my $digit;
seek $pi_fh, $next_digit - 1, 0;
read $pi_fh, $digit, 1;
close $pi_fh;

my $word = $WORD_FOR{ $digit };

my $statuses_read = 0;
my $chosen_status;
my $max_id;
while ( ( not $chosen_status ) && ( $statuses_read < $SEARCH_LIMIT ) ) {
    if ( $statuses_read > 0 ) {
        sleep 1;
    }
    my %search_args = ( 'q' => "$word $QUERY_FILTERS", lang => 'en', );
    if ( $max_id ) {
        $search_args{ max_id } = $max_id;
    }

    my $result;
    eval {$result = $twitter->search( \%search_args );};
    if ( my $err = $@ ) {
	die $@ unless blessed $err && $err->isa('Net::Twitter::Error');
 
    warn "HTTP Response Code: ", $err->code, "\n",
         "HTTP Message......: ", $err->message, "\n",
	"Twitter error.....: ", $err->error, "\n";
    }
    my $next_results_string = $result->{ search_metadata }->{ next_results };
    if ( $next_results_string ) {
        ( $max_id ) = $next_results_string =~ /^.*?(\d+)/;
    }
    else {
        next;
    }
    for my $status ( @{ $result->{ statuses } } ) {
        $statuses_read++;
        if ( ( $status->{ text } =~ /^$word/i )
             && ( $status->{ text } !~ /\b($NAUGHTY_WORDS)\b/oi )
             && ( $status->{ text } !~ /followed me/ )
             && ( not $seen_status{ $status->{ id } } )
        ) {
            $chosen_status = $status;
        }
    }
    if ( $ARGV{ debug } ) {
        print "Read and rejected $statuses_read statuses...\n";
    }
}

if ( $chosen_status ) {
    if ( $ARGV{ debug } ) {
        print "$chosen_status->{ text }\n";
    }
    else {
        $twitter->retweet( $chosen_status->{ id } );
    }
    $seen_status{ $chosen_status->{ id } } = 1;

    my $new_bio = $BIO_TEMPLATE;
    my $ordinal = 
	commify( ordinate( $next_digit > 1 ? $next_digit - 1 : $next_digit ) );
    $new_bio =~ s/$BIO_PLACEHOLDER/$ordinal/;

    if ( $ARGV{ debug } ) {
        print "$new_bio\n";
    }
    else {
        $twitter->update_profile( { description => $new_bio } );
    }
    open my $next_digit_fh, '>', $next_digit_filename
	or die "Can't create $next_digit_filename: $!";
    print $next_digit_fh ++$next_digit . "\n";
    close $next_digit_fh;
}
elsif ( $ARGV{ verbose } ) {
    warn "Couldn't find '$word' within $SEARCH_LIMIT tweets.\n";
}

sub commify {
    local $_  = shift;
    1 while s/((?:\A|[^.0-9])[-+]?\d+)(\d{3})/$1,$2/s;
    return $_;
}
