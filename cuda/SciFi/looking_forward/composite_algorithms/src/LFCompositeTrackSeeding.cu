#include "LFCompositeTrackSeeding.cuh"
#include "Invoke.cuh"

void lf_composite_track_seeding_t::invoke() {
  invoke_helper(handler_lf_triplet_seeding);
  invoke_helper(handler_lf_triplet_keep_best);
  invoke_helper(handler_lf_extend_tracks_x);
}
