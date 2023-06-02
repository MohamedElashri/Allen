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
from PyConf.application import ApplicationOptions
from Configurables import DumpBeamline

options = ApplicationOptions(_enabled=False)
options.simulation = True
options.input_type = "ROOT"
options.input_files = [
    "root://tmp@eoslhcb.cern.ch//eos/lhcb/grid/prod/lhcb/MC/Dev/DIGI/00183018/0000/00183018_00000098_1.digi"
]
options.dddb_tag = "dddb-20230313"
options.conddb_tag = "sim-20230313-vc-md100"
options.data_type = "Upgrade"
# Simulated beam position is at: (1.092, 0.474) while the Velo is at
# (0.0, 0.45), so the offset should be (1.092, 0.024).
# Information obtained from:
# - https://gitlab.cern.ch/lhcb-conddb/DDDB/-/merge_requests/121
# - https://gitlab.cern.ch/lhcb-conddb/SIMCOND/-/merge_requests/207
DumpBeamline().Offset = (1.092, 0.024)
