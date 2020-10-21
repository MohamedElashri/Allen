###############################################################################
# (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
from Configurables import LHCbApp
from PRConfig import TestFileDB

sample = TestFileDB.test_file_db[
    'upgrade-magdown-sim09c-up02-reco-up01-minbias-ldst']
sample.run(configurable=LHCbApp(), withDB=True)
