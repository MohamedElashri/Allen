###############################################################################
# (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
from GaudiConf import IOExtension
from PRConfig import TestFileDB

sample = TestFileDB.test_file_db['MiniBrunel_2018_MinBias_FTv4_MDF']
sample.setqualifiers(withDB=True)
IOExtension().inputFiles(list(set(sample.filenames)), clear=True)
