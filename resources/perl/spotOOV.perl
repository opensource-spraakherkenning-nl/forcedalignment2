### Radboud University, CLST, Nijmegen, NL
### developed for internal R&D purposes 2010-2019
### Available under license Affero GLP v3.0 (AGPL-3.0)
# spot OOVs. Arg 1: lexicon

open(LEX, "<" . $ARGV[0]);

while (<LEX>)
  {
  chomp;
  @tok = split(/\s+/);
  $word{$tok[0]} = 1;
  }

while (<STDIN>)
  {
  chomp;
  @tok = split(/\s+/);
  for ($i = 0; $i <= $#tok; $i++)
    {
    if (defined($word{$tok[$i]}))
      {
      printf("%s %s\n", $tok[$i], 1);
      }
    else
      {
      printf("%s %s\n", $tok[$i], 0);
      }
    }
  } 
