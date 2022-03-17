import sys
from collections import defaultdict as d

from optparse import OptionParser, OptionGroup

# Author: Martin Kapun

#########################################################   HELP   #########################################################################
usage = "python %prog --input file --output file "
parser = OptionParser(usage=usage)
group = OptionGroup(parser, "< put description here >")

#########################################################   CODE   #########################################################################

parser.add_option("--summary", dest="SU", help="Input sequencing_summary file")
parser.add_option("--blast", dest="blast", help="BLAST output")

(options, args) = parser.parse_args()
parser.add_option_group(group)


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


# parse BLAST
IDs = d(str)

for l in load_data(options.blast):
    a = l.rstrip().split()
    if l.startswith("qseqid"):
        continue
    IDs[a[0]]

for l in load_data(options.SU):
    a = l.rstrip().split()
    if l.startswith("filename"):
        print(l.rstrip())
        header = a
        continue
    DICT = {header[x]: a[x] for x in range(len(header))}
    if DICT["read_id"] in IDs:
        print(l.rstrip())
