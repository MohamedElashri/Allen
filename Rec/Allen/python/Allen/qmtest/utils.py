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


def good_sequence(s):
    physics = s.startswith('hlt1') and 'validation' not in s
    extra = s in ('calo_prescaled_plus_lumi', 'passthrough')
    return physics or extra


def print_sequence_differences(a, b):
    diff_keys = set(a.keys()).symmetric_difference(set(b.keys()))
    diff = defaultdict(dict)
    ka = [k for k in a.keys() if k not in diff_keys]
    for k in ka:
        props_a = a[k]
        props_b = b[k]
        diff_prop_keys = set(props_a.keys()).symmetric_difference(
            set(props_b.keys()))
        pka = [k for k in props_a.keys() if k not in diff_prop_keys]
        for prop_key in pka:
            if props_a[prop_key] != props_b[prop_key]:
                diff[k][prop_key] = (props_a[prop_key], props_b[prop_key])

    return dict(diff)
