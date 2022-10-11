/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "FindMuonHits.cuh"

#include "Common.h"
#include <string>

INSTANTIATE_ALGORITHM(find_muon_hits::find_muon_hits_t)

void find_muon_hits::find_muon_hits_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_muon_tracks_t>(
    arguments, Muon::Constants::max_number_of_tracks * first<host_number_of_events_t>(arguments));
  set_size<dev_muon_number_of_tracks_t>(arguments, first<host_number_of_events_t>(arguments));
}

void find_muon_hits::find_muon_hits_t::output_monitor(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Allen::Context& context) const
{
  auto handler = runtime_options.root_service->handle(name());
  auto tree = handler.tree("monitor_tree");

  float chi2x, chi2y, tx, ty, ax, ay, x0, x1, x2, x3, y0, y1, y2, y3, z0, z1, z2, z3, dx0, dx1, dx2, dx3, dy0, dy1, dy2,
    dy3;
  handler.branch(tree, "chi2y", chi2y);
  handler.branch(tree, "chi2x", chi2x);
  handler.branch(tree, "ty", ty);
  handler.branch(tree, "tx", tx);
  handler.branch(tree, "ay", ay);
  handler.branch(tree, "ax", ax);
  handler.branch(tree, "x0", x0);
  handler.branch(tree, "x1", x1);
  handler.branch(tree, "x2", x2);
  handler.branch(tree, "x3", x3);
  handler.branch(tree, "dx0", dx0);
  handler.branch(tree, "dx1", dx1);
  handler.branch(tree, "dx2", dx2);
  handler.branch(tree, "dx3", dx3);
  handler.branch(tree, "y0", y0);
  handler.branch(tree, "y1", y1);
  handler.branch(tree, "y2", y2);
  handler.branch(tree, "y3", y3);
  handler.branch(tree, "dy0", dy0);
  handler.branch(tree, "dy1", dy1);
  handler.branch(tree, "dy2", dy2);
  handler.branch(tree, "dy3", dy3);
  handler.branch(tree, "z0", z0);
  handler.branch(tree, "z1", z1);
  handler.branch(tree, "z2", z2);
  handler.branch(tree, "z3", z3);

  const auto host_station_ocurrences_offset = make_host_buffer<dev_station_ocurrences_offset_t>(arguments, context);
  const auto host_muon_hits = make_host_buffer<dev_muon_hits_t>(arguments, context);
  const auto host_muon_tracks = make_host_buffer<dev_muon_tracks_t>(arguments, context);
  const auto host_muon_number_of_tracks = make_host_buffer<dev_muon_number_of_tracks_t>(arguments, context);

  const auto n_tracks = host_muon_number_of_tracks.data();
  const auto tracks = host_muon_tracks.data();
  const auto muon_hits = host_muon_hits.data();
  const auto muon_offsets = host_station_ocurrences_offset.data();
  const auto n_events = first<host_number_of_events_t>(arguments);

  const auto muon_total_number_of_hits = muon_offsets[n_events * Muon::Constants::n_stations];
  const auto event_muon_hits = Muon::ConstHits {muon_hits, muon_total_number_of_hits};
  for (unsigned event_number = 0; event_number < n_events; event_number++) {
    for (unsigned i_track = 0; i_track < n_tracks[event_number]; i_track++) {
      const MuonTrack track = tracks[event_number * Muon::Constants::max_number_of_tracks + i_track];
      std::array<float, 4> x {-99999.f, -99999.f, -99999.f, -99999.f};
      std::array<float, 4> y {-99999.f, -99999.f, -99999.f, -99999.f};
      std::array<float, 4> dx {-99999.f, -99999.f, -99999.f, -99999.f};
      std::array<float, 4> dy {-99999.f, -99999.f, -99999.f, -99999.f};
      std::array<float, 4> z {-99999.f, -99999.f, -99999.f, -99999.f};

      for (unsigned muon_st = 0; muon_st < 4; muon_st++) {
        const int muon_idx = track.hit(muon_st);
        if (muon_idx != -1) {
          x[muon_st] = event_muon_hits.x(muon_idx);
          y[muon_st] = event_muon_hits.y(muon_idx);
          dx[muon_st] = event_muon_hits.dx(muon_idx);
          dy[muon_st] = event_muon_hits.dy(muon_idx);
          z[muon_st] = event_muon_hits.z(muon_idx);
        }
      }

      std::tie(x0, x1, x2, x3) = std::make_tuple(x[0], x[1], x[2], x[3]);
      std::tie(y0, y1, y2, y3) = std::make_tuple(y[0], y[1], y[2], y[3]);
      std::tie(z0, z1, z2, z3) = std::make_tuple(z[0], z[1], z[2], z[3]);
      std::tie(dx0, dx1, dx2, dx3) = std::make_tuple(dx[0], dx[1], dx[2], dx[3]);
      std::tie(dy0, dy1, dy2, dy3) = std::make_tuple(dy[0], dy[1], dy[2], dy[3]);
      std::tie(chi2x, chi2y, tx, ty, ax, ay) =
        std::make_tuple(track.chi2x(), track.chi2y(), track.tx(), track.ty(), track.ax(), track.ay());
      tree->Fill();
    }
  }
}

