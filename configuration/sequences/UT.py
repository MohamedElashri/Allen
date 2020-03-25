from definitions.VeloSequence import VeloSequence
from definitions.PVSequence import PVSequence
from definitions.UTSequence import UTSequence
from definitions.algorithms import compose_sequences

ut_sequence = compose_sequences(VeloSequence(), PVSequence(), UTSequence())
ut_sequence.generate()
