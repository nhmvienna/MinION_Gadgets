#!/bin/bash

### do Nanoplot analysis

input=$1
name=$2

mkdir ${input}/Nanoplot_full

header="""filename\tread_id\trun_id\tbatch_id\tchannel\tmux\tstart_time\tduration\tnum_events\tpasses_filtering\ttemplate_start\tnum_events_template\ttemplate_duration\tsequence_length_template\tmean_qscore_template\tstrand_score_template\tmedian_template\tmad_template\tscaling_median_template\tscaling_mad_template"""

printf ${header} > ${input}/Nanoplot_full/sequencing_summary.txt

for i in ${input}/*

do

  if [[ $i != ${input}/log && $i != ${input}/Nanoplot_full ]]
  then

    awk 'NR>1' $i/sequencing_summary.txt >> ${input}/Nanoplot_full/sequencing_summary.txt
    echo ${i##*/}

    output=${i}/Nanoplot
    mkdir ${output}

    echo """
      #!/bin/sh

      ## name of Job
      #PBS -N ${i##*/}

      ## Redirect output stream to this file.
      #PBS -o ${output}/log.txt

      ## Stream Standard Output AND Standard Error to outputfile (see above)
      #PBS -j oe

      ## Select a maximum of 200 cores and 200gb of RAM
      #PBS -l select=1:ncpus=10:mem=200gb

      ######## load dependencies #######

      source /opt/anaconda3/etc/profile.d/conda.sh
      conda activate nanoplot_1.32.1

      ######## run analyses #######
      NanoPlot \
        -t 100 \
        --summary $i/sequencing_summary.txt \
        --maxlength 1000000 \
        --plots dot -o ${output}/

      ################ make pdf report_test_Damen #############
      pandoc -f html \
        -t markdown \
        -o ${output}/NanoPlot-report.md \
        ${output}/NanoPlot-report.html

      awk '1;/### Plots/{exit}' ${output}/NanoPlot-report.md \
      > ${output}/NanoPlot-report_cut.md

      for i in ${output}/*.png
      do
        File=\${i##*/}
        Name=\${File%.*}
        echo '!['\$Name']('\$i')' >> ${output}/NanoPlot-report_cut.md
      done

      pandoc -f markdown \
        -t latex \
        -o ${output}/NanoPlot-report_${name}_${i##*/}.pdf \
        ${output}/NanoPlot-report_cut.md

      rm -f ${output}/NanoPlot-report*.md
      ######################
    """ > ${output}/qsub_nanoplot.sh

    qsub ${output}/qsub_nanoplot.sh

  fi

done

output=${input}/Nanoplot_full

echo """
    #!/bin/sh

    ## name of Job
    #PBS -N full

    ## Redirect output stream to this file.
    #PBS -o ${output}/log.txt

    ## Stream Standard Output AND Standard Error to outputfile (see above)
    #PBS -j oe

    ## Select a maximum of 200 cores and 200gb of RAM
    #PBS -l select=1:ncpus=10:mem=200gb

    ######## load dependencies #######

    source /opt/anaconda3/etc/profile.d/conda.sh
    conda activate nanoplot_1.32.1

    ######## run analyses #######
    NanoPlot \
      -t 100 \
      --summary ${input}/Nanoplot_full/sequencing_summary.txt \
      --maxlength 1000000 \
      --plots dot -o ${output}/

    ################ make pdf report_test_Damen #############
    pandoc -f html \
      -t markdown \
      -o ${output}/NanoPlot-report.md \
      ${output}/NanoPlot-report.html

    awk '1;/### Plots/{exit}' ${output}/NanoPlot-report.md \
    > ${output}/NanoPlot-report_cut.md

    for i in ${output}/*.png
    do
      File=\${i##*/}
      Name=\${File%.*}
      echo '!['\$Name']('\$i')' >> ${output}/NanoPlot-report_cut.md
    done

    pandoc -f markdown \
      -t latex \
      -o ${output}/NanoPlot-report_${name}.pdf \
      ${output}/NanoPlot-report_cut.md

    rm -f ${output}/NanoPlot-report*.md
    ######################
""" > ${output}/qsub_nanoplot.sh

qsub ${output}/qsub_nanoplot.sh
