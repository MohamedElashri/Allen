###############################################################################
# (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
from GaudiConf import IOExtension
from PRConfig import TestFileDB

sample = TestFileDB.test_file_db['MiniBrunel_2018_MinBias_FTv4_MDF']
sample.setqualifiers(withDB=True)
IOExtension().inputFiles(list(set(sample.filenames)), clear=True)
