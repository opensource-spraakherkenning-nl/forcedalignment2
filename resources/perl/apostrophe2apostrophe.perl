use open qw(:std :utf8);
use utf8; # essential!

while (<STDIN>)
  {
  chomp;
  s/\’/\'/g;
  printf("%s\n", $_);
  }

