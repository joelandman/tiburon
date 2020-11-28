#!/usr/bin/env perl

# install perl modules
use strict;
use CPAN;

my @mods=qw(MCE Starman HTML::TreeBuilder HTTP::Response HTML::Entities JSON::PP File::ChangeNotify  Mojolicious Mojolicious::Plugin::RemoteAddr HTML::Mason Mojolicious::Plugin::Mason1Renderer Crypt::PRNG);

map {
	printf "===================================\nInstalling module %s ...\n",$_;
	CPAN::Shell->install($_);
	printf "Done\n----------------------------------\n";
    } @mods;
