#!/usr/bin/perl -s

########################################################
##
## archpage -- simple script to send an archwireless 
##             page via the archwireless.net "Send a 
##             Message" web page.
##
##    usage: archpage [-e] [PIN] 
##       -e         use editor rather than STDIN 
##       <PIN>      destination pager PIN number
##
## Pager message is composed by calling the environment
## EDITOR or default.
##
##    (c) Rob Muhlestein Sat Mar  3 11:13:36 PST 2001
##        Released under GPL

## set to default PIN number
     my $PIN = '<default PIN number>';

## set to default editor
     my $editor = 'vi';

## set to prefix for temporary message file, process ID
## will be added during editing and file removed later.
     my $tmp_file_prefix = '/tmp/archpage';

#### END Config

$PIN = $ARGV[0] if $ARGV[0];
$editor = $ENV{EDITOR} if $ENV{EDITOR};
my $message='';

if ($e){
        system "$editor $tmp_file_prefix$$";
        undef $/;open FILE, "$tmp_file_prefix$$";
        $message=<FILE>; close FILE;
        unlink "$tmp_file_prefix$$";
} else {
        undef $/;
        $message=<STDIN>;
}

## URL encode (escape '&','=') and remove line breaks
$message =~ s/\n//g;
$message =~ s/\r//g;
print "Sending message to archwireless.net: $message ...";
$message =~ s/\&/\%26/g;
$message =~ s/\=/\%3D/g;

## construct HTTP client (i.e. lynx) command and exec
my $command = "lynx - <<EOF\n" . <<EOM;
http://www.archwireless.net/cgi-bin/wwwpage.exe
-post_data
PIN=$PIN&Q1=1&MSSG=$message&firstSubmit=Send ---
EOF
EOM

exec $command


