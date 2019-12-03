#include "LFCompositeExtendTracksUV.cuh"
#include "Invoke.cuh"

void lf_composite_extend_tracks_uv_t::invoke() {
  invoke_helper(handler_lf_search_uv_windows);
  invoke_helper(handler_lf_extend_tracks_uv);
}
