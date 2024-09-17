#!/usr/bin/perl

use utf8;
use JSON;
use POSIX qw{setsid};
use String::ShellQuote 'shell_quote';
use Encode;

$save = shift(@ARGV);

open FILE,"$save";
$wlist = from_json(join('', <FILE>), {utf8 => 1});
close FILE;

# run VLCs stage

foreach $v (@$wlist)
{
	$x = $$v[0];
	$y = $$v[1];
	$w = $$v[2];
	$h = $$v[3];
	$t = $$v[4];
	$c = $$v[5];
	$pid = fork();
	sleep(1);
	if($pid == 0)
	{
		#child process
		POSIX::setsid();
		fork and exit;
		umask 0;		
		chdir "/";
		close STDOUT;
		close STDERR;
		close STDIN;
		@arg = map { $_ .= "\0" } split("\0", $c);
		exec(@arg);
	}
	elsif (!defined($pid))
	{
		die "could not fork";
	}
}

# waiting for VLC windows

$cnt = 0;
do
{
	@wininfo = `/usr/bin/wmctrl -lp | /usr/bin/grep VLC`;
	$cnt ++;
}
until((scalar(@wininfo) == scalar(@$wlist)) || $cnt > 30);

# move VLC windows stage

@placed = ();

print scalar @$wlist . "\n";

for($cnt = 0; $cnt < 10 ; $cnt++)
{
	print "tick $cnt\n";
	%wids = ();
	@wininfo = `/usr/bin/wmctrl -lp | /usr/bin/grep VLC`;
	foreach $win (@wininfo)
	{
		chomp $win;
		if($win =~ /^(\S+)\s+0\s+(\d+)/)
		{
			$pid = $2;
			$arg = `cat /proc/$pid/cmdline`;
			chomp $arg;
			$wids{$arg}=$1;
		}
		else
		{
			die("can'r parse $win\n!");
		}
	}

	foreach $wl (@$wlist)
	{
		$arg = $$wl[5];
		Encode::_utf8_off($arg);
#		print " ---- [1] $arg\n";
		if(defined $wids{$arg})
		{
#			print " ---- [2] $arg\n";
#			print "     placed windows: " . join(', ', @placed) . "\n";
			$wid = $wids{$arg};
			if(! ($wid ~~ @placed))
			{
#				print " ---- [3] $arg\n";
				$x = $$wl[0];
				$y = $$wl[1];
#				print "trying wmctrl -i -r $wid -e 0,$x,$y,-1,-1\n";
#				`/usr/bin/wmctrl -i -r $wid -e 0,0,0,-1,-1`;
				`/usr/bin/wmctrl -i -r $wid -e 0,$x,$y,-1,-1`;
				push(@placed, $wid);
				sleep(1);
			}
		}
		else
		{
#			print ".... not found $arg\n";
		}
	}
	sleep(1);
	if(scalar(@placed) == scalar(@$wlist))
	{
		$cnt = 31;
	}
}

0;
