# merges two dictionaries in the "overrule mode"
# format: orthography <tab> phone transcription
# call syntax:
# cat addon | merge_dict backgrounddict > merged_dict

use open qw(:std :utf8);
use utf8;


open(BGDICT, "<" . $ARGV[0]);

while (<STDIN>)
  {
  chomp;
  @tok = split(/\s+/);
  $ortho = $tok[0];
  $pron = join(" ", @tok[1..$#tok]);
  push(@{$ortho2pron_add{$ortho}}, $pron);
  $ortho_seen{$ortho} = 1;
  }

while (<BGDICT>)
  {
  chomp;
  @tok = split(/\s+/);
  $ortho = $tok[0];
  $pron = join(" ", @tok[1..$#tok]);
  push(@{$ortho2pron_bg{$ortho}}, $pron);
  $ortho_seen{$ortho} = 1;
  }

@allorthos = keys %ortho_seen;

for $ortho (sort {$a cmp $b} @allorthos)
  {
  if (defined($ortho2pron_add{$ortho}))
    {
    for $item (@{$ortho2pron_add{$ortho}})
      {
      printf("%s\t%s\n", $ortho, $item);
      }
    }
  else
    {
    for $item (@{$ortho2pron_bg{$ortho}})
      {
      printf("%s\t%s\n", $ortho, $item);
      }
    }
  }


