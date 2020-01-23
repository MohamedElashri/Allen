from HLT1Sequence import HLT1_sequence

s = HLT1_sequence(validate=False)

s["compass_ut_t"].set_property("max_considered_before_found", "16")
s["compass_ut_t"].set_property("sigma_velo_slope", "0.00010")
s["compass_ut_t"].set_property("min_momentum_final", "0.0")
s["compass_ut_t"].set_property("min_pt_final", "0.0")
s["compass_ut_t"].set_property("hit_tol_2", "0.8")
s["compass_ut_t"].set_property("delta_tx_2", "0.018")
