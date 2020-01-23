from VeloSequence import VELO_sequence
from PVSequence import PV_sequence
from UTSequence import UT_sequence
from ForwardSequence import Forward_sequence
from MuonSequence import Muon_sequence
from HLT1Sequence import HLT1_sequence

default_sequence = HLT1_sequence()
default_sequence.generate(output_filename = "generated/DefaultSequence.h",
    json_configuration_filename = "generated/DefaultSequence.json")

ut_sequence = UT_sequence()
ut_sequence.generate(output_filename = "generated/UT.h",
    json_configuration_filename = "generated/UT.json")

velo_sequence = VELO_sequence()
velo_sequence.generate(output_filename = "generated/VELO.h",
    json_configuration_filename = "generated/VELO.json")

pv_sequence = PV_sequence()
pv_sequence.generate(output_filename = "generated/PV.h",
    json_configuration_filename = "generated/PV.json")

muon_sequence = Muon_sequence()
muon_sequence.generate(output_filename = "generated/Muon.h",
    json_configuration_filename = "generated/Muon.json")

forward_sequence = Forward_sequence()
forward_sequence.generate(output_filename = "generated/Forward.h",
    json_configuration_filename = "generated/Forward.json")
