from definitions.VeloSequence import VeloSequence
from definitions.PVSequence import PVSequence
from definitions.algorithms import compose_sequences

pv_sequence = compose_sequences(VeloSequence(), PVSequence())
pv_sequence.generate()
