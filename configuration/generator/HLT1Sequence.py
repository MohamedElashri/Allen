from algorithms import *
from MuonSequence import Muon_sequence

def HLT1_sequence(validate=False):
  kalman_velo_only = kalman_velo_only_t()
  kalman_pv_ipchi2 = kalman_pv_ipchi2_t()
  fit_secondary_vertices = fit_secondary_vertices_t()
  
  prefix_sum_secondary_vertices = host_prefix_sum_t("prefix_sum_secondary_vertices",
    host_total_sum_holder_t="host_number_of_svs_t",
    dev_input_buffer_t=fit_secondary_vertices.dev_sv_atomics_t(),
    dev_output_buffer_t="dev_sv_offsets_t")

  consolidate_svs = consolidate_svs_t()
  run_hlt1 = run_hlt1_t()
  prepare_raw_banks = prepare_raw_banks_t()

  s = Muon_sequence(validate=False)
  s.extend_sequence(
    kalman_velo_only,
    kalman_pv_ipchi2,
    fit_secondary_vertices,
    prefix_sum_secondary_vertices,
    consolidate_svs,
    run_hlt1,
    prepare_raw_banks)

  if validate:
    s.validate()

  return s
