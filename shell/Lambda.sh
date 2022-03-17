## index lambda

# module load Alignment/ncbi-BLAST-2.12.0
#
# makeblastdb -in /home/mkapun/github/MinION_Gadgets/data/Lambda.fasta \
  # -dbtype nucl
#


#input=/media/inter/SeqData/raw/MinION/20220225_neopleustes_dzmb_70041/neopleustes_70041/20220225_1130_MC-111359_0_FAR44677_a20d42b6/pass_HAC
#output=/media/inter/SeqData/raw/MinION/20220225_neopleustes_dzmb_70041/neopleustes_70041/20220225_1130_MC-111359_0_FAR44677_a20d42b6/lambda_HAC

input=$1
output=$2


## change to home directory of scripts
BASEDIR=$(dirname $0)
cd $BASEDIR

## make output folders
mkdir -p ${output}/shell

## make header of BLAST file
printf "qseqid\tsseqid\tqlen\tpident\tlength\tmismatch\tevalue\tbitscore\n" > ${output}/blastn.txt

## FASTQ > FASTA
for i in $input/*.gz

do

  temp=${i##*/}
  ID=${temp%%.*}
  echo $ID

  gunzip -c $i \
    | sed -n '1~4s/^@/>/p;2~4p' \
    >> ${output}/BLAST.fa

done

echo """
  #!/bin/sh

  ## name of Job
  #PBS -N BLAST

  ## Redirect output stream to this file.
  #PBS -o ${output}/shell/log.txt

  ## Stream Standard Output AND Standard Error to outputfile (see above)
  #PBS -j oe

  ## Select a maximum of 150 cores and 200gb of RAM
  #PBS -l select=1:ncpus=150:mem=20gb

  ######## load dependencies #######

  module load Alignment/ncbi-BLAST-2.12.0

  ######## run analyses #######

  blastn \
    -num_threads 100 \
    -evalue 1e-100 \
    -outfmt \"6 qseqid sseqid qlen pident length mismatch evalue bitscore\" \
    -db /home/mkapun/github/MinION_Gadgets/data/Lambda.fasta \
    -query ${output}/BLAST.fa \
    >> ${output}/blastn.txt

""" > ${output}/shell/qsub_BLAST.sh

qsub -W block=true ${output}/shell/qsub_BLAST.sh

rm -f ${output}/BLAST.fa

python ../scripts/filter_summary.py \
  --summary ${input}/sequencing_summary.txt \
  --blast ${output}/blastn.txt \
  > ${output}/sequencing_summary_lambda.txt

sh Nanoplot.sh \
  ${output}/nanoplot \
  ${output}/sequencing_summary_lambda.txt \
  lambda
