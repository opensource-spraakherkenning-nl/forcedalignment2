# writes the word tier to flat txt

use open qw(:std :utf8);
use utf8;

$flag = 0;
while (<STDIN>)
  {
  chomp;
  if (($flag) & (m/\"IntervalTier\"/)) { $flag = 0; }
  if ($flag)
    {
    # if (m/^([\.0-9]+)$/) { $onset = $offset; $offset = $1; }
    # if (m/^\"([\<\>a-zA-Z]+)\"$/) { $word = $1; printf("%f %f %s\n", $onset, $offset, $word)}
    if (m/\"(.*)\"/) { $word = $1; if (!($word =~ m/^\s*$/)) {printf("%s ", $word)}}
    }
   if (m/\"[Ww]ord(s|)\"/) { $flag = 1; }
  }
printf("\n");
