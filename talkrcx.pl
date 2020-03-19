#!/usr/bin/perl -w
#
# $Id: talkrcx.txt,v 1.3 1998/10/08 03:44:26 paulh Exp $
#
# Talk to your RCX, in hex.
#  Written by Paul Haas, http://hamjudo.com.
# Most of what I know about the RCX communication protocol came from
# came from reading Kekoa Proudfoot's webpage, 
#  http://graphics.stanford.edu/~kekoa/rcx/index.html
#
# Most of what the rest of what I know about the RCX came from the
# Lego Robotics web page http://www.crynwr.com/lego-robotics
# maintained by Russell Nelson.
#
# You must read those pages to understand this program.
# 
# This is almost the very first release, 0.2.  It's got a bunch of limitations.
# It is not tolerant of communication errors.
#
# Set the serial port to match where you plugged in your IR tower.
# (This should be a command line parameter or something.)
$port = "/dev/cua1";
open("portfh","+<$port") || die "opening $port for input: $!";
#
# http://www.crynwr.com/lego-robotics says:
#    The IR protocol associated with sending a "message" to the RCX is
#    pretty simple. Bit encoding is 2400 baud, NRZ, 1 start, 8 data, odd
#    parity, 1 stop bit.
# Make it so.
system("stty 2400 -echo parodd parenb cs8 -cstopb raw < $port");

# All messages start the same way.
$messageHeader = hex2str("55 ff 00");

#
# Every other message has the sequence number bit set.
# This program makes the sequence bit the inverse of the bit
# from the previous message.  The "1234" is just an arbitrary
# previous message.
$message = "1234";
print "talkrcx Version 0.2, using $port for the serial port.\n";
print "Type> ";
while(<>) {
    $y = hex2str($_);
    $message = toMsg($y,$message);
    $response = str2hex (getMsg("portfh",$message));
    print "In: $response\n";
    print "Type> ";
}
close("portfh");

#
# If we don't like the string we get back from the RCX, 
# complain about it.  This could use work...
sub msgError {
    local($errorstr,$message,$response) = @_;
    $ostr = str2hex($message);
    $istr = str2hex($response);
    print STDERR "$errorstr: sent $ostr\n       got $istr\n";
    return '';
}
sub getMsg {
    local($portfh, $outmsg) = @_;
    local($inmsg,$inbuff,$rin) = ('','','');
    local($sum,$sumGood) = (0,0);
    
#
# Send the message to the RCX.
    sendMsg($portfh,$outmsg);
#
# Read it back.  This reads stuff until there is no character
# for 0.3 seconds in a row.  If this knew the reply length,
# it could do something smarter.  As it is, sometime .3 seconds
# isn't long enough.
    vec($rin,fileno("portfh"),1) = 1;
    while ( select($rout=$rin, undef, undef, 0.3) ) {
	$char = '';
	sysread ("portfh",$char,1);
	$inbuff .= $char;
    }
#
# Make sure that the reply includes an accurate echo of our
# request.
    if ( 0 != index($inbuff,$outmsg)){
	return msgError("No echo",$outmsg,$inbuff);
    }
#
# Then it should have the standard message header.
    $inbuff = substr($inbuff,length($outmsg));
    if ( $inbuff !~ s/^$messageHeader//s ){
	return msgError("No response header",$outmsg,$inbuff);
    }
#
# Now make sure each character is followed by its complement.
# Also keep track of the checksum.
    while( $inbuff =~ s/^(..)//s ) {
	$cpair = $1;
	$oc = ord($cpair);
	if ( compBad ($cpair) ) {
	    return msgError(sprintf("bad complement %02x",$oc),$outmsg,$inbuff);
	}
	$inmsg .= chr($oc);
	$sumGood = $sum == $oc; 
	$sum = 0xff & ( $sum + $oc);
    }
    if ( ! $sumGood ) {
    	return msgError("Bad checksum",$outmsg,$inbuff);
    }
    $inmsg =~ s/.$//s;  # Remove checksum from response
    substr($inmsg,0,1) = chr(ord($inmsg) & 0xf7); # remove sequence #
    return $inmsg;
}
#
# Given a pair of characters, return true if they are not a complements.
sub compBad {
    local($pair) = @_;
    local ($c1,$c2) = split(//,$pair);
    return (ord($c1) != (0xff ^ ord($c2)) );
}
    
#
# send some characters.
sub sendMsg {
    local($portfh, $msg) = @_;
    syswrite $portfh, $msg, length($msg);
}

#
# Convert a string into hex for easier viewing by people.
sub str2hex {
    local ($line) = @_;
    $line =~ s/(.)/sprintf("%02x ",ord($1))/eg;
    return $line;
}

#
# $string = hex2str ( $hexstring );
# Where string is of the form "xx xx xx xx" where x is 0-9a-f
# hex numbers are limited to 8 bits.
sub hex2str {
    local ($l) = @_;
    $l =~ s/([0-9a-f]{1,2})\s*/sprintf("%c",hex($1))/egi;
    return $l;
}

#
# Take a request and make it into a happy packet.
# Note that the sequence number bit should be the opposite
# of the last packet.  We use the last packet for that
# information.
# Packets start with a standard 3 byte header, the data
# and then end with a checksum.  Every byte is followed
# by its complement.
sub toMsg {
    local ($str,$lastMsg) = @_;
    local ($msg) = "";
    local ($sum, $c, $invC,$seqno);
    $sum = 0;  # Checksum;
    $msg = $messageHeader; 
    $seqno = 0x08 != (0x08 & ord(substr($lastMsg,3,1)));
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
