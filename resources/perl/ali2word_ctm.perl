# ali to ctm on word level
# this script deals with the ali files with four columns (start, dus, phone, and the forth column (word))

# audiofilename: optional argument
# channel: optional; default 1

use open qw(:std :utf8);
use utf8;

$audiofn = "audio";
if ($#ARGV >= 0)
  { $audiofn = $ARGV[0]; }
$channel = 1;
if ($#ARGV >= 1)
  { $channel = $ARGV[1]; }


$nr_of_phones = 0;
$nr_of_words = 0;

$linenumber = 0;
while (<STDIN>)
  {
  chomp;
  @tok = split(/\t/);
  $linenumber++;
  if ($linenumber == 2) {$start_in_utt = $tok[0];}
  if ($linenumber >= 2)
    {
    if (!($tok[2] =~ m/^\s*$/))
      {
      $phone[$nr_of_phones] = $tok[2];
      $phonestart[$nr_of_phones] = $tok[0];
      $nr_of_phones++;
      }
    if (($tok[3] =~ m/^\s*$/) & ($tok[2] ne "SIL")) {};
    if (($tok[3] =~ m/^\s*$/) & ($tok[2] eq "SIL")) {$tok[3] = "SIL";}
    if (($tok[3] =~ m/^\s*$/) & ($tok[2] eq "SPN")) {$tok[3] = "SPN";}
    if (!($tok[3] =~ m/^\s*$/)) 
      {
      $word[$nr_of_words] = $tok[3];
      $wordstart[$nr_of_words] = $tok[0];
      $nr_of_words++;
      }
    $end_in_utt = $tok[0]+$tok[1];
    }
  }



for ($j = 0; $j < $nr_of_words-1; $j++)
{
printf("%s\t%s\t%.3f\t%.3f\t%s\t0.99\n", $audiofn, $channel, $wordstart[$j], $wordstart[$j+1], $word[$j]);
}
$j = $nr_of_words-1;
printf("%s\t%s\t%.3f\t%.3f\t%s\t0.99\n", $audiofn, $channel, $wordstart[$j], $end_in_utt, $word[$j]);







