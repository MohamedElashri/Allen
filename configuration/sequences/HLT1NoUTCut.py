from definitions.VeloSequence import VeloSequence
from definitions.PVSequence import PVSequence
from definitions.UTSequence import UTSequence
from definitions.ForwardSequence import ForwardSequence
from definitions.MuonSequence import MuonSequence
from definitions.HLT1Sequence import HLT1Sequence
from definitions.algorithms import compose_sequences


hlt1_sequence = compose_sequences(VeloSequence(), PVSequence(),
                                  UTSequence(restricted=False), ForwardSequence(),
                                  MuonSequence(), HLT1Sequence())
hlt1_sequence.generate()
