I started by finding the range of times that are spanned by the logs (roughly):

    [pdelong@localhost bitly-exercise]$ logRange() { ( head -1 $1 && tail -1 $1 ) | awk -F'[][]' '{print $2}'; }
    [pdelong@localhost bitly-exercise]$ logRange 2014-07-14_15.access.log 
    14/Jul/2014:15:00:01 +0000
    14/Jul/2014:15:18:51 +0000
    [pdelong@localhost bitly-exercise]$ logRange 2014-07-14_15.decodes.log 
    14/Jul/2014:15:00:01 +0000
    14/Jul/2014:15:04:37 +0000
    [pdelong@localhost bitly-exercise]$

It looks like we have a 19-minute slice of time for the access log, and a
5-minute slice of time for the "decodes" log (which happens to fall into the
first 5 minutes of the access log's range).

Next, a quick-and-dirty attempt at finding the client IPs that are hitting us
the most:

    [pdelong@localhost bitly-exercise]$ top10IP() { awk '{print $1}' $1 | sort | uniq -c | sort -nr | head; }
    [pdelong@localhost bitly-exercise]$ top10IP 2014-07-14_15.access.log 
       4066 23.227.176.34
        723 66.249.80.87
        663 216.46.7.162
        547 66.220.159.112
        528 66.220.159.118
        502 66.220.159.115
        384 38.104.59.18
        345 69.171.247.113
        328 173.252.120.118
        309 69.171.247.115
    [pdelong@localhost bitly-exercise]$ top10IP 2014-07-14_15.decodes.log 
       1777 168.143.172.211
       1499 173.192.79.101
       1421 23.227.176.34
       1341 23.227.176.35
        821 54.228.246.119
        818 140.109.21.214
        748 54.221.20.188
        720 69.164.222.192
        625 14.54.187.112
        611 46.236.24.52
    [pdelong@localhost bitly-exercise]$

However, parsing fields from the logs beyond the IP address will be onerous if
we limit ourselves to just using the shell and basic sed/awk usage (at-least
for me), so I've decided to switch to using Perl after this point (since it has
some pretty powerful regex features).

I'm cheating a little bit here, because I've repurposed a script I've already
written for very similar motivations.  I've made slight modifications to adapt
it to the log format used in this exercise.  (It's called ApacheLogParser.pl,
because I originally used it to parse Apache logs.  But naturally it can be
used on other webservers as well (e.g., Tomcat, nginx, etc.), since they all
use similar logging conventions.)

First, let's see what our most popular ten requests are:

    [pdelong@localhost bitly-exercise]$ ~/Stuff/bin/ApacheLogParser.pl -r -c -f request 2014-07-14_15.access.log | head 
    67055x -
    3640x GET / HTTP/1.1
    2051x HEAD / HTTP/1.1
    1247x GET /javascript-api.js?version=latest&login=marketwatch&apiKey=R_8762f368b71d4d4bba322c59fba00e91 HTTP/1.1
    1061x GET /javascript-api.js?version=latest&login=directadvert&apiKey=R_2c10a7f753092ba3160586072fbbe72f HTTP/1.1
    899x POST /data/info HTTP/1.1
    849x GET /javascript-api.js?version=latest&login=jornaloglobo&apiKey=R_7d4719122e4a3f2977791f8f0bc620cd HTTP/1.1
    710x GET /javascript-api.js?version=latest&login=jornalextra&apiKey=R_c24275b79724caceb2d02aacab3c4f45 HTTP/1.1
    654x POST /data/clicks HTTP/1.1
    606x GET /javascript-api.js?version=latest&login=tweettrackjs&apiKey=R_7e9987b2fd13d7e4e881f9cbb168f523 HTTP/1.1
    [pdelong@localhost bitly-exercise]$

Next, let's zoom-in on some particular requests.

There doesn't seem to be a whole lot of interesting stuff happening with that null request:

    [pdelong@localhost bitly-exercise]$ ~/Stuff/bin/ApacheLogParser.pl -r -c -m request='-' -f host 2014-07-14_15.access.log | head | ~/Stuff/bin/ReplaceIP.pl 
    114x  cpe-173-89-32-175.wi.res.rr.com 
    84x  dynamic-acs-24-101-117-185.zoominternet.net 
    78x  cpe-66-57-184-22.sc.res.rr.com 
    66x  c-50-172-52-98.hsd1.il.comcast.net 
    64x  c-71-234-165-2.hsd1.ct.comcast.net 
    63x  64-191-131-226.xdsl.qx.net 
    60x  d60-65-119-141.col.wideopenwest.com 
    59x  71-219-204-203.clsp.qwest.net 
    57x  108-225-173-228.lightspeed.jcvlfl.sbcglobal.net 
    53x  Dynamic-IP-181583068.cable.net.co 
    [pdelong@localhost bitly-exercise]$

The traffic seems pretty evenly distributed across clients.  Normally, this is
the kind of thing I see from an F5 (or other load-balancer), because it's just
opening and closing a socket, without staring an HTTP conversation, just to see
if there's anything listening (to monitor the health / availability of the pool
members).

