#!/usr/bin/perl -w
use strict;
use warnings;

use lib './LWP-Protocol-https-6.06/lib';

use LWP;
use LWP::Simple;
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
    print "URL: ".$url."\n";
    my $project_tag = $config{"project_tag"};
    chomp $project_tag;
    my $start_index = $config{"bug_start"};
    chomp $start_index;
    my $last_index = $config{"bug_end"};
    chomp $last_index;
    my $root_directory = $config{"root_directory"};
    chomp $root_directory;
    print "Directory to store bug information: ".$root_directory."\n";
    my $sleep_time = $config{"max_timeout_secs"};
    chomp $sleep_time;
    my $browser = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 });
    
    do
    {
      my $url_obj = new URI::URL "$url";
      my $complete_url;
      if ($url_obj->path ne "/browse/"){
         $complete_url = $url_obj->scheme."://".$url_obj->host."/browse/".$project_tag."-".$start_index;
      }else{
         $complete_url = $url_obj->scheme."://".$url_obj->host.$url_obj->path.$project_tag."-".$start_index;
      }
      print "BUG URL: ".$complete_url."\n";
      my $response = $browser->get( $complete_url );
      die "Can't get $url -- ", $response->status_line unless $response->is_success;
      my $page = $response->content;
      my $file_path = $root_directory."/".$project_tag."-".$start_index.".txt";
      open my $fh, ">>$file_path" or die $!;
      print {$fh} $page;
      close $fh;
      $start_index = $start_index + 1;
      sleep($sleep_time);
    }while( $start_index <=  $last_index);  
}else{
    print "\nError: Invalid configuration file supplied.\n";
    exit;
}

