###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
from definitions.GECSequence import GECSequence
from definitions.VeloSequence import VeloSequence
from definitions.algorithms import compose_sequences

gec_sequence = GECSequence()

velo_sequence = VeloSequence(gec_sequence['initialize_lists'])

compose_sequences(gec_sequence, velo_sequence).generate()
