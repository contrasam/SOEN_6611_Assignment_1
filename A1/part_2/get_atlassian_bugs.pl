#!/usr/bin/perl -w
use strict;
use warnings;

use lib './LWP-Protocol-https-6.06/lib';
use lib './URI-Find-20140709/lib';
use lib './HTML-Tree-5.03/lib';
use lib './Regexp-Common-2013031301/lib';

use LWP;
use LWP::Simple;
use URI::Find;
use HTML::TreeBuilder;
use Encode;
use URI::URL;

my $number_of_args = $#ARGV + 1;
if($number_of_args != 1){
    print "\nUsage: perl get_atlassian_bugs bugs_conf\n";
    exit;
}

my $bug_conf_file = $ARGV[0];
print "\nCONFIG FILENAME: $bug_conf_file\n";
open FILE,"<",$bug_conf_file or die $!;
my @lines = <FILE>;
my %config;
foreach my $line ( @lines ) {
    my @config_pair = split('=', $line);
    my $key = $config_pair[0];
    splice @config_pair, 0, 1;
    $config{$key} = join('=', @config_pair);
}
if(exists($config{"url"}) && exists($config{"project_tag"}) && exists($config{"bug_start"}) && exists($config{"bug_end"}) && exists($config{"max_timeout_secs"}) && exists($config{"root_directory"})){
    my $url = $config{"url"};
    chomp $url;
    print "URL: ".$url;
    my $url_obj = new URI::URL "$url";
    my $root_directory = $config{"root_directory"};
    chomp $root_directory;
    my $browser = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 });
    my $response = $browser->get( $url );
    die "Can't get $url -- ", $response->status_line unless $response->is_success;
    my $page = Encode::decode_utf8($response->content);

    
}else{
    print "\nError: Invalid configuration file supplied.\n";
    exit;
}

sub uniq {
    my %seen;
    grep !$seen{$_}++, @_;
}

sub remove_git_extension {
   my $url = $_[0];
   my $last_four = substr $url, -4;
   if($last_four eq ".git"){
     $url = substr $url, 0, -4;
   }
   return $url;
}
