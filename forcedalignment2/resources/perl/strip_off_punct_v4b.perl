
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
    if ($tok[$i] =~ m/\.$/) {$period_at_end = 1; $tok[$i] =~ s/[\.]+$//g; } else {$period_at_end = 0};

    # line removed
    # idem - see version 4


    if ($period_at_end) {$tok[$i] = $tok[$i] . "."};

    if (($tok[$i] eq "'s") | ($tok[$i] eq "'t") | ($tok[$i] eq "'m") | ($tok[$i] eq "'m") | ($tok[$i] eq "'k'"))
      {;}
    else
      {
      $tok[$i] =~ s/[\.\,\!\#\&\*\?\'\"\(\)\‘\…\'\"\:\;\¨]+//g; # extended set!
      }
    
    $keepassuch = 0;
    if (($tok[$i] =~ m/^[\.A-Za-z]+$/) & ($tok[$i] =~ m/\.[A-Za-z]/)) {$tok[$i] =~ s/\.+$/\./; $keepassuch = 1;} # looks like acronym
  if (!($keepassuch)) {$tok[$i] =~ s/\.//g;} 
    }
    
  printf("%s\n", join(" ", @tok));
  }



