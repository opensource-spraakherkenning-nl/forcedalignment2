# ali to tg
# this script deals with the ali files with four columns (start, dus, phone, and the forth column (word))

use open qw(:std :utf8);
use utf8;


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


printf("File type = \"ooTextFile\"\n");
printf("Object class = \"TextGrid\"\n");

printf("xmin = 0\n"); 
printf("xmax = %f\n", $end_in_utt);
printf("tiers? <exists>\n"); 
print("size = 2\n"); # this is the number of tiers
printf("item []:\n");

###########################

printf("    item [1]:\n");
printf("        class = \"IntervalTier\"\n");
printf("        name = \"phone\"\n"); 
printf("        xmin = 0.00\n");
printf("        xmax = %f\n", $end_in_utt);
printf("        intervals: size = %d\n", $nr_of_phones);
 
for ($j = 0; $j < $nr_of_phones-1; $j++)
{
printf("        intervals [%d]:\n", $j+1);
printf("            xmin = %f\n", $phonestart[$j]);
printf("            xmax = %f\n", $phonestart[$j+1]);
printf("            text = \"%s\"\n", $phone[$j]);
}
$j = $nr_of_phones-1;
printf("        intervals [%d]:\n", $j+1);
printf("            xmin = %f\n", $phonestart[$j]);
printf("            xmax = %f\n", $end_in_utt);
printf("            text = \"%s\"\n", $phone[$j]);


#############################

printf("    item [2]:\n");
printf("        class = \"IntervalTier\"\n");
printf("        name = \"word\"\n"); 
printf("        xmin = 0.00\n");
printf("        xmax = %f\n", $end_in_utt);
printf("        intervals: size = %d\n", $nr_of_words);
 
for ($j = 0; $j < $nr_of_words-1; $j++)
{
printf("        intervals [%d]:\n", $j+1);
printf("            xmin = %f\n", $wordstart[$j]);
printf("            xmax = %f\n", $wordstart[$j+1]);
printf("            text = \"%s\"\n", $word[$j]);
}
$j = $nr_of_words-1;
printf("        intervals [%d]:\n", $j+1);
printf("            xmin = %f\n", $wordstart[$j]);
printf("            xmax = %f\n", $end_in_utt);
printf("            text = \"%s\"\n", $word[$j]);