void find_muon_hits::find_muon_hits_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_muon_number_of_tracks_t>(arguments, 0, context);

  global_function(find_muon_hits)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_x_t>(), context)(
    arguments, constants.dev_match_windows);
  if (property<enable_monitoring_t>()) output_monitor(arguments, runtime_options, context);
}

__device__ bool applyWeightedFit(MuonTrack& muon_track, Muon::ConstHits& muon_hits, bool xz)
{
  const auto n_hits_track = muon_track.number_of_hits();
  float sz2, sz, s0, sxz, sx, sx2;
  sz2 = sz = s0 = sxz = sx = sx2 = 0.f;
  for (unsigned i_hit = 0; i_hit < 4; i_hit++) {
    if (muon_track.hit(i_hit) == -1) continue;
    float z = muon_hits.z(muon_track.hit(i_hit));
    float coord, coorderr;

    if (xz) {
      coord = muon_hits.x(muon_track.hit(i_hit));
      coorderr = 2.f * muon_hits.dx(muon_track.hit(i_hit));
    }
    else {
      coord = muon_hits.y(muon_track.hit(i_hit));
      coorderr = 2.f * muon_hits.dy(muon_track.hit(i_hit));
    }

    sz2 += z * z / coorderr / coorderr;
    sz += z / coorderr / coorderr;
    s0 += 1.f / coorderr / coorderr;
    sxz += z * coord / coorderr / coorderr;
    sx += coord / coorderr / coorderr;
    sx2 += coord * coord / coorderr / coorderr;
  }

  float slope, a, chi2ndof;
  slope = a = chi2ndof = 9999.f;
  float det = sz2 * s0 - sz * sz;
  if (det != 0.f) {
    slope = (sxz * s0 - sx * sz) / det;
    a = (sx * sz2 - sxz * sz) / det;

    chi2ndof = (sx2 + slope * slope * sz2 + a * a * s0 - 2.f * slope * sxz - 2.f * a * sx + 2.f * slope * a * sz) /
               (n_hits_track - 2);
  }
  else
    return false;
  if (xz) {
    muon_track.tx() = slope;
    muon_track.ax() = a;
    muon_track.chi2x() = chi2ndof;
    muon_track.state() = muon_track.hit(Muon::Constants::M2);
  }
  else {
    muon_track.ty() = slope;
    muon_track.ay() = a;
    muon_track.chi2y() = chi2ndof;
  }
  return true;
}

__device__ int find_compatible_hit_in_station(
  float x,
  float y,
  unsigned region_seed,
  unsigned i_station,
  const unsigned* station_ocurrences_offset,
  const Muon::ConstHits muon_hits,
  const float* Xmax,
  const float* Ymax)
{
  const auto station_offset = station_ocurrences_offset[i_station];
  const auto nhits_i_station = station_ocurrences_offset[i_station + 1] - station_offset;
  const auto xmax = Xmax[i_station * 4 + region_seed];
  const auto ymax = Ymax[i_station * 4 + region_seed];

  int track_index = -1;
  float delta2min;

  for (unsigned i_hit = 0; i_hit < nhits_i_station; i_hit++) {
    const auto idx = station_offset + i_hit;
    const auto deltaX = fabsf(x - muon_hits.x(idx));
    const auto deltaY = fabsf(y - muon_hits.y(idx));
    const auto delta2 = deltaX * deltaX + deltaY * deltaY;

    if (deltaX < xmax && deltaY < ymax && (track_index == -1 || delta2 < delta2min)) {
      delta2min = delta2;
      track_index = static_cast<int>(i_hit);
    }
  }
  return track_index;
}

