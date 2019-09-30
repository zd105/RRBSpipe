#!/usr/bin/perl
use strict;
use warnings;
use PerlIO::gzip;
use Getopt::Long;
use Cwd 'abs_path';
my $usage=<<"USAGE";
	name:    rrbs_GlobalMethy_batch
             It is designed for running Global Methylation profile of BS-seq in batch model.
			 (note: global used all sites; element used >=5x sites)
	
	version:1.0
    usage:   perl $0
	            -c <str>  cout file;
				-b <str>  element.bed file; "global" for genome wide stat;
				-t <str>  C type: CG,CHG or CHH;
				-o <str>  out file;
                -h <str>  help;
	author: zhangdu
	date:    2018-05-29
USAGE



my ($cout, $bed, $out, $cytosine,$help);
my %h;
GetOptions("b=s" =>  \$bed,
           "c=s" => \$cout,
		   "o=s" => \$out,
		   "t=s" => \$cytosine,
		   "h=s" => \$help
);
die $usage if $help;
die $usage unless $bed;
die $usage unless $cout;
die $usage unless $out;
die $usage unless $cytosine;

if( $bed eq "global"){
   open IN,"<:gzip", $cout or die $!;
   while(<IN>){
		chomp;
		my @a = split;
		#next if $a[0] ne $chr;
		next if($a[3] ne $cytosine);
        my $d = $a[6] + $a[7]; 
		$h{"d"} += $d;
        $h{"m"} += $a[6]
   }
   close IN;
   my $methyl =  $h{"d"} == 0 ? "NA" : sprintf("%.6f", $h{"m"} / $h{"d"});
   open OUT, ">$out" or die $!;
   print OUT join("\t", "Global", $h{"m"}, $h{"d"}, $methyl), "\n"; #global的甲基化水平是用全基因组 总mC/C算出来的
               # global C总深度 mC总深度 mC总深度/C总深度
   close OUT;
}else{

  open IN,"<:gzip", $cout or die " !! can not open file: $cout \n";
  while(<IN>){
	chomp;
	my @a = split;
	#next if $a[0] ne $chr;
    next if $a[3] ne $cytosine;
	my $d = $a[6] + $a[7];
    next if $d < 5;
	$h{$a[0]}{$a[1]} = $a[5]; # >=5x C位点的甲基化水平记录下来
  }
  close IN;
  
  open OUT, ">$out" or die $!;
  open BB, $bed or die " !! can not open file: $bed \n";
  while(<BB>){
	chomp;
	my @a = split;
	#next if $a[0] ne $chr;
	my $n = 0;
	my $m = 0;
	foreach my $i ($a[1]..$a[2]){
	    if(exists $h{$a[0]}{$i}){
			$n += 1;
			$m += $h{$a[0]}{$i};
	    }
    }
	my $meth = $n== 0 ? "NA" : sprintf("%.6f", $m/$n);	
	print OUT join("\t", $_, $meth),"\n"; # 输出bed中每条序列的平均甲基化水平(>=5x才算)
  }
  close BB;
  close OUT;
}

