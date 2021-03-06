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
    print "\nUsage: perl get_git.pl git_conf\n";
    exit;
}

my $git_conf_file = $ARGV[0];
print "\nCONFIG FILENAME: $git_conf_file\n";
open FILE,"<",$git_conf_file or die $!;
my @lines = <FILE>;
my %config;
foreach my $line ( @lines ) {
    my @config_pair = split('=', $line);
    my $key = $config_pair[0];
    splice @config_pair, 0, 1;
    $config{$key} = join('=', @config_pair);
}
if(exists($config{"url"}) && exists($config{"root_directory"})){
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

    my @abs_uris;
    print "\nFinding Absolute URIs in page";
    my $finder = URI::Find->new(sub {
      my($uri, $original_uri) = @_;
      if($original_uri !~ /data:/ && $original_uri !~ /https:\/\/github.com\/showcases/ && $original_uri !~ /https:\/\/github.com\/site/ && (substr($original_uri, -3) ne ".js") && (substr($original_uri, -4) ne ".css")){
          $original_uri = remove_git_extension($original_uri);
          push @abs_uris, $original_uri;
      }
    });
    $finder->find(\$page);

    my @rel_uris;
    print "\nFinding Relative URIs in page.";
    my $tree = HTML::TreeBuilder->new();
    $tree->parse_content($page);
    my @links = $tree->look_down('_tag', 'a'); 
    for my $link (@links) {
          my $href = $link->attr('href');
	  if( not head  $href) {
          	$href = remove_git_extension($href);
	  	my @chars = split("", $href);
	  	my $abs_path;
	  	if(exists($chars[0]) && $chars[0] eq "/"){
			$abs_path = $url_obj->scheme."://".$url_obj->host."".$href;
	  	}else{
			$abs_path = $url_obj->scheme."://".$url_obj->host."/".$href;
	  	}
	  	if($abs_path !~ /https:\/\/github.com\/showcases/ && $abs_path !~ /https:\/\/github.com\/site/){
	     		push @rel_uris, $abs_path;
	  	} 		  
	  }
    }

    my @unique_uris = uniq(@abs_uris,@rel_uris);
    print "\nChecking for GIT URLs\n";
    foreach my $uri ( @unique_uris ) {
        if("$uri" ne "$url"){
	  system('git ls-remote --exit-code -h "'.$uri.'" >>output.log 2>/dev/null');
	  if($? == 0){
	    print "Found a GIT URL: ".$uri."\n";
	    my @split_url = split('/', $uri);
	    my $clone_path = $config{'root_directory'};
	    chomp $clone_path;
	    print "Cloning repository: ".$split_url[-1]." in location: ".$clone_path."\n";
            system('git clone '.$uri.' '.$clone_path.'/'.$split_url[-1]);
	    print "Cloned GIT URL: ".$uri."\n";
	  }
        }
    }
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

