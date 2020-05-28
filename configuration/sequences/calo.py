from definitions.GECSequence import GECSequence
from definitions.CaloSequence import CaloSequence
from definitions.algorithms import compose_sequences

gec_sequence = GECSequence()

calo_sequence = CaloSequence(gec_sequence['initialize_lists'])

compose_sequences(gec_sequence, calo_sequence).generate()