__device__ std::pair<float, float> extrapolate(
  const Muon::ConstHits muon_hits,
  const float* z,
  const MuonTrack& muon_track,
  const unsigned& current_index,
  const unsigned& previous_index,
  const unsigned& following_index)
{
  const auto x_current_station = muon_hits.x(muon_track.hit(current_index));
  const auto x_previous_station = muon_hits.x(muon_track.hit(previous_index));
  const auto y_current_station = muon_hits.y(muon_track.hit(current_index));
  const auto y_previous_station = muon_hits.y(muon_track.hit(previous_index));
  const auto z_previous_station = muon_hits.z(muon_track.hit(previous_index));
  const auto z_following_station = z[following_index];
  const auto z_current_station = muon_hits.z(muon_track.hit(current_index));
  auto x = x_current_station + (x_current_station - x_previous_station) / (z_current_station - z_previous_station) *
                                 (z_following_station - z_current_station);
  auto y = y_current_station + (y_current_station - y_previous_station) / (z_current_station - z_previous_station) *
                                 (z_following_station - z_current_station);
  return std::pair {x, y};
}

__device__ void seedAndFind(
  Muon::ConstHits muon_hits,
  const unsigned* station_ocurrences_offset,
  const int* st_order,
  unsigned n_stations,
  Muon::Constants::MatchWindows match_windows,
  int required_station,
  int required_number_of_hits,
  unsigned& number_of_muon_tracks_atomic,
  MuonTrack* muon_tracks)
{

  const auto first_st_ocurrences_offset = station_ocurrences_offset[st_order[0]];
  const auto number_of_hits_first_st = station_ocurrences_offset[st_order[0] + 1] - first_st_ocurrences_offset;
  for (unsigned seed = threadIdx.x; seed < number_of_hits_first_st; seed += blockDim.x) {
    const unsigned first_st_abs_idx = first_st_ocurrences_offset + seed;
    const auto xseed = muon_hits.x(first_st_abs_idx);
    const auto yseed = muon_hits.y(first_st_abs_idx);
    const auto zseed_inverse = 1.f / muon_hits.z(first_st_abs_idx);
    auto region_seed = muon_hits.region(first_st_abs_idx);

    MuonTrack muon_track;
    muon_track.add_hit_to_station(first_st_abs_idx, st_order[0]);

    float x, y;
    std::array<int, 2> last_two_stations_found {st_order[0], -1};

    for (unsigned i_station = 1; i_station < n_stations; i_station++) {
      const auto station = st_order[i_station];
      if (muon_track.number_of_hits() >= 2) {
        // Update x, y parameters by extrapolating the building track
        const auto xy = extrapolate(
          muon_hits,
          match_windows.z_station,
          muon_track,
          last_two_stations_found[0],
          last_two_stations_found[1],
          station);
        x = xy.first;
        y = xy.second;
      }
      else {
        // Create x, y parameters by linear extrapolation from origin
        const auto slope = match_windows.z_station[station] * zseed_inverse;
        x = xseed * slope;
        y = yseed * slope;
      }

      const auto hit_index = find_compatible_hit_in_station(
        x, y, region_seed, station, station_ocurrences_offset, muon_hits, match_windows.Xmax, match_windows.Ymax);

      if (hit_index != -1) {
        const auto idx = station_ocurrences_offset[station] + hit_index;
        muon_track.add_hit_to_station(idx, station);
        last_two_stations_found[1] = last_two_stations_found[0];
        last_two_stations_found[0] = station;
        region_seed = muon_hits.region(station_ocurrences_offset[station] + hit_index);
      }
      else
        break;
    }

    if (muon_track.number_of_hits() == required_number_of_hits && muon_track.hit(required_station) != -1) {
      auto fit_result_xz = applyWeightedFit(muon_track, muon_hits, true);
      auto fit_result_yz = applyWeightedFit(muon_track, muon_hits, false);
      if (fit_result_xz && fit_result_yz) {
        const auto insert_index = atomicAdd(&number_of_muon_tracks_atomic, 1);
        muon_tracks[insert_index] = muon_track;
      }
    }
  }
}

