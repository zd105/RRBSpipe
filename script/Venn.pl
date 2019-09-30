#!/usr/bin/perl
use strict;
use warnings;
use File::Basename qw(basename dirname);
use Getopt::Long;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Usage

my $usage=<<"USAGE";

name:  $0
       A Venn diagram or set diagram is a diagram that shows all
       possible logical relations between a finite collection of 
       different sets. Venn diagrams were conceived around 1880 
       by John Venn.
       Here, this perl script can show all possible logical 
       relations of given different sets like Venn diagram.
       

usage:
              -I  <file_a,file_b,file_c,...,file_n >, join file names with ',';
                  要比较的id所在的各个文件；
             
              -C  [file_a_col_No,file_b_col_No,file_c_col_No,...,file_n_col_NO], join colNO. with ',';
                  the default is each whole row;
                  要比较的id在各个文件中所在的列的编号；
                  (文件列数编号从0开始)
              
              -L  Show the classify results only;
                  仅展示分类，不输出具体结果；
example:
         perl $0   -I a,b
         perl $0   -I a,b    -C 1,1
         perl $0   -I a,b,c  -C 1,1,4 -L
         perl $0   -I a,b,c,d,e,f -C 1,2,3,4,5,6 -L
author:
         luhanlin\@genomics.org.cn
         2012.01.01
P.S.
  比较多个文件中各指定列是否有包含关系；
  用来比较两个文件，之后输出a文件特有的，b文件特有的和ab两个文件共有的行；
  或者输入三个文件，输出a,b,c特有的，a,b,c共有的，以及ab特有，bc特有和ca特有的行；
  或者输入 n 个文件，2^n-1 种关系......
  [控制文件，不宜过多]



USAGE

my ($file_in, $cols_in, $list_only, $help);
GetOptions(
    "I=s" => \$file_in,
    "C=s" => \$cols_in,
    "L"   => \$list_only,
    "h|?|help" => \$help,
);
die $usage if $help;
unless($file_in){
    print "$usage";
    exit 0;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ globle parameters

my (@files, @f_cols, %ha, %uniq, %typ, @com, %name, %class_2_file);

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ define the relations

@files = split(',', $file_in);
for (my $i=0; $i<@files; $i++){   # 1 2 4 8 16 32 64 ...
    my $num = 2**$i;
    push @com, $num;
    my $name = basename( $files[$i] );
    $class_2_file{$num} = $name;
}
for (my $i=1; $i< 2**($#files+1); $i++){  # 有n个文件就有 2**n-1 种关系类型
    my $binary = sprintf( "%b", $i );
    my @dit = reverse split(//, $binary);
    my @name_tmp;
    for (my $j=0; $j<=$#dit; $j++){
        my $s_bin = $dit[$j] * ( 2 ** $j );
        unless($s_bin == 0){
            push @name_tmp, "$class_2_file{$s_bin}";
        }
    }
    $name{$i} = join ' ~ ', @name_tmp;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ reading files

if (defined $cols_in){  #reading files
    @f_cols = split(',', $cols_in);
    foreach my $col (@f_cols){
        unless ($col=~/^\d+$/){
            die "$cols_in\nBe Sure your colNO. are all number!\n";
        }
    }
    unless ($#files == $#f_cols){
        die "files counts != column counts\nBe Sure your files and your designated colNO. are one-to-one!\n" ;
    }
    for (my $i=0; $i<@files; $i++){
        open IN,"< $files[$i]" or die "can not open file:\t$files[$i]\n";
        %uniq = ();
        while (my $row = <IN>){
            chomp $row;
            next if ($row=~/^\s*$/);
            my $id = (split(/\s+/,$row))[ $f_cols[$i] ];
            next if ($id=~/^\s*$/);
            $uniq{$id}++;
        }
        close IN;
        $ha{$_} += $com[$i] foreach (keys %uniq);    #对每个元素做关系类型的归属处理
    }
}
else{
    for (my $i=0;$i<@files;$i++){
        open IN,"< $files[$i]" or die "can not open file:\t$files[$i]\n";
        %uniq = ();
        while (my $row = <IN>){
            chomp $row;
            next if($row=~/^\s*$/);
            $uniq{$row}++;
        }
        close IN;
        $ha{$_} += $com[$i] foreach (keys %uniq);
    }
}
%uniq = ();

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ clustering

foreach my $uniq_id (keys %ha){
    my $class = $ha{$uniq_id};
    push @{$typ{$class}},$uniq_id;
}
%ha = ();

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ print the results

if (defined $list_only){
    foreach my $class_b (sort {$a<=>$b} keys %name){
        if(exists $typ{$class_b}){
           print "$class_b\t$name{$class_b}\t", $#{$typ{$class_b}}+1, "\n";
        }
        else{
           print "$class_b\t$name{$class_b}\t0\n";
        }
    }
}
else{
    print ">~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#\n";
    foreach my $class_b (sort {$a<=>$b} keys %name){
        if(exists $typ{$class_b}){
            print ">>> $class_b\t$name{$class_b}\t", $#{$typ{$class_b}}+1, "\n";
        }
        else{
            print ">>> $class_b\t$name{$class_b}\t0\n";
        }
    }
    print ">~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#\n";
    foreach my $class_b (sort {$a<=>$b} keys %name){
        if(exists $typ{$class_b}){
            print "### $class_b\t$name{$class_b}\t", $#{$typ{$class_b}}+1, "\n";
            foreach (@{$typ{$class_b}}){
                print "$class_b\t$_\n";
            }
            #print "\n";
        }
    }
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  END
