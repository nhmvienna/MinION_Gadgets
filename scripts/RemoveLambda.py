import sys
from collections import defaultdict as d
from optparse import OptionParser, OptionGroup

# Author: Martin Kapun

#########################################################   HELP   #########################################################################
usage = "python %prog --input file --output file "
parser = OptionParser(usage=usage)
group = OptionGroup(parser, "< put description here >")

#########################################################   CODE   #########################################################################

parser.add_option("--input", dest="IN", help="Input file")
parser.add_option("--summary", dest="SU", help="Input file")

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


DATA = load_data(options.IN)

IDs = d(str)

for l in load_data(options.SU):
    if l.startswith("filename"):
        continue
    a = l.rstrip().split()
    if len(a) < 2:
        continue
    IDs[a[1]]

while True:
    H = DATA.readline()
    S = DATA.readline()
    DATA.readline()
    Q = DATA.readline().rstrip()
    if H.rstrip() == "":
        break
    if H[1].rstrip() in IDs:
        continue
    print(H + S + "+\n" + Q)
