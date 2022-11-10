## index lambda

# module load Alignment/ncbi-BLAST-2.12.0
#
# makeblastdb -in /home/mkapun/github/MinION_Gadgets/data/Lambda.fasta \
  # -dbtype nucl
#

input=$1
output=$2
summary=$3
name=$4

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
  #echo $ID

  gunzip -c $i \
    | sed -n '1~4s/^@/>/p;2~4p' \
    > ${output}/BLAST_${ID}.fa

  echo """
  #!/bin/sh

  ## name of Job
  #PBS -N BLAST_${ID}

  ## Redirect output stream to this file.
  #PBS -o ${output}/shell/log.txt

  ## Stream Standard Output AND Standard Error to outputfile (see above)
  #PBS -j oe

  ## Select a maximum of 150 cores and 200gb of RAM
  #PBS -l select=1:ncpus=5:mem=20gb

  ######## load dependencies #######

  module load Alignment/ncbi-BLAST-2.12.0

  ######## run analyses #######

  blastn \
    -num_threads 5 \
    -evalue 1e-100 \
    -outfmt \"6 qseqid sseqid qlen pident length mismatch evalue bitscore\" \
    -db /home/mkapun/github/MinION_Gadgets/data/Lambda.fasta \
    -query ${output}/BLAST_${ID}.fa \
    >> ${output}/blastn.txt

  rm -f ${output}/BLAST_${ID}.fa

  """ > ${output}/shell/qsub_BLAST_${ID}.sh

  qsub ${output}/shell/qsub_BLAST_${ID}.sh

done

while [[ `qstat -u $USER | grep 'BLAST_' | wc -l` -gt 0 ]]
do
  echo "still running..."
  sleep 5
done

rm -f ${output}/BLAST.fa

python ../scripts/filter_summary.py \
  --summary ${summary} \
  --blast ${output}/blastn.txt \
  > ${output}/sequencing_summary_lambda.txt

sh Nanoplot.sh \
  ${output}/sequencing_summary_lambda.txt \
  ${output}/nanoplot \
  lambda


folder=${input%/*}
type=${folder##*/}

for i in $input/*.gz

do

  python ../scripts/RemoveLambda.py \
    --summary ${output}/sequencing_summary_lambda.txt \
    --input $i \
    | gzip >> ${folder}/${name}_${type}.fq.gz

done
