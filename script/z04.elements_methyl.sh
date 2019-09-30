#### average methlation level for gene elements of samples

# Usage:
#      z04.elements_methyl.sh <element dir> <cout file> <out dir> <C type> <sample name> <Rscript program> <"cgi" or "">
#
#      details:
#      generally analysis "promoter down1k down2k exon genebody intergenic intron up2k up1k";
#      add "cgi" in args 6 if you want to analysis "cgi cgi_shelf cgi_shore".

shell=$0
Bin=${shell%/*}

			  ele_dir=$1
			  cout=$2
			  outdir=$3
			  type=$4
			  sample=$5
			  Rscript=$6
			  CGI=$7


			  mkdir -p  $outdir

### global
#echo -e "|-----Start analysis $sample of global $type methylation level..."
#echo `date`
#perl $Bin/z04.elements_methyl.pl -c $cout -b global -t $type -o $outdir/$sample.$type.global_methy.txt
#echo "-----|done..."

### cgi
if [ $CGI ];then
	for i in cgi cgi_shelf cgi_shore
	#for i in cgi cgi_shore
	do
		echo -e "##################################################\n|-----Start analysis $sample $i methylation level..."
		echo `date`
		echo -e "[COMAND]: perl $Bin/z04.elements_methyl.pl -c $cout -b $ele_dir/genome.$i.bed -t CG -o $outdir/$sample.genome.$i.methy.txt"
		perl $Bin/z04.elements_methyl.pl -c $cout -b $ele_dir/genome.$i.bed -t CG -o $outdir/$sample.genome.$i.methy.txt
		echo "-----|done..."
	done
		#plot
		echo -e "|-----Violin plotting...\n"
		echo -e "[COMAND]: $Rscript $Bin/z04.elements_methyl.R $outdir cgi-cgi_shelf-cgi_shore $sample.genome.CGI $sample"
		$Rscript $Bin/z04.elements_methyl.R $outdir cgi-cgi_shelf-cgi_shore $outdir/$sample.genome.CG $sample
fi


##### genic
#for i in downstream2k downstream5k exon genebody intergenic intron upstream2k upstream5k
for i in promoter down1k down2k exon genebody intergenic intron up2k up1k 5utr 3utr cds exon1 intron1
do
	echo -e "##################################################\n|-----Start analysis $sample $i methylation level..."
	echo `date`
	perl $Bin/z04.elements_methyl.pl -c $cout -b $ele_dir/genome.$i.bed -t $type -o $outdir/$sample.genome.$i.methy.txt
	echo -e "[COMAND]: perl $Bin/z04.elements_methyl.pl -c $cout -b $ele_dir/genome.$i.bed -t $type -o $outdir/$sample.genome.$i.methy.txt"
	echo "-----|done..."
done
echo -e "|-----Violin plotting...\n"
echo -e "[COMAND]: $Rscript $Bin/z04.elements_methyl.R $outdir promoter-down1k-down2k-exon-genebody-intergenic-intron-up2k-up1k-intron1-exon1 $sample.genome.genetic $sample"
$Rscript $Bin/z04.elements_methyl.R $outdir promoter-down1k-down2k-exon-genebody-intergenic-intron-up2k-up1k-5utr-3utr-cds-intron1-exon1 $outdir/$sample.genome.genetic $sample


## repeat
for j in DNA LINE Low_complexity LTR RNA Satellite Simple_repeat SINE
#do
#     perl $p1 chr$i.combinedCpG.filter.txt $d/repeat/$j.mbed chr$i > z02_stat/chr$i.repeat.$j.txt
#done
