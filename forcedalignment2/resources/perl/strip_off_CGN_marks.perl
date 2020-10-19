use open qw(:std :utf8);
use utf8;

while (<STDIN>)
  {
  chomp;
  @tok = split(/\s+/);
  for ($i = 0; $i <= $#tok; $i++)
    {
    $tok[$i] =~ s/\*.*$//;
    }
  printf("%s\n", join(" ", @tok));
  }
