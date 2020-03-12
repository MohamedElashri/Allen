###############################################################################
# (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      #
#                                                                             #
# This software is distributed under the terms of the GNU General Public      #
# Licence version 3 (GPL Version 3), copied verbatim in the file "COPYING".   #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
from Configurables import LHCbApp
from PRConfig import TestFileDB

sample = TestFileDB.test_file_db[
    'upgrade-magdown-sim09c-up02-reco-up01-minbias-ldst']
sample.run(configurable=LHCbApp(), withDB=True)
