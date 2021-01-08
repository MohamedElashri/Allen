###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################

# See https://stackoverflow.com/questions/16981921/relative-imports-in-python-3
import sys
import os
PACKAGE_PARENT = '..'
SCRIPT_DIR = os.path.dirname(os.path.realpath(os.path.join(os.getcwd(), os.path.expanduser(__file__))))
sys.path.append(os.path.normpath(os.path.join(SCRIPT_DIR, PACKAGE_PARENT)))

import pytest
from minipyconf.cftree_ops import merge_execution_masks
from sympy import simplify

def test_merge_execution_masks():
    masks = [("alg1", "true"), ("alg1", "false")]
    should_be_merged = merge_execution_masks(masks)
    merged = {"alg1": "true"}
    assert simplify(should_be_merged["alg1"]) == simplify(merged["alg1"])
