###############################################################################
# (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "COPYING".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
from collections import defaultdict
from io import StringIO
import json
import difflib


def good_sequence(s):
    physics = s.startswith('hlt1') and 'validation' not in s
    extra = s in ('calo_prescaled_plus_lumi', 'passthrough')
    # not all lines produce a tck, list them here
    lines_not_producing_tcks = ['odqv']
    bad = any([line in s.lower() for line in lines_not_producing_tcks])
    return (physics or extra) and not bad


def sequence_differences(a, b, fromfile, tofile):
    io = StringIO()
    json.dump(a, io, indent=4)
    lines_json = [l + '\n' for l in io.getvalue().split('\n')]
    io = StringIO()
    json.dump(b, io, indent=4)
    lines_python = [l + '\n' for l in io.getvalue().split('\n')]
    return difflib.unified_diff(
        lines_json, lines_python, fromfile=fromfile, tofile=tofile)
