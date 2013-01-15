#!/usr/bin/perl -w

use POSIX qw/strftime/;

# Date and time variables.
$date = strftime('%F',localtime);
$datetime = strftime('%D %T',localtime);

# Make directory with current date
mkdir("/home/n02703942/perfdata/$date", 0777);


# Accept command-line arguments for collection interval and duration.
#Default case: Every 10 seconds for 60 seconds.
$n1=$ARGV[0];
$n2=$ARGV[1];

if( $n1 ne "")
{
        $interval=$n1;
}
else
{
        $interval=10;
}
if( $n2 ne "")
{
        $duration=$n2;
}
else
{
        $duration=60;
}

# Establish the counter.
$counts = $duration/$interval;

print "Starting data collection with script $0 of PID: $$: Interval = $interval, Duration = $duration. Counts = $counts. Current time is $datetime.\n";

print "Starting vmstat.\n";

# Pipe vmstat command through the timestamp script in order to prefix each line with a timestamp.
$vm_cmd="vmstat -n $interval | /home/n02703942/collector/timestamp.pl > /home/n02703942/perfdata/$date/vmstat.dat &";

# Fork child process to run vmstat command.
# Parent process terminates vmstat and child  when counter reaches 1, sleeps otherwise.
$retval=fork();

if ( $retval != 0 ) {
     # this is parent

     print "child process id = $retval ...\n";

	 # Capture vmstat process to obtain process ID to kill
     $filter="ps -ef | grep 2778 | grep \"vmstat -n $interval\"\$\n";
     $capture=`$filter`;
     print("$capture\n");
     @VMPID=split(/\ +|\t/, $capture);
     $vmprocid=$VMPID[1];

     print("vmstat process -> $vmprocid\n");
     
     while ($counts > 1)
     {
	sleep $interval;
	$counts--;
     }	
     `kill $retval $vmprocid >/dev/null 2>&1`;


} else {
     # this is child
     exec( $vm_cmd );
}

open(INFILE, "/home/n02703942/perfdata/$date/vmstat.dat") or die $!;

open (OUTFILE, ">/home/n02703942/perfdata/$date/vmstat.csv") or die $!;

<INFILE>;
<INFILE>;
print OUTFILE "datetime,machinename,r,b,swpd,free,buff,cache,si,so,bi,bo,in,cs,us,sy,id,wa,st\n";

# Create csv file-- shift off date and time, then send rest to csv file comma-separated rather than space-separated.
while (<INFILE>)
{
     my @thisline=split(/\s+/, $_);
     $shiftdate = shift(@thisline);
     $shifttime = shift(@thisline);
     print OUTFILE "$shiftdate ";
     print OUTFILE "$shifttime\,";
     local $" = ','; # local output field separator
     print OUTFILE "@thisline\n";
}

close INFILE;
close OUTFILE;
