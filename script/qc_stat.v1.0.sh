# name:    qc_stat
# usage:   sh qc_stat.v1.0.sh <dir> <prefix>
#             dir <str> 04_qc_stat abs dir;
#             prefix <str> common prefix of sample id.
# author:  zhangdu
# e-mail:  zhangducsu\@163.com
# date:
# version:v1.0

statdir=$1  # 04_qc_stat abs dir
prefix=$2    # common prefix of sample id

cd $statdir
echo -e "Sample_ID\tRawReadsNum\tRawBaseNum\tRawQ20Rate\tRawQ30Rate\tAdapterCleanBaseRate\tCleanReadsNum\tCleanBaseNum\tCleanQ20Rate\tCleanQ30Rate\tCleanReadsRate\tCleanBaseRate\tCleanData(Gb)" >> QC_result.xls
for sam in `ls -d $prefix*`
do
Sample_ID=$sam
RawReadsNum=$(less -S $sam/$sam.raw.xls | awk '$0!~/^R/{print $1}')
RawBaseNum=$(less -S $sam/$sam.raw.xls | awk '$0!~/^R/{print $2}')
RawQ20Rate=$(less -S $sam/$sam.raw.xls | awk '$0!~/^R/{printf "%.2f%\n",$4*100}')
RawQ30Rate=$(less -S $sam/$sam.raw.xls | awk '$0!~/^R/{printf "%.2f%\n",$6*100}')
AdapterCleanBaseRate=$(less -S $sam/$sam.noAdapter.xls | awk '$0!~/^R/{printf "%.2f%\n",($2/'$RawBaseNum')*100}')
CleanReadsNum=$(less -S $sam/$sam.clean.xls | awk '$0!~/^R/{print $1}')
CleanBaseNum=$(less -S $sam/$sam.clean.xls | awk '$0!~/^R/{print $2}')
CleanQ20Rate=$(less -S $sam/$sam.clean.xls | awk '$0!~/^R/{printf "%.2f%\n",$4*100}')
CleanQ30Rate=$(less -S $sam/$sam.clean.xls | awk '$0!~/^R/{printf "%.2f%\n",$6*100}')
CleanReadsRate=$(less -S $sam/$sam.clean.xls | awk '$0!~/^R/{printf "%.2f%\n",($1/'$RawReadsNum')*100}')
CleanBaseRate=$(less -S $sam/$sam.clean.xls | awk '$0!~/^R/{printf "%.2f%\n",($2/'$RawBaseNum')*100}')
CleanData=$(less -S $sam/$sam.clean.xls | awk '$0!~/^R/{printf "%.3f\n",$2/10^9}')
echo -e "$Sample_ID\t$RawReadsNum\t$RawBaseNum\t$RawQ20Rate\t$RawQ30Rate\t$AdapterCleanBaseRate\t$CleanReadsNum\t$CleanBaseNum\t$CleanQ20Rate\t$CleanQ30Rate\t$CleanReadsRate\t$CleanBaseRate\t$CleanData" >> QC_result.xls
done
