#!/bin/bash

#Run AscatNGS with default parameters. Needs as input: tumor bam as parameter 1, normal bam as parameter 2, output directory as parameter 3, sample gender as parameter 4
reference=~/genome_references/customRef38.fa
snpGC=~/genome_references/snpGcCorrections_hg38wChr.tsv
ascat=./ascat.pl
normal=$1
tumor=$2
outDir=$3
sex=$4

#Color constants to print in different colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

#Get assembly, specie and platform
#Assembly
sp=`samtools view -H $normal | grep @SQ | grep -c AS`
sp2=`samtools view -H $tumor | grep @SQ | grep -c AS`

if (( $sp == 0 && $sp2 == 0))
then
	assembly=GRCh38.d1.vd1
else
	if (( $sp != 0 ))
	then
		assembly=`samtools view -H $normal | grep @SQ | grep -m 1 AS | awk '{for(i=1;i<=NF;++i){j=index($i,"AS:"); if(j!=0){print substr($i,j+3)}}}'`
	else
		assembly=`samtools view -H $tumor | grep @SQ | grep -m 1 AS | awk '{for(i=1;i<=NF;++i){j=index($i,"AS:"); if(j!=0){print substr($i,j+3)}}}'`
	fi
fi

#Specie
sp=`samtools view -H $normal | grep @SQ | grep -c SP`
sp2=`samtools view -H $tumor | grep @SQ | grep -c SP`


if (( $sp == 0 && $sp2 == 0))
then
	specie="Homo sapiens"
else
	if (( $sp != 0 ))
	then
		specie=`samtools view -H $normal | grep @SQ | grep -m 1 SP | awk '{for(i=1;i<=NF;++i){j=index($i,"SP:"); if(j!=0){print substr($i,j+3)}}}'`
		if (( $specie == "Homo" ))
		then
			specie="Homo sapiens"
		fi
	else
		specie=`samtools view -H $tumor | grep @SQ | grep -m 1 SP | awk '{for(i=1;i<=NF;++i){j=index($i,"SP:"); if(j!=0){print substr($i,j+3)}}}'`
		if (( $specie == "Homo" ))
		then
			specie="Homo sapiens"
		fi
	fi
fi

#Platform assumes always Illumina
platform="ILLUMINA"

#Check if the number of parameters is the expected and run AscatNGS if that is the case
if (( $# == 4 )); then
	cd ~/soft/AscatNGS/bin
	sta=`date`
	SECONDS=0
	$ascat -outdir $outDir -tumour $tumor -normal $normal -reference $reference -snp_gc $snpGC -protocol WXS -gender $sex -genderChr chrY -platform $platform -species $specie -assembly $assembly -cpus 8 -nobigwig -noclean

	if (( $? == 0 )); then
		echo -e "\n\n${GREEN}AscatNGS ran successfully.${NC} Running the analysis\n\n"
		echo -e "Output written in $outDir\n"
		end=`date`
		echo -e "AscatNGS started at $sta\nEnded at $end"
		printf 'Elapsed time -> %dh:%dm:%ds\n' $(($SECONDS/3600)) $(($SECONDS%3600/60)) $(($SECONDS%60))
	else
		echo -e >&2 "\n${RED}Execution aborted. Check below possible errors${NC}\n"
		exit 1
	fi
else 
	echo -e >&2 "\nUSAGE: runAscat.sh normal.bam tumor.bam output_directory sample_gender [XX, XY]\n" #Print the output using stderr
	exit 1
fi