The fact that it's coming from garden variety clients seems a little weird to
me, and slightly suspicious.  It leads me to believe that they're bots probing
for vicitims.  Maybe this is something to follow-up on if we're bored, but we
seem to have bigger fish to fry right now (seems like it would be a sucker's
game of whack-a-mole anyway).

Slightly more intersting is the *actual* HTTP requests that are most frequesnt right now:

    [pdelong@localhost bitly-exercise]$ ~/Stuff/bin/ApacheLogParser.pl -r -c -m request='GET / HTTP/1.1' -f host -f status 2014-07-14_15.access.log | head -3 | ~/Stuff/bin/ReplaceIP.pl 
    2031x  23-227-176-34-customer-incero.com  301
    61x  173.252.73.113  301
    44x  173.252.73.112  301
    [pdelong@localhost bitly-exercise]$ ~/Stuff/bin/ApacheLogParser.pl -r -c -m request='HEAD / HTTP/1.1' -f host -f status 2014-07-14_15.access.log | head -3 | ~/Stuff/bin/ReplaceIP.pl 
    2031x  23-227-176-34-customer-incero.com  405
    4x  ec2-54-228-246-119.eu-west-1.compute.amazonaws.com  405
    3x  c-67-189-172-11.hsd1.ct.comcast.net  405
    [pdelong@localhost bitly-exercise]$ 

I limited it to three in each case, because it falls-off pretty quickly.  So we
seem to have one client making GET and HEAD requests for "/", about once or
twice a second (each).  We're responding to it with a permanent redirect (for
GET) and a method-not-allowed (for HEAD), which probably comes as no surprise
to us.

That second-level domain name also looks a little odd.  Who would register a
new second-level domain for each IP address they own?

Anyway, this client warrants further investigation.

It also may be worth looking into those two 173.252.73.* addresses, since they
don't have PTR records (which is usually suspicious).

Next, while there's a little time left, let's look at the "decodes" log:

    [pdelong@localhost bitly-exercise]$ ~/Stuff/bin/ApacheLogParser.pl -r -c -f host 2014-07-14_15.decodes.log | head | ~/Stuff/bin/ReplaceIP.pl
    1777x  168.143.172.211 
    1499x  173.192.79.101-static.reverse.softlayer.com 
    1421x  23-227-176-34-customer-incero.com 
    1341x  23-227-176-35-customer-incero.com 
    821x  ec2-54-228-246-119.eu-west-1.compute.amazonaws.com 
    818x  Tweet-Crawler.iis.sinica.edu.tw 
    748x  ec2-54-221-20-188.compute-1.amazonaws.com 
    720x  ewrap11.xydo.com 
    625x  14.54.187.112 
    611x  ded3124.sysms.net 
    [pdelong@localhost bitly-exercise]$ 

That top offendor is a little suspicious, since it has no PTR record.  Let's
have a closer look at the requests it's making:

    [pdelong@localhost bitly-exercise]$ ~/Stuff/bin/ApacheLogParser.pl -r -c -m host='^(168\.143\.172\.211)$' -f status -f request 2014-07-14_15.access.log | head
    36x 302 GET / HTTP/1.0
    27x 301 GET / HTTP/1.0
    6x 405 HEAD / HTTP/1.0
    5x 404 GET /mm-jul13 HTTP/1.0
    4x 404 GET /1rlnx1j HTTP/1.0
    2x 404 GET /apple-touch-icon-precomposed.png HTTP/1.0
    2x 404 GET /1wkudsq HTTP/1.0
    2x 404 GET /blog/ HTTP/1.0
    2x 404 HEAD /U42M82#.U8PqwDu3ulk.twitter HTTP/1.0
    2x 404 GET /1sR1UAenatpo.st/1sR1UAe HTTP/1.0
    [pdelong@localhost bitly-exercise]$ 

And let's look at the user-agent header values (if those can be trusted):

    [pdelong@localhost bitly-exercise]$ ~/Stuff/bin/ApacheLogParser.pl -r -c -m host='^(168\.143\.172\.211)$' -f agent 2014-07-14_15.access.log | head
    37x facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)
    25x Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; Trident/6.0)
    23x Facebot/1.0
    21x Mozilla/5.0 (compatible; Baiduspider/2.0; +http://www.baidu.com/search/spider.html)
    15x Microsoft Office Mobile/15.0
    9x help@dataminr.com
    8x -
    5x Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/34.0.1847.131 Safari/537.36
    5x Mozilla/5.0 (compatible; Genieo/1.0 http://www.genieo.com/webfilter.html)
    4x Mozilla/5.0 (iPhone; CPU iPhone OS 7_1_2 like Mac OS X) AppleWebKit/537.51.2 (KHTML, like Gecko) Version/7.0 Mobile/11D257 Safari/9537.53
    [pdelong@localhost bitly-exercise]$ 

This might actually be benign, considering the relatively harmless look of the
requests being made from that IP, and the spread of user-agent strings coming
from there (or maybe that's just what they *want* us to think).

Anyway, time's up.  I could keep mining these logs for patterns, but you need
to keep me honest too.
