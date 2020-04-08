#include "CompassUTDefinitions.cuh"

__device__ short TrackCandidates::get_from(int layer, int sector) const {
  return m_base_pointer
    [sector * UT::Constants::n_layers * UT::Constants::num_thr_compassut + layer * UT::Constants::num_thr_compassut +
     threadIdx.x];
}

__device__ short TrackCandidates::get_size(int layer, int sector) const {
  return m_base_pointer
    [(sector + (CompassUT::num_elems / 2)) * UT::Constants::n_layers * UT::Constants::num_thr_compassut +
     layer * UT::Constants::num_thr_compassut + threadIdx.x];
}
