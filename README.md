# cd2cddb - CD Text to CDDB Server Perl Script

Here's a little perl script which uses the cdio library to read the CD-text from a CD and serves it as CDDB server. So any CD-ripper software which is capable of querying a CDDB server can get the CD-text off a CD :-)

### How to get it run:

First you have to install Perl and the cdio library (which usually comes with your Linux distro).  
Then you need to install the Device::Cdio Perl module.  
As I'm writing this the latest version is 0.3.0. Unfortunately this version only supports an older version of libcdio. You need a patch to get Device::Cdio running with a current libcdio.
