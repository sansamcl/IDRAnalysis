#!/bin/bash -l

# Chris Sansam, 2020-07-31

#SBATCH -A sansam-lab
#SBATCH --output slurm-%x.%A.%a.log
#SBATCH --mail-type END,FAIL
#SBATCH --mem 96G
#SBATCH --cpus-per-task 12
#SBATCH -p serial

################################################################################
# MergeAndSplitBams
################################################################################
#  This script will take the BAM files and perform the following steps: 
# 	Merge BAMs for Cut&Run files,
# 	Shuffle reads and split into two new BAM files (pseudo-replicates), 
# 	Merge BAMs
#-------------------------------------------------------------------------------
# positional parameters:
#  ${1} Sample Bam file #1
#  ${2} Sample Bam file #2
#  ${3} Input Bam file #1
#  ${4} Input Bam file #2
#  ${5} The experiment label. For the final filenames.
#  ${6} Temporary directory (ie /s/sansam-lab)
#-------------------------------------------------------------------------------
# side effects:
#  job ids
#-------------------------------------------------------------------------------

echo ${1}
echo ${2}
echo ${3}
echo ${4}
echo ${5}
echo ${6}

ml samtools

	NAME1=$(basename ${1} .bam)
	echo $NAME1
	NAME2=$(basename ${2} .bam)
	echo $NAME2
	NAME3=$(basename ${3} .bam)
	echo $NAME3
	NAME4=$(basename ${4} .bam)
	echo $NAME4
	EXPT=${5}
	echo $EXPT
	tmpDir=${6}
	echo $tmpDir

# Split bams into self pseudoreplicates

# define function
## Positional variables
## $1 bam file to split
## $2 output directory
function splitBam {
	NAME1=$(basename ${1} .bam)
	samtools view -@ 4 -H ${1} > ${2}/${NAME1}_header.sam
	nlines=$(samtools view -@ 4 ${1} | wc -l )
	nlines=$(( (nlines + 1) / 2 ))
	samtools view -@ 4 ${1} | shuf - | split -d -l ${nlines} - ${2}/${NAME1}
	cat ${2}/${NAME1}_header.sam ${2}/${NAME1}00 | samtools view -@ 10 -bS - > temp.bam
	samtools sort -@ 4 temp.bam > ${2}/${NAME1}_selfPseudoRep1.bam
	cat ${2}/${NAME1}_header.sam ${2}/${NAME1}01 | samtools view -@ 10 -bS - > temp.bam
	samtools sort -@ 4 temp.bam > ${2}/${NAME1}_selfPseudoRep2.bam
	rm ${2}/${NAME1}_header.sam
	rm ${2}/${NAME1}00
	rm ${2}/${NAME1}01
	rm temp.bam
}

## run function on sample or input bams
## sample bams
splitBam ${1} ${tmpDir}
splitBam ${2} ${tmpDir}
## input bams
splitBam ${3} ${tmpDir}
splitBam ${4} ${tmpDir}


# Generate pooled pseudoreplicates

## define function
### Positional variables
### $1 bam file 1
### $2 bam file 2
### $3 output directory
### $4 experiment label
function generatePooledPseudoreplicates {
	NAME1=$(basename ${1} .bam)
	NAME2=$(basename ${2} .bam)
	samtools merge -f -u ${4}_pooledPseudoRep2.bam ${NAME1}_selfPseudoRep2.bam ${NAME2}_selfPseudoRep2.bam
	samtools merge -f -u ${4}_pooledPseudoRep1.bam ${NAME1}_selfPseudoRep1.bam ${NAME2}_selfPseudoRep1.bam
}

generatePooledPseudoreplicates \
	${1} \
	${2} \
	${tmpDir} \
	$(basename ${1} .bam)$(basename ${2} .bam)

generatePooledPseudoreplicates \
	${3} \
	${4} \
	${tmpDir} \
	$(basename ${3} .bam)$(basename ${4} .bam)

cp ${1} .
cp ${2} .
cp ${3} .
cp ${4} .

for i in *.bam
do
	samtools index -@ 10 ${i}
done