__global__ void find_muon_hits::find_muon_hits(
  find_muon_hits::Parameters parameters,
  const Muon::Constants::MatchWindows* dev_match_windows)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  const auto muon_total_number_of_hits =
    parameters.dev_station_ocurrences_offset[number_of_events * Muon::Constants::n_stations];
  const auto station_ocurrences_offset =
    parameters.dev_station_ocurrences_offset + event_number * Muon::Constants::n_stations;
  const auto muon_hits = Muon::ConstHits {parameters.dev_muon_hits, muon_total_number_of_hits};

  // Output
  auto tracks_offset = event_number * Muon::Constants::max_number_of_tracks;
  auto event_muon_tracks = parameters.dev_muon_tracks + tracks_offset;

  auto event_number_of_tracks = parameters.dev_muon_number_of_tracks + event_number;

  // Station processing order
  constexpr std::array<int, 4> st_order {
    Muon::Constants::M5, Muon::Constants::M4, Muon::Constants::M3, Muon::Constants::M2};

  const auto match_windows = dev_match_windows[0];
  __shared__ float muon_tracks_shared_container[Muon::Constants::max_number_of_tracks * sizeof(MuonTrack)];
  MuonTrack* muon_tracks = reinterpret_cast<MuonTrack*>(muon_tracks_shared_container);
  __shared__ unsigned number_of_muon_tracks_atomic;
  if (threadIdx.x == 0) number_of_muon_tracks_atomic = 0;

  __syncthreads();
  seedAndFind(
    muon_hits,
    station_ocurrences_offset,
    st_order.data(),
    Muon::Constants::n_stations,
    match_windows,
    Muon::Constants::M2,
    parameters.required_number_of_hits,
    number_of_muon_tracks_atomic,
    muon_tracks);

  __syncthreads();

  // Clone killing
  const auto is_clone_of = [&](const MuonTrack& track_a, const MuonTrack& track_b) {
    if (
      track_a.hit(Muon::Constants::M2) == track_b.hit(Muon::Constants::M2) ||
      track_a.hit(Muon::Constants::M3) == track_b.hit(Muon::Constants::M3) ||
      ((track_a.hit(Muon::Constants::M4) != -1 &&
        track_a.hit(Muon::Constants::M4) == track_b.hit(Muon::Constants::M4)) ||
       (track_a.hit(Muon::Constants::M5) != -1 &&
        track_a.hit(Muon::Constants::M5) == track_b.hit(Muon::Constants::M5)))) {

      auto chi2_ax = track_a.m_chi2x;
      auto chi2_ay = track_a.m_chi2y;

      auto chi2_bx = track_b.m_chi2x;
      auto chi2_by = track_b.m_chi2y;

      return (((chi2_ax + chi2_ay) > (chi2_bx + chi2_by)) - ((chi2_ax + chi2_ay) < (chi2_bx + chi2_by)));
    }
    return -1;
  };

  for (unsigned track = threadIdx.x; track < number_of_muon_tracks_atomic; track += blockDim.x) {
    const auto muon_track = muon_tracks[track];
    bool is_clone = false;

    for (unsigned other_track = 0; other_track < number_of_muon_tracks_atomic; ++other_track) {
      if (track != other_track) {
        const int is_clone_of_value = is_clone_of(muon_track, muon_tracks[other_track]);
        if (is_clone_of_value == 1 || (is_clone_of_value == 0 && track > other_track)) {
          is_clone = true;
          break;
        }
      }
    }
    if (!is_clone) {
      const auto insert_index = atomicAdd(event_number_of_tracks, 1);
      event_muon_tracks[insert_index] = muon_track;
    }
  }
}
