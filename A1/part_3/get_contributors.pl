#!/usr/bin/perl -w
use strict;
use warnings;

use lib './LWP-Protocol-https-6.06/lib';
use lib './JSON-2.90/lib';

use LWP;
use JSON qw( decode_json );
use Data::Dumper;

my $url =  "https://api.github.com/repos/poise/python/contributors?access_token=1b06cd246cad223d19040f7c52186dd0e38a6532";
my $browser = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 });
my $api_response_json = $browser->get( $url );
die "Can't get $url -- ", $api_response_json->status_line unless $api_response_json->is_success;
my @response = decode_json($api_response_json->content);
print "Contributors for the https://api.github.com/repos/poise/python/ repository: \n";
foreach my $item (@{$response[0]})
{
      my %item_hash = %{$item};
      print $item_hash{'login'}."\n";
}

