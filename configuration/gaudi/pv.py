###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
from PVSequence import make_pvs

pvs = make_pvs()
pvs["dev_multi_final_vertices"].producer.configuration().apply()
