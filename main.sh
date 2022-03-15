#### BASECALLING on cluster

output=/home/clusteradmin/Documents/mkapun/projects/GuppyCluster/test
name=neopleustes_70041

## make output directoy
mkdir -p ${output}

## go to node01
ssh node01

input=/media/inter/SeqData/raw/MinION/20220225_neopleustes_dzmb_70041/neopleustes_70041/20220225_1130_MC-111359_0_FAR44677_a20d42b6
output=/home/clusteradmin/Documents/mkapun/projects/GuppyCluster/test
username=mkapun
name=neopleustes_70041

## make local working directory & set WD variable
mkdir -p data_${name}

## copy data from phyloserver
echo "provide PW for user $username on phyloserver2"
scp -r ${username}@10.10.0.47:${input}/fast5_pass/ data_${name}

## set input folder
FAST5=data_${name}/fast5_pass

## count number of files
CF=`ls ${FAST5} | wc -l`

echo "total number of files: "$CF

## divide by 4
files=$(( ($CF+10)/4))
echo "number of files in 4 subsets"$files
i=0

## split folder in 4 equal parts
for file in ${FAST5}/*
do
  d=${name}_$(printf %03d $((i/$files+1)))
  mkdir -p data_${name}/$d
  cp "$file" data_${name}/$d
  let i++
  echo $i
done

## copy folders to nodes
for i in {1..4}

do

  scp -r data_${name}/${name}_00${i} node0${i}:
  echo $i

done

## remove data_${name} folder
rm -rf data_${name}

## go back to Phylo1
ssh phylo1

output=/home/clusteradmin/Documents/mkapun/projects/GuppyCluster/test
name=neopleustes_70041
input=/media/inter/SeqData/raw/MinION/20220225_neopleustes_dzmb_70041/neopleustes_70041/20220225_1130_MC-111359_0_FAR44677_a20d42b6


## start Basecalling
for i in {1..4}

do

  mkdir -p $output/HAC_${name}_00${i}

  echo """

  #!/bin/sh

  ## name of Job
  #PBS -N node0${i}

  ## Redirect output stream to this file.
  #PBS -o $output/HAC_${name}_00${i}/log.txt

  ## Stream Standard Output AND Standard Error to outputfile (see above)
  #PBS -j oe

  ## Select a maximum of 200 cores and 1000gb of RAM
  #PBS -l select=1:host=node0${i}

  ######## load dependencies #######

  module load ONT/guppy_6.0.1_gpu

  ######## run analyses #######

  guppy_basecaller \
  --input_path ${name}_00${i} \
  --config dna_r9.4.1_450bps_hac.cfg \
  --compress_fastq \
  --save_path HAC_${name}_00${i} \
  -x \"cuda:0\"

  """ > $output/HAC_${name}_00${i}/qsub_HAC_00${i}.sh

  qsub $output/HAC_${name}_00${i}/qsub_HAC_00${i}.sh

done

# wait until all jobs are finished

## retrieve summaries and delete FAST5 files
for i in {1..4}

do

  scp node0${i}:HAC_${name}_00${i}/sequencing_summary.txt $output/s${i}.ss
  ssh node0${i} rm -rf ${name}_00*

done

## combine summaries and copy to server
mv $output/s1.ss $output/sequencing_summary.txt

for i in {2..4}

do

  awk 'NR>1' $output/s${i}.ss >> $output/sequencing_summary.txt

done

rm -f $output/s*.ss

scp -r $output/sequencing_summary.txt mkapun@10.10.0.47:${input}/sequencing_summary_FAR44677_ac1db6e3_HAC.txt
