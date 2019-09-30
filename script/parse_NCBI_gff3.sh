#!/bin/sh
if [ $# != 2 ]
then
    echo "----------------------------------------------------------"
    echo "Usage: $0 <NCBI_.*.gff3[gz]> <prefix_of_output>"
    echo "Use this perl to get following files from NCBI gff3:"
    echo "1. exon.bed"
    echo "2. cds.bed"
    echo "3. intron.bed"
    echo "4. intergenic.bed"
    echo "5. upstream.bed"
    echo "6. downstream.bed"
    echo "7. genebody.bed"
	echo "7. promoter.bed"
    echo "----------------------------------------------------------"
    exit
fi
ref=$1
prefix=$2


#####1 genebody
echo "|-- $prefix.genebody.bed begin...(TSS~TTS)"
less -S $ref | perl -F"\t" -alne 'if($F[2]=~/gene/){ @a=split(/;/,$F[8]); %h=(); foreach(@a){ @b=split(/=/,$_); $h{$b[0]}=$b[1];} print join "\t", @F[0,3,4], $h{ID}, "$h{Name}|$h{gene_biotype}", $F[6]}' > $prefix.genebody.bed
echo "--| $prefix.genebody.bed is done..."

##### promoter: -2000bp ~ +500 bp
echo "|-- $prefix.promoter.bed begin...(-2000bp ~ +500 bp)"
cat $prefix.genebody.bed | perl -alne 'if($F[5] eq "+"){ $start = $F[1]-2000 > 0 ? $F[1]-2000 : 1;$end = $F[1]+500 > $F[2] ? $F[2] : $F[1]+500;print join "\t",$F[0], $start, $end, @F[3,4,5] }else{$end =$F[2]-500 > $F[1] ? $F[2]-500 : $F[1]; print join "\t",$F[0], $end,$F[2]+2000,@F[3,4,5]}' > $prefix.promoter.bed
echo "--| $prefix.promoter.bed is done..."

##### genebody2 :+500bp ~ TTS
echo "|-- $prefix.genebody2.bed begin...(+500bp ~ TTS)"
cat $prefix.genebody.bed | perl -alne 'if($F[5] eq "+"){ if($F[1]+500 >= $f[2]){ next}else{print join "\t",$F[0], $F[1]+500,$F[2], @F[3,4,5]}}else{if($F[2]-500 <= $f[1]){ next}else{print join "\t",$F[0], $F[1],$F[2]-500, @F[3,4,5]}}' > $prefix.genebody2.bed
echo "--| $prefix.genebody2.bed is done..."

####4 up2k
echo "|-- $prefix.up2k.bed begin..."
cat $prefix.genebody.bed | perl -alne 'if($F[5] eq "+"){ $start = $F[1]-2000 > 0 ? $F[1]-2000 : 1; print join "\t",$F[0], $start, $F[1]-1, @F[3,4,5] }else{print join "\t",$F[0], $F[2]+1, $F[2]+2000,@F[3,4,5]}' > $prefix.upstream2k.bed
cat $prefix.genebody.bed | perl -alne 'if($F[5] eq "+"){ $start = $F[1]-5000 > 0 ? $F[1]-5000 : 1; print join "\t",$F[0], $start, $F[1]-1, @F[3,4,5] }else{print join "\t",$F[0], $F[2]+1, $F[2]+5000,@F[3,4,5]}' > $prefix.upstream5k.bed
echo "--| $prefix.up2k.bed is done..."

###5 down2k
echo "|-- $prefix.down2k.bed begin..."
cat $prefix.genebody.bed | perl -alne 'if($F[5] eq "+"){ print join "\t", $F[0], $F[2]+1, $F[2]+2000, @F[3,4,5]}else{ $start = $F[1]-2000 > 0 ? $F[1]-2000 : 1; print join "\t",$F[0], $start, $F[1]-1,@F[3,4,5]}' > $prefix.downstream2k.bed
cat $prefix.genebody.bed | perl -alne 'if($F[5] eq "+"){ print join "\t", $F[0], $F[2]+1, $F[2]+5000, @F[3,4,5]}else{ $start = $F[1]-5000 > 0 ? $F[1]-5000 : 1; print join "\t",$F[0], $start, $F[1]-1,@F[3,4,5]}' > $prefix.downstream5k.bed
echo "--| $prefix.down2k.bed is done..."

####6 exon
echo "|-- $prefix.exon.bed begin..."
less -S $ref | perl -F"\t" -alne 'if($F[2]=~/exon/){ @a=split(/;/,$F[8]); %h=(); foreach(@a){ @b=split(/=/,$_); $h{$b[0]}=$b[1];} print join "\t", @F[0,3,4], $h{ID}, "$h{gene}|$h{transcript_id}|$h{gbkey}", $F[6]}' > $prefix.exon.bed
echo "--| $prefix.exon.bed is done..."

####7 cds
echo "|-- $prefix.cds.bed begin..."
less -S $ref | perl -F"\t" -alne 'if($F[2]=~/CDS/){ @a=split(/;/,$F[8]); %h=(); foreach(@a){ @b=split(/=/,$_); $h{$b[0]}=$b[1];} print join "\t", @F[0,3,4], $h{ID}, "$h{gene}", $F[6]}' > $prefix.cds.bed
echo "--| $prefix.cds.bed is done..."

####8 intron
echo "|-- $prefix.intron.bed begin..."
less -S $prefix.exon.bed | perl -alne ' @a=split(/\|/, $F[4]); if($a[1]){ $g{$a[1]}="$F[4]\t$F[5]"; $c{$a[1]}=$F[0]; push @{$h{$a[1]}}, $F[1]; push @{$h{$a[1]}}, $F[2];} 
END{ 
  foreach $i (keys %c){ 
    $chr = $c{$i};
    $gene = $g{$i};
    if(@{$h{$i}}>2){
      @pos = @{$h{$i}};
      @pos = sort {$a<=>$b} @pos;
      for($i=1; $i<$#pos; $i+=2){
        print join "\t", $chr, $pos[$i] + 1, $pos[$i+1] - 1, 0, $gene;
      }
    }
  } 
}' | sort -k1,1 -k2,2g | perl -alne 'print join "\t",@F[0,1,2], "intron_$.",@F[4,5]' > $prefix.intron.bed
echo "--| $prefix.intron.bed is done..."

####9 intergenic
#没有考虑染色体两端的片段，有待改进
echo "|-- $prefix.intergenic.bed begin..."
sort -k1,1 -k2,2n -u $prefix.genebody.bed | perl -alne ' $g="$F[3]|$F[4]|$F[5]"; $end=$F[2]; if($F[0] eq $tem_chr){ print $F[0],"\t", $tem_end+1, "\t", $F[1]-1, "\t", 0, "\t", "$tem_gene;$g", "\t", "+"; } $tem_gene=$g; $tem_end=$end; $tem_chr=$F[0];' | perl -alne 'print if $F[2]-$F[1] > 200 ' | sort -k1,1 -k2,2g | perl -alne 'print join "\t",@F[0,1,2],"intergenic_$.",@F[4,5]' > $prefix.intergenic.bed
echo "--| $prefix.intergenic.bed is done..."

###### sort -u
echo "|-- sort ..."
sort -k1,1 -k2,2g -k3,3g -u -T . -o $prefix.genebody.bed $prefix.genebody.bed
sort -k1,1 -k2,2g -k3,3g -u -T . -o $prefix.promoter.bed $prefix.promoter.bed
sort -k1,1 -k2,2g -k3,3g -u -T . -o $prefix.genebody2.bed $prefix.genebody2.bed
sort -k1,1 -k2,2g -k3,3g -u -T . -o $prefix.upstream2k.bed $prefix.upstream2k.bed
sort -k1,1 -k2,2g -k3,3g -u -T . -o $prefix.upstream5k.bed $prefix.upstream5k.bed
sort -k1,1 -k2,2g -k3,3g -u -T . -o $prefix.downstream2k.bed $prefix.downstream2k.bed
sort -k1,1 -k2,2g -k3,3g -u -T . -o $prefix.downstream5k.bed $prefix.downstream5k.bed
sort -k1,1 -k2,2g -k3,3g -u -T . -o $prefix.exon.bed $prefix.exon.bed
sort -k1,1 -k2,2g -k3,3g -u -T . -o $prefix.cds.bed $prefix.cds.bed
sort -k1,1 -k2,2g -k3,3g -u -T . -o $prefix.intron.bed $prefix.intron.bed
sort -k1,1 -k2,2g -k3,3g -u -T . -o $prefix.intergenic.bed $prefix.intergenic.bed
echo "--| sort done ..."
###### 
