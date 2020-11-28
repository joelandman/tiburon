#!/usr/bin/env perl

use strict;
use Getopt::Long;
use constant {true => (1==1),  false => (1==0) };

my ($debug,$verbose,$svcfile,$sysd_path,$rundir,$user,$group,$rc,$out);
my ($bootapp);

$debug = $verbose = false;


GetOptions(
           "debug|d"               => \$debug,
           "verbose|v"             => \$verbose,
           "servicefile|svc|s=s"   => \$svcfile,
	   "systemdpath|sdp=s"	   => \$sysd_path,
	   "bootapp|b=s"	   => \$bootapp,
	   "rundir=s"		   => \$rundir,
	   "user|u=s"		   => \$user,
	   "group|g=s"		   => \$group
);

#
# check user and group ... if they are not defined, try www-data
$user 	= "www-data" if (!defined($user));
$group	= "www-data" if (!defined($group));
chomp($rc = `getent passwd | grep $user`);
die "FATAL ERROR: no user \'$user\' in password database\n" if ($rc eq "");
chomp($rc = `getent group | grep $group`);
die "FATAL ERROR: no group \'$group\' in group database\n" if ($rc eq "");

#
# check bootapp to make sure it exists and is executable
die "FATAL ERROR: bootapp \'$bootapp\' does not exist\n" if (!(-e $bootapp));
die "FATAL ERROR: bootapp \'$bootapp\' is not executable\n" if (!(-x $bootapp));

#
# check rundir to make sure it exists and is a directory
die "FATAL ERROR: rundir \'$rundir\' does not exist\n" if (!(-e $rundir));
die "FATAL ERROR: rundir \'$rundir\' is not a directory\n" if (!(-d $rundir));

if (!defined($svcfile)) {
  $svcfile	= &get_value("Enter name of service file to generate");
}
&dp(sprintf("Service file = %s",$svcfile));

if (!defined($sysd_path)) {
  $sysd_path      = &get_value("Enter full path to systemd local service file storage");
}
&dp(sprintf("systemd path = %s",$sysd_path));

$out	= <<'EOS';
[Unit]
Description=Start Tiburon boot server daemon
After=network.target

[Service]
WorkingDirectory=%s
ExecStart=%s
User=%s
Group=%s

[Install]
WantedBy=multi-user.target
EOS

my $x = sprintf($out,$rundir,$bootapp,$user,$group);

# place the systemd service file in its location
open(my $fh,">".$sysd_path.'/'.$svcfile) or die "FATAL ERROR: unable to open file $sysd_path/$svcfile for writing\n";

printf $fh "%s\n",$x;
close($fh);


sub get_value {
  my $q = shift;
  printf "%s\n",$q;
  my $v = <>;
  chomp($v);
  return($v);
}

sub dp {
  my $s = shift;
  printf STDERR "D[%i] %s\n",$s if ($debug && !$verbose);
  printf "%s\n",$s if (!$debug && $verbose);
}

