#Usage:
#      CGI.element_finder_forUCSC.v1.0.sh <genome.fa> <cpgIslandExt.txt.gz from UCSC> <out dir> <outprefix>
#
# Note: you have to have samtools,bedtools installed in your system.
# output:  1.prefix.cgi.bed
#		  2.prefix.cgi_shore.bed
#		  3.prefix.cgi_shelf.bed

ref=$1
cgi=$2
outdir=$3
name=$4
cd $outdir

# CG island 预测
##################################
echo "|--------cgi and cgi shore extracting from $cgi...";
less -S $cgi | cut -f2,3,4 | perl -alne '$id="cgi".$.; print join "\t",@F,$id,$id'> $name.cgi.bed

# CGI shore 预测
##################################
samtools faidx $ref
# 统计得到基因组序列长度信息
cut -f-2 $ref.fai > $ref.length
echo "|--------Building $name.cgi_shore.bed..."
slopBed -i $name.cgi.bed -g $ref.length -b 2000 | mergeBed | subtractBed -a - -b $name.cgi.bed > $name.cgi_shore.bed
# slop: 双侧扩展2000bp （cgi双侧扩展2k）
# merge: 重叠的序列合并为一条（有重叠的cgi shore合并）
# subtract : a - b 生成新序列（合并之后再减去与cgi重叠的部分）

# CGI shelf 预测
##################################
echo "|--------Building $name.cgi_shelf.bed..."
slopBed -i $name.cgi.bed -g $ref.length -b 4000 | mergeBed | subtractBed -a - -b $name.cgi_shore.bed |subtractBed -a - -b $name.cgi.bed > $name.cgi_shelf.bed






