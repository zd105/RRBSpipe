#Usage:
#      CGI.element_finder.v1.0.sh <genome.fa> <out dir> <outprefix>
#
# Note: you have to have emboss,samtools and bedtools installed in your system.
# output:  1.prefix.cgi.bed
#		  2.prefix.cgi_shore.bed
#		  3.prefix.cgi_shelf.bed

ref=$1
outdir=$2
name=$3
cd $outdir

# CG island 预测
##################################
echo "|--------Building $name.cgi.bed of $ref by Emboss cpgplot tools..."
cpgplot -outfeat emboss.cgIsland.txt -window 100 -minlen 200 -minoe 0.6 -minpc 50 -outfile emboss.cpgplot -graph svg $ref
less -S emboss.cgIsland.txt |grep -v '#' | cut -f1,4,5 | perl -alne '$id="cgi".$.; print join "\t",@F,$id,$id'> $name.cgi.bed

# CGI shore 预测
##################################
samtools faidx $ref
# 统计得到基因组序列长度信息
cut -f-2 $ref.fai > $ref.length
echo "|--------Building $name.cgi_shore.bed.."
slopBed -i $name.cgi.bed -g $ref.length -b 2000 | mergeBed | subtractBed -a - -b $name.cgi.bed > $name.cgi_shore.bed
# slop: 双侧扩展2000bp （cgi双侧扩展2k）
# merge: 重叠的序列合并为一条（有重叠的cgi shore合并）
# subtract : a - b 生成新序列（合并之后再减去与cgi重叠的部分）

# CGI shelf 预测
##################################
echo "|--------Building $name.cgi_shelf.bed.."
slopBed -i $name.cgi.bed -g $ref.length -b 4000 | mergeBed | subtractBed -a - -b $name.cgi_shore.bed |subtractBed -a - -b $name.cgi.bed > $name.cgi_shelf.bed






