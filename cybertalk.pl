#! perl -w

# version 1.0 of cybertalk.pl #####################################
####################################################################
############### hacked by jörg dießl, fall 99 (joreg@testphase.at) #
####################################################################
# based on the original version talkrcx.txt,v 1.3 ##################
# written by Paul Haas (http://www.hamjudo.com/rcx/talkrcx.txt) ####
####################################################################
# besides a perl version (>5) this script requires two modules #####
# installed on your system: ########################################
# Win32::API available under http://www.divinf.it/dada/perl/Win32API-0.011.zip
# Win32::SerialPort available under http://members.aol.com/Bbirthisel/Win32-SerialPort-0.18.tar.gz
####################################################################
####################################################################
# this server listens to port 9000 for the following commands:	   #
# "vor", "stop", "zruck" and "view" 							   #
# corresponding to the command a string is sent to the serial-port #
# (to which a cybermaster should be connected) that starts one	   #
# of the four tasks that may be stored in a cybermaster 		   #
####################################################################
# before the server starts listening...							   #
# ...the serial-port is opened									   #
# ...the firmware is unlocked									   #
# ...variables 0 and 1 are set to 1 (starting values for viewchange [required in loop.nqc])
# ...the power down delay is set to 0 (infinite)				   #
####################################################################
####################################################################
# linx for more info on rcx-programming: ###########################
# http://graphics.stanford.edu/~kekoa/rcx/ #########################
# http://home.concepts.nl/~bvandam/ ################################
# http://www.crynwr.com/lego-robotics/ #############################
####################################################################
# this script is very primitiv and therefore includes no kind of ###
# errorhandling or other highly sophisticated stuff! ###############
####################################################################
# have a lot! ######################################################

use Win32::SerialPort 0.15;

my $PortName = "COM1";
my $PortObj = new Win32::SerialPort ($PortName)
       || die "Can't open $PortName: $^E\n";    # $quiet is optional

$PortObj->databits(8);
$PortObj->baudrate(2400);
$PortObj->parity("odd");
$PortObj->parity_enable(1);
$PortObj->stopbits(1);
$PortObj->buffers(4096, 4096);
$PortObj->dtr_active(1);
$PortObj->rts_active(1);            

if ($PortObj->write_settings != 1) 
{
	print "Any kind of error occured!";
	undef $PortObj;
}

#This program makes the sequence bit the inverse of the bit
# from the previous message.  The "1234" is just an arbitrary
# previous message.
$message = "1234";
# all messages start the same way.
$messageHeader = hex2str("FE 0 0 FF");
# all messages we recieve should inlcude:

# Every other message has the sequence number bit set.
# This program makes the sequence bit the inverse of the bit
# from the previous message.  The "1234" is just an arbitrary
# previous message.

print "Unlocking the cybermaster firmware...\n";
# "Do you byte, when I knock?"
$unlockMSG = "FE	00	00	FF	A5	5A	44	BB	6F	90	20	DF	79	86	6F	90	75	8A	20	DF	62	9D	79	86	74	8B	65	9A	2C	D3	20	DF	77	88	68	97	65	9A	6E	91	20	DF	49	B6	20	DF	6B	94	6E	91	6F	 90	63	9C	6B	94	3F	C0	85	7A";
$unlockMSG = hex2str($unlockMSG);
$response = str2hex (getMsg($unlockMSG));

print "Cybermaster connected to $PortName is under your control now.\n";
print "Enter commands in hex-code!\n";
print "command> ";

while(<>) 
{
	$y = hex2str($_);
    $message = toMsg($y,$message);
    print "sending>" . str2hex($message) . "\n";
    $response = str2hex (getMsg($message));
    
    print "\n";
    print "command> ";
}


#close the port 
undef $PortObj;

# If we don't like the string we get back from the RCX, 
# complain about it.  This could use work...
sub msgError 
{
    local($errorstr,$message,$response) = @_;
    $ostr = str2hex($message);
    $istr = str2hex($response);
    print STDERR "$errorstr: sent $ostr\n       got $istr\n";
    return '';
}

sub getMsg 
{
    local($outmsg) = @_;
	# Send the message to the RCX.
	sendMsg($outmsg);
        
        sleep(1);
        $inbuff = $PortObj->input;
        print "response> " . str2hex($inbuff) . "\n";
       
}

sub sendMsg 
{
    local($msg) = @_;
    $count_out = $PortObj->write($msg);
	warn "write incomplete\n"     if ( $count_out != length($msg) );
}

# Convert a string into hex for easier viewing by people.
sub str2hex 
{
    local ($line) = @_;
    $line =~ s/(.)/sprintf("%02x ",ord($1))/eg;
    return $line;
}

# $string = hex2str ( $hexstring );
# Where string is of the form "xx xx xx xx" where x is 0-9a-f
# hex numbers are limited to 8 bits.
sub hex2str 
{
    local ($l) = @_;
    $l =~ s/([0-9a-f]{1,2})\s*/sprintf("%c",hex($1))/egi;
    return $l;
}

# Take a request and make it into a happy packet.
# Note that the sequence number bit should be the opposite
# of the last packet.  We use the last packet for that
# information.
# Packets start with a standard header!
# note:
# 4 byte for the cybermaster: FE 00 00 FF
# 3 byte for the mindstorms: 55 ff 00
# followed by the data and then end with a checksum. Every byte is followed
# by its complement.

sub toMsg 
{
    local ($str,$lastMsg) = @_;
    local ($msg) = "";
    local ($sum, $c, $invC,$seqno);
    $sum = 0;  # Checksum;
    $msg = $messageHeader; 
    $seqno = 0x08 != (0x08 & ord(substr($lastMsg,4,1)));
    if ( $seqno ) {
        substr($str,0,1) = chr(ord($str) | 0x08);
    } else {
        substr($str,0,1) = chr(ord($str) & 0xf7);
    }
    foreach $c ( split(//,$str) ) {
        $invC = chr(0xff ^ ord($c));
        $msg .= $c . $invC;
        $sum += ord($c);
    }
    $sum &= 0xff;
    $msg .= chr($sum) . chr(0xff ^ $sum);
    return $msg
}
