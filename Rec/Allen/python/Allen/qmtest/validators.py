###############################################################################
# (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              #
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


def check_large_event_histograms(filename):
    from ROOT import TFile
    from AllenConf import persistency
    import re

    rbs = {b: re.compile(k) for k, b in persistency.rb_map.items()}

    mon_file = TFile.Open("large_event_passthrough.root")
    dr_histo = mon_file.Get("HltDecReportsMonitor/pass_count")
    rb_histo = mon_file.Get("HltRoutingBitsMonitor/rb_count")

    # The bin labels are the line names
    pass_counts = {}
    for i in range(dr_histo.GetNbinsX()):
        line_name = str(dr_histo.GetXaxis().GetLabels()[i])
        pass_counts[line_name] = int(dr_histo.GetBinContent(i + 1))

    line_name = None
    if len(pass_counts) == 1:
        line_name, n_evt = list(pass_counts.items())[0]
        matching_bits = [b for b, expr in rbs.items() if expr.match(line_name)]
        rb_counts = {b: rb_histo.GetBinContent(b + 1) for b in matching_bits}
    else:
        rb_counts = {}

    return line_name, pass_counts, rb_counts


def check_PV_efficiency(reference_file, causes, category):
    import re
    import os
    # Regular expression to find the line with the required category
    pattern = rf"\b{category}\s+:.*?\[\s*(\d+\.\d+)\s*%\],\s*false\s*(\d+)\s*from\s*reco\.\s*(\d+)\s*\(.*?\[\s*(\d+\.\d+)\s*%\]"
    with open(os.path.expandvars(reference_file)) as ref:
        file_contents = ref.read()  # Read the reference file into a string
        match = re.search(pattern, file_contents)

    if match:
        efficiency = float(match.group(1))
        fake_pv_percentage = float(match.group(4))
        if efficiency < 90:
            causes.append(
                "WARNING : The all tracks PV reconstruction efficiency = {}% is lower than 90% "
                .format(efficiency))
        if fake_pv_percentage > 3:
            causes.append(
                "WARNING : The all tracks number of fake PVs = {}% is higher than 3% "
                .format(fake_pv_percentage))

        return efficiency, fake_pv_percentage
    else:
        return None, None
