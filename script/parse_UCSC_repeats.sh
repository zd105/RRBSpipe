file=$1  #RepeatMaser.txt.gz
outdir=$2 

for type in DNA LINE LTR Retroposon RNA Satellite SINE Low_complexity Simple_repeat
	do
	echo -e "Extracting repeat elements from genome: $type ..."
	if [ $type == "RNA" ];then
		zcat $file |perl -alne 'if($F[11]=~/RNA$/){print join "\t",@F[5..7],@F[10..12],$F[9]}' > $outdir/Repeats.$type.bed
	else
		zcat $file |perl -alne 'if($F[11] eq '$type'){print join "\t",@F[5..7],@F[10..12],$F[9]}' > $outdir/Repeats.$type.bed
	fi
	done
