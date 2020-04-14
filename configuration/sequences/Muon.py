from definitions.VeloSequence import VeloSequence
from definitions.PVSequence import PVSequence
from definitions.UTSequence import UTSequence
from definitions.ForwardSequence import ForwardSequence
from definitions.MuonSequence import MuonSequence
from definitions.algorithms import compose_sequences

muon_sequence = compose_sequences(VeloSequence(), PVSequence(), UTSequence(),
                                  ForwardSequence(), MuonSequence())
muon_sequence.generate()
