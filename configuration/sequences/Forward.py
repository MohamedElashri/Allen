from definitions.VeloSequence import VeloSequence
from definitions.PVSequence import PVSequence
from definitions.UTSequence import UTSequence
from definitions.ForwardSequence import ForwardSequence
from definitions.algorithms import compose_sequences

forward_sequence = compose_sequences(VeloSequence(), PVSequence(),
                                     UTSequence(), ForwardSequence())
forward_sequence.generate()
