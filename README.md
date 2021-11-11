# IDRAnalysis

This generates pseudoreplicate bams for analysis of reproducibility using IDR as described in:
https://hbctraining.github.io/Intro-to-ChIPseq/lessons/07_handling-replicates-idr.html

## Generate all pseudoreplicate bams
```
sbatch \
--mem 128G \
--cpus-per-task 12 \
--wrap=\
"./MergeAndSplitBamsWithoutSubsampling.sh \
testBam3.bam \
testBam4.bam \
testBam3_input.bam \
testBam4_input.bam \
test \
test"
```
