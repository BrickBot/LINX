# Linx
Control a Lego robot via a webserver or console

[Archive of Original Website](http://web.archive.org/web/20081230142619/http://www.testphase.at/linx/)

## How to prepare a Lego robot to be controled via the web (on a win32 System):

I. Required Software:
  - A web server (e.g. Apache - http://www.apache.org)
  - Perl 5.0 (or newer) for win32 (http://www.perl.com/)
  - Perl modules:
    + [Win32::API](https://metacpan.org/pod/Win32::API) (version used was 0.011)
    + [Win32::SerialPort](https://metacpan.org/pod/Win32::SerialPort)  (version used was 0.18)
      * Linux version of SerialPort – [Device::SerialPort](https://metacpan.org/pod/Device::SerialPort)
    + NOTE: Subsequent to this project’s original release, there is also the [Lego::RCX](https://github.com/BrickBot/perl-LEGO-RCX) module
  - nqc
  - `linx.nqc`, `linxServer.pl`
	
II. Setup:
  A. Connect the tower to a serial-port
      * Open a dos-console and set the variable RCX_PORT to the port 
        - `set RCX_PORT=COM1` (or COM2)
  B. Load linx.nqc to the robot using nqc.exe
      * `nqc -c -d linx.nqc`
  C. Install and run the webserver and connect to linx.html
  D. Run the linx-Server
      * `perl linxServer.pl`
  E. Ready
	
III. Troubles:
  * joreg [at] testphase.at
	
IV. Also available:
  * cybertalk.pl:  A Perl program to control the robot via a DOS console
  * talkrcx.pl:  A Perl program to communicate with a robot via Linux
    - talkrcx.pl by Paul Haas [archive of Paul’s original website](http://web.archive.org/web/20031003183930/http://hamjudo.com/rcx/)
