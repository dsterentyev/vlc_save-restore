#!/usr/bin/perl

use utf8;
use JSON;

$wnname = shift @ARGV;

@wndinfo = `/usr/bin/wmctrl -lGp | /usr/bin/grep -F VLC`;

@wlist = ();
foreach $wnd (@wndinfo)
{
	chomp $wnd;
	if($wnd =~ /^(\S+)\s+0\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+\S+\s+(.+)$/)
	{
		$args = `cat /proc/$2/cmdline`;
		chomp $args;
		@geom = `/usr/bin/xwininfo -stats -id $1 | /usr/bin/grep -F "Absolute upper-left" | /usr/bin/grep -oP "\\d+"`;
		$x = shift(@geom);
		chomp $x;
		$y = shift(@geom);
		chomp $y;
		push(@wlist, [$x, $y, $5, $6, $7, $args]);
	}
	else
	{
		die("can't parse window info '$wnd'\n");
	}
}

$sfile = `kdialog --getsavefilename ~/Документы '*.vlc_save'`;
chomp $sfile;
exit if $sfile eq '';

if($sfile !~ /\.vlc_save$/)
{
	$sfile .= '.vlc_save';
}
#print $sfile;

open FILE,">$sfile";
print FILE to_json(\@wlist,{pretty => 1});
close FILE;

0;