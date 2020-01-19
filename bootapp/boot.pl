#!/usr/bin/env perl

use feature ':5.22';
use Mojolicious::Lite;
use Mojo::Util qw(url_unescape);
use File::ChangeNotify;

use strict;
use warnings;
use utf8;
use POSIX;
use File::Spec;
use Config::JSON;
use Data::Dumper;
use URI;
use Crypt::PRNG qw(random_string_from rand irand);


use constant {true => (1==1),  false => (1==0) };
my $config_file	= '/data/tiburon/etc/boot.json';

my ($config,$machines,$mac,$macs,$install,$targets,$type,$name);
my ($boot_info,$debug,$servers);

my $watcher = 
        File::ChangeNotify->instantiate_watcher
	( 
	  directories => [ '/data/tiburon/etc/' ],
          filter      => qr/boot\.json/
        );


$config 	= Config::JSON->new($config_file);
$machines	= $config->get("machines");
$servers 	= $config->get("servers");

#printf STDERR "Dump: %s\n",Dumper($servers);

$debug		= true;





foreach $mac (keys %{$machines})
 {
  printf "machine: %s (len=%i), type: %s, name: %s\n",$mac,length($mac),$machines->{$mac}->{'type'},$machines->{$mac}->{'name'};
  $macs->{lc($mac)} = $mac; # use only lower case in the search
 } 

my $comp_root   = POSIX::getcwd;
plugin 'Mason1Renderer' => 
  { 
     interp_params  => { comp_root => File::Spec->catfile($comp_root,"root") },
     request_params => { error_format => "brief" }
  };

helper whois => sub {
    my $self  = shift;
    my $agent = $self->req->headers->user_agent || 'Anonymous';
    my $ip    = $self->tx->remote_address;
    my $lip   = $self->tx->local_address;
    my $secure= $self->req->is_secure;
    my $ret   = {
                  agent         => $agent,
                  ip            => $ip,
                  local_address => $lip,
                  secure        => $secure 
                };
    return $ret;
  };


get '/' => sub {
  use Data::Dumper;
  my $self = shift;
  my ($k,$v,$s,$k2);
  my $whois     = $self->whois;
  &check_config_for_changes();
  
  $type = $machines->{'default'}->{'type'};
  $name = $machines->{'default'}->{'name'};
  $boot_info = $targets->{$type}->{$name} ;
  
  # update boot_info with any replacement values of __server.key__
  foreach $k (keys %{$servers}) {
	$s = sprintf "__servers.%s__",$k;
	$v = $servers->{$k};
	foreach $k2 (keys %{$boot_info}) {
	   printf STDERR " -: %s -> %s\n",$s,$v if ($boot_info->{$k2} =~ s/$s/$v/g);
	}
  }
 
  $self->render(
                'boot.html',
                handler         => "mason",
		firstboot	=> 1,
		boot_info	=> $boot_info,
		whois		=> $whois
               );
};

get '/boot' => sub {
  my $self = shift;
  $self->redirect_to("/");
};

get '/boot/:mac' => sub {
  my $self = shift;
  my $m  = $self->param('mac');
  my ($target,$boot_server,$ip,$boot_protocol,$netmask,$gateway);
  my ($kernel, $initrd, $boot_args, $state, $inst_image, $k, $v, $k2, $s);
  my $whois     = $self->whois;

  # unescape mac
  my $mac = lc(url_unescape $m);
  $mac =~ s/^\s{1,}//g;
  $mac =~ s/\s{1,}$//g;

  printf STDERR " incoming m ->%s\n\tmac -> %s\n",$m,$mac;
  $self->redirect_to("/") if (!$mac);
  $state	= "";
  &check_config_for_changes();
   
  # search for the mac address ... if found, get the info
  # if not found, then hand it good defaults based upon the
  # default entry
  
  $mac =~ s/^mac=// if ($mac);
  
  $type = ( exists($machines->{$mac} ) ? $machines->{$mac}->{'type'} : $machines->{'default'}->{'type'} );
  $name = ( exists($machines->{$mac} ) ? $machines->{$mac}->{'name'} : $machines->{'default'}->{'name'} );

  printf STDERR " - mac=%s (len=%i), type=%s, name=%s\n",$mac,length($mac),$type,$name;
  printf STDERR "  : exists=%s\n",(exists($machines->{$mac}) ? "true" : "false");
 
  $boot_info = $targets->{$type}->{$name} ;
  #printf STDERR " - Dump of bootinfo\n\t%s\n",Dumper($boot_info);
  #printf STDERR " - Dump of targets\n\t%s\n",Dumper($targets);
   
  # update boot_info with any replacement values of __server.key__
  foreach $k (keys %{$servers}) {
        $s = sprintf "__servers.%s__",$k;
        $v = $servers->{$k};
        foreach $k2 (keys %{$boot_info}) {
           printf STDERR " -: %s -> %s\n",$s,$v if ($boot_info->{$k2} =~ s/$s/$v/g);
        }  
  }
 
  $self->render(
		'boot.html', 
		handler 	=> "mason", 
		boot_info	=> $boot_info,
		firstboot	=> 0,
		whois		=> $whois
	       );
};


&set_secure_cookie();
app->sessions->default_expiration(1); # set expiry to 1 hour
app->start(qw(daemon --listen http://*:27182));

sub set_secure_cookie {
  # generate a secure cookie secret
  my $length  = 32;
  my @ch        = ['0'..'9', 'A'..'Z', 'a'..'z', ,'_', ' '];
  my $pass      = random_string_from(@ch,$length);
  app->secrets($pass);
}

sub check_config_for_changes {
# check to see if the config file changed, and if so, reload
  if ( my @events = $watcher->new_events() )
     {
        undef $config;
        $config = Config::JSON->new($config_file);
     }
  $machines     = $config->get("machines");
  $targets      = $config->get("targets"); 
  $servers	= $config->get("servers"); 
}
