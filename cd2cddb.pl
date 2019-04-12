    #!/usr/bin/perl
     
    ###############################################################################
    # This little perl script serves the CD-text of a CD currently in the drive
    # as CDDB server. So any CD-ripper software which is capable of querying a
    # CDDB server can get the CD-text off a CD :-)
    #
    # Copyright (C) 2015 David Schueler <david.schueler1982@gmail.com>
    #
    # This library is free software; you can redistribute it and/or
    # modify it under the terms of the GNU Lesser General Public
    # License as published by the Free Software Foundation; either
    # version 2.1 of the License, or (at your option) any later version.
    #
    # This library is distributed in the hope that it will be useful,
    # but WITHOUT ANY WARRANTY; without even the implied warranty of
    # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
    # Lesser General Public License for more details.
    #
    # You should have received a copy of the GNU Lesser General Public
    # License along with this library; if not, write to the Free Software
    # Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
    ################################################################################
     
    { ###############################################
    package CdTextWebServer;
     
    use HTTP::Server::Simple::CGI;
    use base qw(HTTP::Server::Simple::CGI);
    use Device::Cdio;
    use Device::Cdio::Device;
    use Data::Dumper;
     
    use constant DEBUG => 0;
     
    my %dispatch = (
        '/cdtext' => \&process_cdtext,
    );
     
    sub handle_request {
        my $self = shift;
        my $cgi  = shift;
        my $path = $cgi->path_info();
        my $handler = $dispatch{$path};
        if (ref($handler) eq "CODE") {
            print "HTTP/1.0 200 OK\r\n";
            $handler->($cgi);
        } else {
            print "HTTP/1.0 404 Not found\r\n";
            print $cgi->header,
                $cgi->start_html('Not found'),
                $cgi->h1('Not found'),
                $cgi->end_html;
        }
    }
     
    sub process_cdtext {
        my $cgi  = shift;   # CGI.pm object
        return if !ref $cgi;    
     
        my @req = split(' ',$cgi->param('cmd'));
     
        print $cgi->header;
        # print Dumper \@req;
     
        if (shift @req ne 'cddb') {
            print "500 Command unimplemented";
            return;
        }
     
        $cmd = shift @req;
        if ($cmd eq 'query') {
            cddb_query(\@req);
        } elsif ($cmd eq 'read') {
            cddb_read(\@req);
        } else {
            print "500 Command unimplemented";
            return;
        }
    }
     
    sub cddb_query {
        my $r = shift;
        my @req = @{$r};
        #print Dumper \@req;
        my $cddbid = shift @req;
        my $notrks = shift @req;
        my @offsets;
        for(my $i=0; $i<$notrks;++$i) {
            push @offsets, shift(@req);
        }
        my $nosecs = shift @req;
        print STDERR "--- query(): ---\n" if (DEBUG);
        print STDERR "discid: $cddbid\n" if (DEBUG);
        print STDERR "notrks: $notrks\n" if (DEBUG);
        print STDERR "offsets:",Dumper(\@offsets),"\n" if (DEBUG);
        print STDERR "nosecs: $nosecs\n" if (DEBUG);
       
        my $found_cd = 0;
        my $cd_drives = Device::Cdio::get_devices($perlcdio::DRIVER_DEVICE);
        foreach my $cd_drive (@$cd_drives) {
            print STDERR "Accessing $cd_drive...\n" if (DEBUG);
            my $dev = Device::Cdio::Device->new($cd_drive);
     
            my @hwinfo = $dev->get_hwinfo();
            print STDERR "Drive vendor: ",$hwinfo[0],"\n" if (DEBUG);
            print STDERR "Drive model: ",$hwinfo[1],"\n" if (DEBUG);
            print STDERR "Drive version: ",$hwinfo[2],"\n" if (DEBUG);
     
            my $disc_mode = $dev->get_disc_mode();
            next if !$disc_mode; # No disc in drive
     
            print STDERR "Disc type: $disc_mode\n" if (DEBUG);
            next if $disc_mode ne "CD-DA"; # no CD-DA -> CD Digital Audio
     
            my $discid = sprintf("%08x",$dev->get_cddb_discid());
            printf STDERR "discid: $discid\n" if (DEBUG);
     
            if ($discid eq $cddbid) {
                $found_cd = $dev;
                last;
            }
        }
        if (!$found_cd) {
            print "202 No disc found with id $cddbid in any drive.";
            print STDERR "No disc found with id $cddbid in any drive.\n" if (DEBUG);
            return;
        }
        my $cdtext = $found_cd->get_disk_cdtext();
        print STDERR "Artist: ",$cdtext->{PERFORMER},"\n" if (DEBUG);
        print STDERR "Title: ",$cdtext->{TITLE},"\n" if (DEBUG);
     
        print "200 misc $cddbid ",$cdtext->{PERFORMER}," / ",$cdtext->{TITLE};
     
        #my $notracks = $dev->get_num_tracks();
        #print STDERR "tracks: $notracks\n";
        #for(my $t=1;$t<=$notracks;$t++){
        #   my $trtxt = $dev->get_track_cdtext($t);
        #   print STDERR "Track $t: ",%{$trtxt}->{PERFORMER}," - ",%{$trtxt}->{TITLE},"\n";
        #};
        #print STDERR "\n";
    }
     
    sub cddb_read {
        my $r = shift;
        my @req = @{$r};
        #print Dumper \@req;
        my $genre = shift @req;
        my $cddbid = shift @req;
     
        print STDERR "--- read(): ---\n" if (DEBUG);
        print STDERR "discid: $cddbid\n" if (DEBUG);
        print STDERR "genre: $genre\n" if (DEBUG);
       
        my $found_cd = 0;
        my $cd_drives = Device::Cdio::get_devices($perlcdio::DRIVER_DEVICE);
        foreach my $cd_drive (@$cd_drives) {
            print STDERR "Accessing $cd_drive...\n" if (DEBUG);
            my $dev = Device::Cdio::Device->new($cd_drive);
     
            my @hwinfo = $dev->get_hwinfo();
            print STDERR "Drive vendor: ",$hwinfo[0],"\n" if (DEBUG);
            print STDERR "Drive model: ",$hwinfo[1],"\n" if (DEBUG);
            print STDERR "Drive version: ",$hwinfo[2],"\n" if (DEBUG);
     
            my $disc_mode = $dev->get_disc_mode();
            next if !$disc_mode; # No disc in drive
     
            print STDERR "Disc type: $disc_mode\n" if (DEBUG);
            next if $disc_mode ne "CD-DA"; # no CD-DA -> CD Digital Audio
     
            my $discid = sprintf("%08x",$dev->get_cddb_discid());
            printf STDERR "discid: $discid\n" if (DEBUG);
     
            if ($discid eq $cddbid) {
                $found_cd = $dev;
                last;
            }
        }
        if (!$found_cd) {
            print "401 $genre $cddbid No such disc found in any drive.";
            print STDERR "No disc found with id $cddbid in any drive.\n" if (DEBUG);
            return;
        }
       
        my $cdtext = $found_cd->get_disk_cdtext();
        #print STDERR "Artist: ",$cdtext->{PERFORMER},"\n" if (DEBUG);
        #print STDERR "Title: ",$cdtext->{TITLE},"\n" if (DEBUG);
     
        print "210 $genre $cddbid CD database entry follows (until terminating `.')\n\n";
        print "DISCID=$cddbid\n";
        print "DTITLE=",$cdtext->{PERFORMER}," / ",$cdtext->{TITLE},"\n";
        print "DYEAR=\n";
        print "DGENRE=\n";
     
        my $notracks = $found_cd->get_num_tracks();
        print STDERR "tracks: $notracks\n" if (DEBUG);
        for(my $t=1;$t<=$notracks;$t++){
            my $trtxt = $found_cd->get_track_cdtext($t);
            print "TTITLE",$t-1,"=",$trtxt->{PERFORMER}," / ",$trtxt->{TITLE},"\n";
            print STDERR "Track $t: ",$trtxt->{PERFORMER}," - ",$trtxt->{TITLE},"\n" if (DEBUG);
        };
     
        print "EXTD=\n";
        for(my $t=0;$t<$notracks;$t++){
            print "EXTT$t=\n";
        }
     
        print "PLAYORDER=\n.\n";
    }
     
    } ###############################################
     
    my $server = CdTextWebServer->new();
    $server->host('127.0.0.1');
    $server->port(4200);
    $server->run();
     
    #$cd_drives = Device::Cdio::get_devices($perlcdio::DRIVER_DEVICE);
    #foreach my $drive (@$cd_drives) {
    #   print "--- Drive $drive -------------\n";
    #   my $dev = Device::Cdio::Device->new($drive);
    #   my @hwinfo = $dev->get_hwinfo();
    #   print "vendor: ",$hwinfo[0],"\n";
    #   print "model: ",$hwinfo[1],"\n";
    #   print "version: ",$hwinfo[2],"\n";
    #   my $disc_mode = $dev->get_disc_mode();
    #   next if !$disc_mode;
    #   print "disc: $disc_mode\n"; #CD-DA -> CD Digital Audio
    #   my $notracks = $dev->get_num_tracks();
    #   print "tracks: $notracks\n";
    #   my $discid = $dev->get_cddb_discid();
    #   print "discid: $discid\n";
    #   my $cdtext = $dev->get_disk_cdtext();
    #   print "Artist: ",%{$cdtext}->{PERFORMER},"\n";
    #   print "Title: ",%{$cdtext}->{TITLE},"\n";
    #   for(my $t=1;$t<=$notracks;$t++){
    #       my $trtxt = $dev->get_track_cdtext($t);
    #       print "Track $t: ",%{$trtxt}->{PERFORMER}," - ",%{$trtxt}->{TITLE},"\n";
    #   };
    #}
     
    #################################################################################################################################################################################################
    # CDDB Request Example:
    #
    # GET /~cddb/cddb.cgi?cmd=cddb+query+a80efa0d+13+150+20398+35018+51204+70562+88773+107150+121419+139002+158387+174993+192091+220888+3836&hello=private+free.the.cddb+Grip+3.3.1&proto=5 HTTP/1.1
    # Host: freedb.freedb.org
    # Accept: */*
    # User-Agent: Grip 3.3.1
    #
    # HTTP/1.1 200 OK
    # Date: Sat, 21 Feb 2015 08:31:10 GMT
    # Server: Apache/2.0.54 (Debian GNU/Linux)
    # Expires: Sat Feb 21 09:31:10 2015
    # Content-Type: text/plain; charset=ISO-8859-1
    # Transfer-Encoding: chunked
    #
    # 2d
    # 200 rock a80efa0d In Extremo / Sterneneisen
    #
    # 0
    #
    # ------------------------------------------
    #
    # GET /~cddb/cddb.cgi?cmd=cddb+read+rock+a80efa0d&hello=private+free.the.cddb+Grip+3.3.1&proto=5 HTTP/1.1
    # Host: freedb.freedb.org
    # Accept: */*
    #
    # User-Agent: Grip 3.3.1
    #
    #
    #
    # HTTP/1.1 200 OK
    # Date: Sat, 21 Feb 2015 08:31:10 GMT
    # Server: Apache/2.0.54 (Debian GNU/Linux)
    # Expires: Sat Feb 21 09:31:10 2015
    # Content-Type: text/plain; charset=ISO-8859-1
    # Transfer-Encoding: chunked
    #
    # 40c
    # 210 rock a80efa0d CD database entry follows (until terminating `.')
     
    # # xmcd
    # #
    # # Track frame offsets:
    # #       150
    # #       20398
    # #       35018
    # #       51204
    # #       70562
    # #       88773
    # #       107150
    # #       121419
    # #       139002
    # #       158387
    # #       174993
    # #       192091
    # #       220888
    # #
    # # Disc length: 3836 seconds
    # #
    # # Revision: 5
    # # Processed by: cddbd v1.5.2PL0 Copyright (c) Steve Scherf et al.
    # # Submitted via: ExactAudioCopyFreeDBPlugin 1.0
    #
    # DISCID=a80efa0d
    # DTITLE=In Extremo / Sterneneisen
    # DYEAR=2011
    # DGENRE=Mittelalterrock
    # TTITLE0=Zigeunerskat
    # TTITLE1=Gold
    # TTITLE2=Viva la Vida
    # TTITLE3=Siehst Du das Licht
    # TTITLE4=Stalker
    # TTITLE5=Hol die Sterne (feat. Der Graf)
    # TTITLE6=Sterneneisen
    # TTITLE7=Zauberspruch No. VII
    # TTITLE8=Auge um Auge
    # TTITLE9=Schau zum Mond
    # TTITLE10=Unsichtbar (feat. Mille Petrozza)
    # TTITLE11=Ich vermiss Dich
    # TTITLE12=Daten-CD
    # EXTD=
    # EXTT0=
    # EXTT1=
    # EXTT2=
    # EXTT3=
    # EXTT4=
    # EXTT5=
    # EXTT6=
    # EXTT7=
    # EXTT8=
    # EXTT9=
    # EXTT10=
    # EXTT11=
    # EXTT12=
    # PLAYORDER=
    # .
    #
    # 0
