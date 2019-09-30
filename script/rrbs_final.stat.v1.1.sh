#!/bin/sh
if [ $# -lt 3 ]
then
	echo "Name: rrbs_final.stat.v1.3.sh"
	echo "Usage: $0 <project dir> <sample name prefix> <YES or NO for CT coversion rate assess>"
	echo "This script is for RRBS stat on login2"
	echo "Author: zhangdu"
	exit
fi

pjdir=$1
prefix=$2
control=$3
outdir=$pjdir/02_methycalling/04_stat
mkdir -p $pjdir/02_methycalling/04_stat/jobs
result1=$outdir/01.QC-mapping_stat.xls
result2=$outdir/02.Global_methy.stat.xls
result3=$outdir/03.CG_global_methy.stat.xls

if [ "$control" =  "YES" ]
then

	echo "NOTE: CT covertion rate will be stat..."
	echo -e "Table 1. QC and mapping summery" > $result1
	echo -e "Sample_ID\tRawReadsNum\tRawBaseNum\tRawQ20Rate\tRawQ30Rate\tAdapterCleanBaseRate\tCleanReadsNum\tCleanBaseNum\tCleanQ20Rate\tCleanQ30Rate\tCleanReadsRate\tCleanBaseRate\tCleanData(Gb)\tMappedReads\tMappedRate\tCT ConvertRatio" >> $result1
	echo -e "Table 2. Global average depth and methylation level in C site " > $result2
	echo -e "Sample_ID\tAverageDepC\tAverageDepCG\tAverageDepCHG\tAverageDepCHH\tMethyLevelC\tMethyLevelCG\tMethyLevelCHG\tMethyLevelCHH" >> $result2
	echo -e "Table 3. Methylation summery on C and CpG sites " > $result3
	echo -e "Sample_ID\tC>1x\tC>1xdep\tC>1xcoverage%\tC>1xmethy\tCG>1x\tCG>1xdep\tCG>1xcoverage%\tCG>1xmethy\tC>=5x\tC>=5xdep\tC>=5xcoverage%\tC>=5xmethy\tCG>=5x\tCG>=5xdep\tCG>=5xcoverage%\tCG>=5xmethy" >> $result3
	cd $pjdir/01_cleandata/02_clean
	for sam in `ls -d $prefix*`
	do  
		echo -n "
		echo -e \"||-------$sam stastics started\\n\"

########################################################################################################################################
		#QC stat
		cd $pjdir/01_cleandata/04_qc_stat
		Sample_ID=$sam
		RawReadsNum=\$(less -S $sam/$sam.raw.xls | awk '\$0!~/^R/{print \$1}')
		RawBaseNum=\$(less -S $sam/$sam.raw.xls | awk '\$0!~/^R/{print \$2}')
		RawQ20Rate=\$(less -S $sam/$sam.raw.xls | awk '\$0!~/^R/{printf \"%.2f%\\n\",\$4*100}')
		RawQ30Rate=\$(less -S $sam/$sam.raw.xls | awk '\$0!~/^R/{printf \"%.2f%\\n\",\$6*100}')
		AdapterCleanBaseRate=\$(less -S $sam/$sam.noAdapter.xls | awk '\$0!~/^R/{printf \"%.2f%\\n\",(\$2/'\$RawBaseNum')*100}')
		CleanReadsNum=\$(less -S $sam/$sam.clean.xls | awk '\$0!~/^R/{print \$1}')
		CleanBaseNum=\$(less -S $sam/$sam.clean.xls | awk '\$0!~/^R/{print \$2}')
		CleanQ20Rate=\$(less -S $sam/$sam.clean.xls | awk '\$0!~/^R/{printf \"%.2f%\\n\",\$4*100}')
		CleanQ30Rate=\$(less -S $sam/$sam.clean.xls | awk '\$0!~/^R/{printf \"%.2f%\\n\",\$6*100}')
		CleanReadsRate=\$(less -S $sam/$sam.clean.xls | awk '\$0!~/^R/{printf \"%.2f%\\n\",(\$1/'\$RawReadsNum')*100}')
		CleanBaseRate=\$(less -S $sam/$sam.clean.xls | awk '\$0!~/^R/{printf \"%.2f%\\n\",(\$2/'\$RawBaseNum')*100}')
		CleanData=\$(less -S $sam/$sam.clean.xls | awk '\$0!~/^R/{printf \"%.3f\\n\",\$2/10^9}')

########################################################################################################################################
		#bsmap stat
		cd $pjdir/02_methycalling/01_bsmap/$sam
		file1=$sam.mapping.stat
		info1=\$(less -S \$file1 | awk 'BEGIN{FS=\"[ \\t(:]\";OFS=\"\\t\"}NR==3{print \$1,\$6}')

		cd $pjdir/02_methycalling/03_control/$sam
		file2=$sam.control.cout.gz
		info2=\$(zcat \$file2 | awk '\$6~/[.]/{ratio+=1-\$6;count++}END{printf \"%.2f%\\n\",(ratio/count)*100}')

		echo -e \"\$Sample_ID\\t\$RawReadsNum\\t\$RawBaseNum\\t\$RawQ20Rate\\t\$RawQ30Rate\\t\$AdapterCleanBaseRate\\t\$CleanReadsNum\\t\$CleanBaseNum\\t\$CleanQ20Rate\\t\$CleanQ30Rate\\t\$CleanReadsRate\\t\$CleanBaseRate\\t\$CleanData\\t\$info1\\t\$info2\" >> $result1

#########################################################################################################################################
		#average methy stat
		cd $pjdir/02_methycalling/02_cout/$sam
		file3=$sam.cout.gz
		info3=\$(zcat \$file3 | awk 'BEGIN{OFS=\"\\t\"}\$4~/^C/{depthC+=(\$7+\$8);ratioC+=\$6;countC++;}\$4~/^CG$/{depthCG+=(\$7+\$8);ratioCG+=\$6;countCG++;}\$4~/^CHG$/{depthCHG+=(\$7+\$8);ratioCHG+=\$6;countCHG++;}\$4~/^CHH$/{depthCHH+=(\$7+\$8);ratioCHH+=\$6;countCHH++;}END{print depthC/countC,depthCG/countCG,depthCHG/countCHG,depthCHH/countCHH,ratioC/countC,ratioCG/countCG,ratioCHG/countCHG,ratioCHH/countCHH}')

		echo -e \"\$Sample_ID\\t\$info3\" >> $result2

###########################################################################################################################################
#coverage and depth stat
		info4=\$(zcat \$file3 | awk 'BEGIN{OFS=\"\\t\"}\$4~/^C/{totalC++;if(\$7+\$8>1){depthC+=\$7+\$8;ratioC+=\$6;countC++;}}\$4~/^CG$/{totalCG++;if(\$7+\$8>1){depthCG+=\$7+\$8;ratioCG+=\$6;countCG++;}}\$4~/^C/{totalCF++;if(\$7+\$8>4){depthCF+=\$7+\$8;ratioCF+=\$6;countCF++;}}\$4~/^CG$/{totalCGF++;if(\$7+\$8>4){depthCGF+=\$7+\$8;ratioCGF+=\$6;countCGF++;}}END{print countC,depthC/countC,(countC/totalC)*100,ratioC/countC,countCG,depthCG/countCG,(countCG/totalCG)*100,ratioCG/countCG,countCF,depthCF/countCF,(countCF/totalCF)*100,ratioCF/countCF,countCGF,depthCGF/countCGF,(countCGF/totalCGF)*100,ratioCGF/countCGF}')
		echo -e \"\$Sample_ID\\t\$info4\" >> $result3

###########################################################################################################################################

		echo -e \"||-------$sam stastics finished\\n\"
		" > $outdir/jobs/$sam.pbs
		echo -e "qsub -cwd -l vf=10G -q all.q -pe smp 1 $outdir/jobs/$sam.pbs" >> $outdir/jobs/all.sge
		echo -e "qsub -N $sam -l nodes=1:ppn=1 $outdir/jobs/$sam.pbs" >> $outdir/jobs/all.pbs

	done

elif [ "$control" =  "NO" ]
then
	echo "NOTE: CT covertion rate was set to not stat!!!!!"
	echo -e "Table 1. QC and mapping summery" > $result1
	echo -e "Sample_ID\tRawReadsNum\tRawBaseNum\tRawQ20Rate\tRawQ30Rate\tAdapterCleanBaseRate\tCleanReadsNum\tCleanBaseNum\tCleanQ20Rate\tCleanQ30Rate\tCleanReadsRate\tCleanBaseRate\tCleanData(Gb)\tMappedReads\tMappedRate" >> $result1
	echo -e "Table 2. Global average depth and methylation level in C site " > $result2
	echo -e "Sample_ID\tAverageDepC\tAverageDepCG\tAverageDepCHG\tAverageDepCHH\tMethyLevelC\tMethyLevelCG\tMethyLevelCHG\tMethyLevelCHH" >> $result2
	echo -e "Table 3. Methylation summery on C and CpG sites " > $result3
	echo -e "Sample_ID\tC>1x\tC>1xdep\tC>1xcoverage%\tC>1xmethy\tCG>1x\tCG>1xdep\tCG>1xcoverage%\tCG>1xmethy\tC>=5x\tC>=5xdep\tC>=5xcoverage%\tC>=5xmethy\tCG>=5x\tCG>=5xdep\tCG>=5xcoverage%\tCG>=5xmethy" >> $result3
	cd $pjdir/01_cleandata/02_clean
	for sam in `ls -d $prefix*`
	do  
		echo -n "
		echo -e \"||-------$sam stastics started\\n\"

########################################################################################################################################
		#QC stat
		cd $pjdir/01_cleandata/04_qc_stat
		Sample_ID=$sam
		RawReadsNum=\$(less -S $sam/$sam.raw.xls | awk '\$0!~/^R/{print \$1}')
		RawBaseNum=\$(less -S $sam/$sam.raw.xls | awk '\$0!~/^R/{print \$2}')
		RawQ20Rate=\$(less -S $sam/$sam.raw.xls | awk '\$0!~/^R/{printf \"%.2f%\\n\",\$4*100}')
		RawQ30Rate=\$(less -S $sam/$sam.raw.xls | awk '\$0!~/^R/{printf \"%.2f%\\n\",\$6*100}')
		AdapterCleanBaseRate=\$(less -S $sam/$sam.noAdapter.xls | awk '\$0!~/^R/{printf \"%.2f%\\n\",(\$2/'\$RawBaseNum')*100}')
		CleanReadsNum=\$(less -S $sam/$sam.clean.xls | awk '\$0!~/^R/{print \$1}')
		CleanBaseNum=\$(less -S $sam/$sam.clean.xls | awk '\$0!~/^R/{print \$2}')
		CleanQ20Rate=\$(less -S $sam/$sam.clean.xls | awk '\$0!~/^R/{printf \"%.2f%\\n\",\$4*100}')
		CleanQ30Rate=\$(less -S $sam/$sam.clean.xls | awk '\$0!~/^R/{printf \"%.2f%\\n\",\$6*100}')
		CleanReadsRate=\$(less -S $sam/$sam.clean.xls | awk '\$0!~/^R/{printf \"%.2f%\\n\",(\$1/'\$RawReadsNum')*100}')
		CleanBaseRate=\$(less -S $sam/$sam.clean.xls | awk '\$0!~/^R/{printf \"%.2f%\\n\",(\$2/'\$RawBaseNum')*100}')
		CleanData=\$(less -S $sam/$sam.clean.xls | awk '\$0!~/^R/{printf \"%.3f\\n\",\$2/10^9}')

########################################################################################################################################
		#bsmap stat
		cd $pjdir/02_methycalling/01_bsmap/$sam
		file1=$sam.mapping.stat
		info1=\$(less -S \$file1 | awk 'BEGIN{FS=\"[ \\t(:]\";OFS=\"\\t\"}NR==3{print \$1,\$6}')

		echo -e \"\$Sample_ID\\t\$RawReadsNum\\t\$RawBaseNum\\t\$RawQ20Rate\\t\$RawQ30Rate\\t\$AdapterCleanBaseRate\\t\$CleanReadsNum\\t\$CleanBaseNum\\t\$CleanQ20Rate\\t\$CleanQ30Rate\\t\$CleanReadsRate\\t\$CleanBaseRate\\t\$CleanData\\t\$info1\" >> $result1
#########################################################################################################################################
		#average methy stat
		cd $pjdir/02_methycalling/02_cout/$sam
		file3=$sam.cout.gz
		info3=\$(zcat \$file3 | awk 'BEGIN{OFS=\"\\t\"}\$4~/^C/{depthC+=(\$7+\$8);ratioC+=\$6;countC++;}\$4~/^CG$/{depthCG+=(\$7+\$8);ratioCG+=\$6;countCG++;}\$4~/^CHG$/{depthCHG+=(\$7+\$8);ratioCHG+=\$6;countCHG++;}\$4~/^CHH$/{depthCHH+=(\$7+\$8);ratioCHH+=\$6;countCHH++;}END{print depthC/countC,depthCG/countCG,depthCHG/countCHG,depthCHH/countCHH,ratioC/countC,ratioCG/countCG,ratioCHG/countCHG,ratioCHH/countCHH}')
		echo -e \"\$Sample_ID\\t\$info3\" >> $result2

###########################################################################################################################################
		#coverage and depth stat
		info4=\$(zcat \$file3 | awk 'BEGIN{OFS=\"\\t\"}\$4~/^C/{totalC++;if(\$7+\$8>1){depthC+=\$7+\$8;ratioC+=\$6;countC++;}}\$4~/^CG$/{totalCG++;if(\$7+\$8>1){depthCG+=\$7+\$8;ratioCG+=\$6;countCG++;}}\$4~/^C/{totalCF++;if(\$7+\$8>4){depthCF+=\$7+\$8;ratioCF+=\$6;countCF++;}}\$4~/^CG$/{totalCGF++;if(\$7+\$8>4){depthCGF+=\$7+\$8;ratioCGF+=\$6;countCGF++;}}END{print countC,depthC/countC,(countC/totalC)*100,ratioC/countC,countCG,depthCG/countCG,(countCG/totalCG)*100,ratioCG/countCG,countCF,depthCF/countCF,(countCF/totalCF)*100,ratioCF/countCF,countCGF,depthCGF/countCGF,(countCGF/totalCGF)*100,ratioCGF/countCGF}')
		echo -e \"\$Sample_ID\\t\$info4\" >> $result3

###########################################################################################################################################

		echo -e \"||-------$sam stastics finished\\n\"
		" > $outdir/jobs/$sam.pbs
		
		echo -e "qsub -cwd -l vf=2G -pe smp 1 $outdir/jobs/$sam.pbs" >> $outdir/jobs/all.sge
		echo -e "qsub -N $sam -l nodes=1:ppn=1 $outdir/jobs/$sam.pbs" >> $outdir/jobs/all.pbs

	done

else
	echo "Unkown argument..."
	exit
fi

echo -e "||-------All stastics task qsub build done..\n"
