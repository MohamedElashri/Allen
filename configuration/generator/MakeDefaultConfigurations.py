from VeloSequence import VELO_sequence
from PVSequence import PV_sequence
from UTSequence import UT_sequence
from ForwardSequence import Forward_sequence
from MuonSequence import Muon_sequence
from HLT1Sequence import HLT1_sequence
from base_types import compose_sequences

velo_sequence = VELO_sequence()
velo_sequence.generate(
    output_filename="generated/VELO.h",
    json_configuration_filename="generated/VELO.json",
    generate_json_defaults=True)

pv_sequence = compose_sequences(VELO_sequence(), PV_sequence())
pv_sequence.generate(
    output_filename="generated/PV.h",
    json_configuration_filename="generated/PV.json")

ut_sequence = compose_sequences(VELO_sequence(), PV_sequence(), UT_sequence())
ut_sequence.generate(
    output_filename="generated/UT.h",
    json_configuration_filename="generated/UT.json")

forward_sequence = compose_sequences(VELO_sequence(), PV_sequence(),
                                     UT_sequence(), Forward_sequence())
forward_sequence.generate(
    output_filename="generated/Forward.h",
    json_configuration_filename="generated/Forward.json")

muon_sequence = compose_sequences(VELO_sequence(), PV_sequence(),
                                  UT_sequence(), Forward_sequence(),
                                  Muon_sequence())
muon_sequence.generate(
    output_filename="generated/Muon.h",
    json_configuration_filename="generated/Muon.json")

hlt1_sequence = compose_sequences(VELO_sequence(), PV_sequence(),
                                  UT_sequence(), Forward_sequence(),
                                  Muon_sequence(), HLT1_sequence())
hlt1_sequence.generate(
    output_filename="generated/DefaultSequence.h",
    json_configuration_filename="generated/DefaultSequence.json")

hlt1_sequence.generate(
    output_filename="generated/HLT1.h",
    json_configuration_filename="generated/HLT1.json")

hlt1_noutcut_sequence = compose_sequences(VELO_sequence(), PV_sequence(),
                                          UT_sequence(restricted=False),
                                          Forward_sequence(), Muon_sequence(),
                                          HLT1_sequence())
hlt1_noutcut_sequence.generate(
    output_filename="generated/HLT1_NoUTCut.h",
    json_configuration_filename="generated/HLT1_NoUTCut.json")
