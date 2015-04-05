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
