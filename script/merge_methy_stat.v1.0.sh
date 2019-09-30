pjdir=$1
prefix=$2
Rscript=$3

echo -e "Table 5.CG,CHG,CHH sequencing depth and coverrage\nSampleID\ttotal_CG\tmean_depthCG\teffect_depthCG(>=1X)\tcovrageCG\tcoverageCG(d>=5X)\tcoverageCG(d>=10X)\ttotal_CHG\tmean_depthCHG\teffect_depthCHG(>=1X)\tcovrageCHG\tcoverageCHG(d>=5X)\tcoverageCHG(d>=10X)\ttotal_CHH\tmean_depthCHH\teffect_depthCHH(>=1X)\tcovrageCHH\tcoverageCHH(d>=5X)\tcoverageCHH(d>=10X)" > $pjdir/03_global_methy/01_coverage_depth/05.all.coverage_depth.xls
echo -e "Table 4.CG,CHG,CHH average methylation level(>1Xdepth)\nSampleID\tC\tCG\tCHG\tCHH" >$pjdir/03_global_methy/01_coverage_depth/04.all.averge_methyl.xls

cd $pjdir/03_global_methy/01_coverage_depth
#for sam in `ls -d $prefix*`
for sam in `ls -d *`
	do
		awk 'NR==2' $sam/$sam.averge_methyl.xls >> $pjdir/03_global_methy/01_coverage_depth/04.all.averge_methyl.xls
		awk 'NR==2' $sam/$sam.coverage_depth.xls >> $pjdir/03_global_methy/01_coverage_depth/05.all.coverage_depth.xls
	done

#plot
#get script file dir 
getsd() { 
	oldwd=`pwd` 
	rw=`dirname $0` 
	cd $rw 
	sw=`pwd` 
	cd $oldwd 
	echo $sw 
} 
scriptdir=`getsd`

$Rscript $scriptdir/averge_methyl.barplot.R $pjdir/03_global_methy/01_coverage_depth/04.all.averge_methyl.xls all.averge_methyl.pdf
$Rscript $scriptdir/methy_type.pieplot.R $pjdir/03_global_methy/01_coverage_depth/05.all.coverage_depth.xls global_methy_type.pieplot.pdf


