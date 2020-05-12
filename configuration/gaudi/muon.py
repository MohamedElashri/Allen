from MuonSequence import is_muon

is_muon_result = is_muon()
is_muon_result["dev_is_muon"].producer().configuration().apply()
