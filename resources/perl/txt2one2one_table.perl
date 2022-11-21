# this scripts takes in an (utf8)  text file and produces an (utf8)  table with tab separated fields
# step 1: cleaning (stripping off everything to arrive at a G2P-feasible input)
# identifying [] intertext meta tags
# cooking the table
# three columns
# col 1: word form as found
# col 2: word form that goes into the FA
# col 3: word form found, prefixed with [] tag

# OUTPUT: tab separated utf8 text file, 3 columns

use open qw(:std :utf8);
use utf8; 

$tag = "";
$tagpresent = 0;

while (<STDIN>)
  {
  chomp;
  s/^\s+//;
  s/\s+$//;
  # is this a tag line?
#printf("INPUT: %s\n", $_);
#if (m/^\s*\[/) {printf("LEFT\n");}
#if (m/\]\s*$/) {printf("RIGHT\n");}

  if (m/^\s*\[.*\]\s*$/)
    { 
    $tag = $tag . "_" . $_; 
    # remove \t from tag, avoid \t in tag
    $tag =~ s/\t/ /g;
    $tagpresent = 1;
#   printf("TAG FOUND: %s\n", $tag);
    } 
  else
    {
    @tok = split(/\s+/);
    for ($i = 0; $i <= $#tok; $i++)
      {
      $found = $tok[$i];

      $cleaned = $found;
      $cleaned =~ s/\*.*$//; # strip off everything after first *
      if ($cleaned =~ m/^\s*\[(.*)\]\s*$/) # [x]
        {
        $cleaned = $1;
        }
      $cleaned =~ s/[\[\]\.\,\!\#\&\*\?\'\"\(\)\‘\…\'\"\:\;\¨]+//g; # z'n? N.A.P.?
      $tagged = $found;
#      printf("case A: %s\t%s\t%s\n", $found, $cleaned, $tagged);

      if ($found =~ m/([^\[]+)(\[.*\])/) # catches x[y]
        {
        $prefix = $1;
        $postfix = $2;
        $cleaned = $prefix;
        $cleaned =~ s/[\[\]\.\,\!\#\&\*\?\'\"\(\)\‘\…\'\"\:\;\¨]+//g; # z'n? N.A.P.?
        $tagged = $prefix . $postfix;
#        printf("case B: %s\t%s\t%s\n", $found, $cleaned, $tagged);
        } 

      #$tagged = $found;
      if (($i==0) & ($tagpresent))  {$tag =~ s/^_//; $tagged = $tag . "_" . $found; $tag = ""; $tagpresent = 0;}

      # printf("%s\t%s\t%s\n", $found, $cleaned, $tagged);
      printf("%s\t%s\t%s\n", $found, lc($cleaned), $tagged);
      }
    }
  }

