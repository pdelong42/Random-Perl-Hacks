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
