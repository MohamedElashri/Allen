###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
from HLT1Sequence import run_selections

selections = run_selections()
selections["dev_sel_rep_raw_banks"].producer.configuration().apply()
