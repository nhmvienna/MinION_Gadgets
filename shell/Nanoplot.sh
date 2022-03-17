#!/bin/bash

### do Nanoplot analysis

output=$1
input=$2
name=$3

mkdir $output

echo """
    #!/bin/sh

    ## name of Job
    #PBS -N ${name}

    ## Redirect output stream to this file.
    #PBS -o ${output}/log.txt

    ## Stream Standard Output AND Standard Error to outputfile (see above)
    #PBS -j oe

    ## Select a maximum of 200 cores and 200gb of RAM
    #PBS -l select=1:ncpus=100:mem=200gb

    ######## load dependencies #######

    source /opt/anaconda3/etc/profile.d/conda.sh
    conda activate nanoplot_1.32.1

    ######## run analyses #######
    NanoPlot \
      -t 100 \
      --summary ${input} \
      --maxlength 250000 \
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