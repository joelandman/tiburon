#!/opt/scalable/bin/perl

use Mojolicious::Lite;
use File::ChangeNotify;

use strict;
use POSIX;
use File::Spec;
use Config::JSON;
use File::Touch;
use Data::Dumper;
use constant true	=> (1==1);
use constant false      => (1==0);
use constant config_file	=> '/data/tiburon/etc/register.json';

my ($config,$machines,$mac,$macs,$install,$targets,$type,$name);
my ($boot_info,$debug,$watcher);


$debug		= true;
my $length = 32;
# make rand random;
srand (time ^ $$ ^ unpack "%L*", `ps axww | gzip -f`);

my $pass;
my @ch  = ('0'..'9', 'A'..'Z', 'a'..'z', ,'_', ' ');
foreach ( 1 .. $length ) { $pass .= $ch[rand($#ch)]; }
app->secret($pass);
 

my $comp_root   = POSIX::getcwd;
plugin 'Mason1Renderer' => 
    { 
        interp_params  => 
            { 
                comp_root => File::Spec->catfile($comp_root,"root") 
            },
        request_params => 
            { 
                error_format => "brief" 
            }
    };

get '/' => sub {
  use Data::Dumper;
  my $self = shift;
  my ($config,$machines);
  
  $config	= &get_config(config_file);
  $machines	= $config->get('machines');
  
  $self->render(
                'list.html',
                handler         => "mason",
		firstboot	=> 1,
		machines	=> $machines
               );
};


get '/register/:mac/:name' => sub {
  use Data::Dumper;
  my $self = shift;
  my $mac  = $self->param('mac');
  my $name = $self->param('name');
  $config	= &get_config(config_file);
  $machines	= $config->get('machines');
  my ($path,$rc);
  $name	= "newmachine" if (!$name);
  
  $mac 	=~ s/^mac=//  if ($mac);
  $name =~ s/^name=// if ($name);
  
  if ( $mac && $name) 
     {
       # insert or update
       $path	= sprintf "machines/%s/name",lc($mac);
       $rc	= $config->set($path,$name);       
     }
   
  if (!$mac) 
     {
       # redirect to /
       $self->redirect_to("/");
     }

  
    
  printf "updated db \n";
  $self->render(
		'register.html', 
		handler 	=> "mason", 
		mac		=> $mac,
		name		=> $name,
		rc		=> $rc
	       );
};

get '/add/:mac/:key/:value' => sub {
  use Data::Dumper;
  my $self = shift;
  my $mac  = $self->param('mac');
  my $k    = $self->param('key');
  my $v    = $self->param('value');
  $config	= &get_config(config_file);
  $machines	= $config->get('machines');
  my ($path,$rc);
  
  $mac 	=~ s/^mac=//  	if ($mac);
  $k    =~ s/^key=//  	if ($k);
  $v    =~ s/^value=//  if ($v);
  
  if ( $mac && $k ) 
     {
       # insert or update
       $path	= sprintf "machines/%s/%s",lc($mac),$k;
       $rc	= $config->set($path,(defined($v) ? $v : "undef"));       
     }
   
  if (!$mac) 
     {
       # redirect to /
       $self->redirect_to("/");
     }

  
    
  printf "updated db \n";
  $self->render(
		'add.html', 
		handler 	=> "mason", 
		mac		=> $mac,
		key		=> $k,
		value		=> $v,
		rc		=> $rc
	       );
};

post '/add/:mac/:key/:value' => sub {
  use Data::Dumper;
  my $self = shift;
  my $mac  = $self->param('mac');
  my $k    = $self->param('key');
  my $v    = $self->param('value');
  $config	= &get_config(config_file);
  $machines	= $config->get('machines');
  my ($path,$rc);
  
  $mac 	=~ s/^mac=//  	if ($mac);
  $k    =~ s/^key=//  	if ($k);
  $v    =~ s/^value=//  if ($v);
  
  if ( $mac && $k ) 
     {
       # insert or update
       $path	= sprintf "machines/%s/%s",lc($mac),$k;
       $rc	= $config->set($path,(defined($v) ? $v : "undef"));       
     }
   
  if (!$mac) 
     {
       # redirect to /
       $self->redirect_to("/");
     }

  
    
  printf "updated db \n";
  $self->render(
		'add.html', 
		handler 	=> "mason", 
		mac		=> $mac,
		key		=> $k,
		value		=> $v,
		rc		=> $rc
	       );
};

app->start(qw(daemon --listen http://*:4000));;

sub get_config {
  my $new	= false;
  my $cf	= shift;
  
  if (!(-e $cf)) {
    my @ft;
    push @ft, config_file;
    touch(@ft);
    $new	= true;
  }
  $new	= true if (-z $cf) ;
  
 my ($volume,$directories,$file) = File::Spec->splitpath( $cf );
 my (@dir,$filter,$ts);
 push @dir,$directories;
 $filter  = $file;
 $filter  =~ s/\./\\\./;
 $ts	= localtime;
 $watcher = 
        File::ChangeNotify->instantiate_watcher
	( 
	  directories => @dir,
          filter      => qr/$filter/
        );

  if ($new)
   {
    $config = Config::JSON->create(config_file);
    $config->set('created',sprintf '%s',$ts);
   }
  else
   {
    $config = Config::JSON->new(config_file);
    $config->set('updated',sprintf '%s',$ts);
   }
  return $config;
}