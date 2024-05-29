import sys
from collections import defaultdict as d
from optparse import OptionParser, OptionGroup

# Author: Martin Kapun

#########################################################   HELP   #########################################################################
usage = "python %prog --input file --output file "
parser = OptionParser(usage=usage)
group = OptionGroup(parser, '< put description here >')

#########################################################   CODE   #########################################################################

parser.add_option("--summary", dest="IN", help="Input file")
parser.add_option("--barcode", dest="IN2", help="Input file")

(options, args) = parser.parse_args()
parser.add_option_group(group)


def load_data(x):
    ''' import data either from a gzipped or or uncrompessed file or from STDIN'''
    import gzip
    if x == "-":
        y = sys.stdin
    elif x.endswith(".gz"):
        y = gzip.open(x, "rt", encoding="latin-1")
    else:
        y = open(x, "r", encoding="latin-1")
    return y


def meanstdv(x):
    ''' calculate mean, stdev and standard error : x must be a list of numbers'''
    from math import sqrt
    n, mean, std, se = len(x), 0, 0, 0
    if len(x) == 0:
        return "na", "na", "na"
    for a in x:
        mean = mean + a
    mean = mean / float(n)
    if len(x) > 1:
        for a in x:
            std = std + (a - mean)**2
        std = sqrt(std / float(n-1))
        se = std/sqrt(n)
    else:
        std = 0
        se = 0
    return mean, std, se


Qcount = d(int)
Qbac = d(lambda: d(list))
Qlength = d(list)
Qscore = d(int)
for l in load_data(options.IN):
    a = l.rstrip().split()
    if a[14] != "mean_qscore_template":
        Qscore[a[1]] = float(a[14])
        Qlength[a[1]] = float(a[13])

for l in load_data(options.IN2):
    a = l.rstrip().split()
    Qcount[a[1]] += 1
    Qbac[a[1]]["Qual"].append(Qscore[a[0]])
    Qbac[a[1]]["Len"].append(Qlength[a[0]])

C = 0
print("Barcode\tReadCount\tAvQual\tSDQual\tSEQual\tAvLength\tSDLength\tSELength")
for k, v in sorted(Qcount.items()):
    if k == "barcode_arrangement":
        continue
    print(str(k),
          str(v),
          "\t".join([str(round(x, 2)) for x in meanstdv(
              Qbac[k]["Qual"])]),
          "\t".join([str(round(x, 1)) for x in meanstdv(Qbac[k]["Len"])]),
          sep="\t")
    C += v

# print(C)
