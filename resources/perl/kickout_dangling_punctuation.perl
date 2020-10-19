
### Radboud University, CLST, Nijmegen, NL
### developed for internal R&D purposes 2010-2019
use open qw(:std :utf8);

use utf8;



while (<STDIN>)
  {
  chomp;
  @tok = split(/\s+/);
  
  for ($i = 0; $i <= $#tok; $i++)
    {
    $tok[$i] =~ s/^\s+//;
    $tok[$i] =~ s/\s+$//;
    if ($tok[$i] =~ m/^\W+$/) { $tok[$i] = ""; }
    }
  
  $res = join(" ", @tok);
  $res =~ s/\s+/ /g;

  printf("%s\n", $res);
  }



