sample=$1
cout=$2
outdir=$3
ref=$4
Rscript=$5

shell=$0
Bin=${shell%/*}


for t in CG CHH CHG 
do
	### get mc bedformat : 筛选 >=10x && methy >0.75 的位点
	zcat $cout | awk -v c=$t 'BEGIN{OFS="\t"}{ if($4==c && $7+$8 > 9 && $6>0.75){n+=1; if($3=="+"){ print $1, $2-4, $2+4, $3, n; } } } ' > $outdir/$sample.seqlogo.m$t.bed 
	### get sequences pwm
        perl $Bin/z02.get_seq.pl -D $ref -R $outdir/$sample.seqlogo.m$t.bed -f 3-0-1-2-4 -O $outdir/$sample.seqlogo.m$t.fa 
	perl -lne 'next if /^>/; next if length($_)<9; @a=split(//, $_); foreach $i (0..8){ $h{$i}{$a[$i]}+=1;} END{ foreach $i (0..8){  $a = $h{$i}{"A"} ? $h{$i}{"A"} : 0; $c = $h{$i}{"C"} ? $h{$i}{"C"} : 0; $g = $h{$i}{"G"} ? $h{$i}{"G"} : 0; $t = $h{$i}{"T"} ? $h{$i}{"T"} : 0; print join "\t", $a, $c, $g, $t; } } ' $outdir/$sample.seqlogo.m$t.fa > $outdir/$sample.seqlogo.m$t.pwm
    ### plot  
	$Rscript $Bin/z02.seqlogo.R $outdir/$sample.seqlogo.m$t.pwm T $outdir/$sample.m$t.seqlogo.pdf
	rm -vf $outdir/$sample.seqlogo.m$t.bed $outdir/$sample.seqlogo.m$t.fa
done

