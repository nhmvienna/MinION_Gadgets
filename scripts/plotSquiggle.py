from ont_fast5_api.fast5_interface import get_fast5_file
from optparse import OptionParser, OptionGroup

# Author: Martin Kapun

#########################################################   HELP   #########################################################################
usage = "python %prog --input file --output file "
parser = OptionParser(usage=usage)
group = OptionGroup(parser, "< put description here >")

#########################################################   CODE   #########################################################################

parser.add_option("--input", dest="IN", help="Input file")
parser.add_option("--FASTQ", dest="FQ", help="FASTQ file")
parser.add_option("--output", dest="OUT", help="Output file")
parser.add_option(
    "--logical", dest="log", help="logical parameter", action="store_true"
)
parser.add_option("--param", dest="param",
                  help="numerical parameter", default=1)

(options, args) = parser.parse_args()
parser.add_option_group(group)


def DoSmthgInR(x, z):
    """ Use rpy2 to do something in r"""

    from rpy2.robjects import r
    import rpy2.robjects as robjects

    r.assign("Y", robjects.vectors.IntVector(x))
    r("library(ggplot2)")

    r("""newData<-data.frame("X"=seq(1,length(Y),1)/3000,"Y"=Y)""")
    r(
        """Plot<-ggplot(newData,aes(x=X,y=Y))+
                geom_line(col="blue")+
                xlab("Seconds")+
                ylab("pAmp")+
                theme(axis.text=element_text(size=40))+
                theme(axis.title = element_text(size = 30))+
                theme_bw()"""
    )

    r('ggsave(Plot,file="' + z + '.png",width=' + str(len(x) / 400) + ",height=5)")


def print_all_raw_data():
    # This can be a single- or multi-read file
    fast5_filepath = options.IN
    with get_fast5_file(fast5_filepath, mode="r") as f5:
        C = 0
        for read in f5.get_reads():
            if C > 10:
                break
            raw_data = read.get_raw_data()
            DoSmthgInR(list(raw_data), options.OUT + "/" + read.read_id)
            C += 1


def load_data(x):
    """ import data either from a gzipped or or uncrompessed file or from STDIN"""
    import gzip

    if x == "-":
        y = sys.stdin
    elif x.endswith(".gz"):
        y = gzip.open(x, "rt", encoding="latin-1")
    else:
        y = open(x, "r", encoding="latin-1")
    return y


print_all_raw_data()
