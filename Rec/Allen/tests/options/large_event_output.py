###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the GNU General Public      #
# Licence version 3 (GPL Version 3), copied verbatim in the file "COPYING".   #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
from PyConf.application import ApplicationOptions

options = ApplicationOptions(_enabled=False)
options.geometry_version = 'run3/trunk'
options.conditions_version = 'master'
options.conddb_tag = 'sim-20220705-vc-md100'
options.dddb_tag = 'dddb-20220705'
options.input_files = ['large_event_passthrough.mdf']
options.input_type = 'MDF'
options.simulation = True
