###############################################################################
# (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the GNU General Public      #
# Licence version 3 (GPL Version 3), copied verbatim in the file "COPYING".   #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
def checkSizes(reference_file, causes, result):
    import os

    ref_sizes = {}
    with open(os.path.expandvars(reference_file)) as ref:
        for line in ref:
            f, s = line.strip().split()
            ref_sizes[f] = int(s)

    missing = []
    bad_size = []
    for f, s in ref_sizes.items():
        if not os.path.exists(f):
            missing.append(f)
        else:
            size = os.stat(f).st_size
            if size != s:
                bad_size.append((f, size, s))

    result_str = ''
    if not missing and not bad_size:
        result_str += 'Files and sizes match\n'
    if missing:
        causes.append("missing files")
        result_str += 'Missing:\n\t' + '\n\t'.join(missing) + '\n'
    if bad_size:
        pat = "%s is %d bytes instead of %d"
        causes.append("file size mismatch(es)")
        result_str += (
            'Wrong size:\n\t' + '\n\t'.join([pat % e
                                             for e in bad_size]) + '\n')

    result["validator.output"] = result.Quote(result_str)
