#!/usr/bin/perl
use strict;
use FindBin qw/$Bin/;
use Getopt::Long;
use Cwd 'abs_path';
my $usage=<<"USAGE";
  
 name:    plot_element_methy
            
            It is designed for plot gene element methylation level vioplot of BS-seq.
 version:1.0
 usage:   perl $0
            -i <str>  map file;
			-p <str>  element methy file path;
			-e <str>  element name list, split with "," like: cgi,cgi_shore,promoter;
            -o <str>  results file path;
            -Rscript <str>  Rscript program;
            -h <str>  help;
 author:  zhangdu
 date:    2018-05-29
USAGE

my ($ref,$file,$outpath,$ele,$elepath,$Rscript);
my $help;
GetOptions("i=s" =>  \$file,
           "p=s" =>  \$elepath,
           "e=s" =>  \$ele,
           "o=s" => \$outpath,
		   "Rscript=s" =>  \$Rscript,
           "h=s" => \$help
);

die $usage if $help;
die $usage unless $file;
die $usage unless $outpath;
die $usage unless $ele;
die $usage unless $elepath;
die $usage unless $Rscript;

my @elelist=split(/,/,$ele);
foreach my $element(@elelist){
	print "#################################\n|-----Analysising $element methylation distribution for all samples...\n";
	system ("date");
	my $out=$elepath."/all.sample.genome.".$element.".methy.txt";
	open FILE, $file or die "can not open $file:$!";
	open OUT, ">$out" or die "can not open $out:$!";
	while(<FILE>){   
       chomp $_;
       next if(/^#Group/);
       my @sampleinfo=split(/\t/,$_);
	   #my $in=$elepath."/".$sampleinfo[1]."/genome.".$element.".methy.txt";
	   my $in=$elepath."/".$sampleinfo[1]."/$sampleinfo[1].genome.".$element.".methy.txt";
           if(-e $in){
               $in=$elepath."/".$sampleinfo[1]."/$sampleinfo[1].genome.".$element.".methy.txt";
           }else{
               $in=$elepath."/".$sampleinfo[1]."/$sampleinfo[1].Repeats.".$element.".methy.txt";
           }
	   open IN, $in or die "can not open $in:$!";
	   my $n=0;
	   while(<IN>){
		   chomp $_;
		   my @info=split(/\t/,$_);
		   next if($info[-1] eq "NA");
		   print OUT "$sampleinfo[0]\t$sampleinfo[1]\t$info[-1]\n";
		   $n++;
	   }
	   print "|-----Total read $n $element from sample: $sampleinfo[1]...\n";
       close IN;
	}
	close OUT;
	close FILE;
#plot
print "|-----violin ploting...\n";
my $pdf1=$outpath."/all.sample.genome.".$element.".methy_vioplot.pdf";
my $pdf2=$outpath."/all.group.genome.".$element.".methy_vioplot.pdf";
system ("$Rscript $Bin/plot_sample_element_methy.v1.0.R $out $pdf1 $element");
system ("$Rscript $Bin/plot_group_element_methy.v1.0.R $out $pdf2 $element");
print "-----|$element analysis finished...\n";
system ("date");
print "#################################\n\n";
}
###########################################################################################################################
