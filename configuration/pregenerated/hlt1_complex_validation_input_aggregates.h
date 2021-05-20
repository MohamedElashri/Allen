#pragma once

#include <tuple>
#include "..//device/selections/lines/inclusive_hadron/include/TwoTrackMVALine.cuh"
#include "..//device/selections/lines/inclusive_hadron/include/TrackMVALine.cuh"

struct Hlt1TrackMVA_Restricted__dev_decisions_t : track_mva_line::Parameters::dev_decisions_t {
  using type = track_mva_line::Parameters::dev_decisions_t::type;
  using deps = track_mva_line::Parameters::dev_decisions_t::deps;
};
struct Hlt1TwoTrackMVA_Restricted__dev_decisions_t : two_track_mva_line::Parameters::dev_decisions_t {
  using type = two_track_mva_line::Parameters::dev_decisions_t::type;
  using deps = two_track_mva_line::Parameters::dev_decisions_t::deps;
};
struct Hlt1TrackMVA_Non_Restricted__dev_decisions_t : track_mva_line::Parameters::dev_decisions_t {
  using type = track_mva_line::Parameters::dev_decisions_t::type;
  using deps = track_mva_line::Parameters::dev_decisions_t::deps;
};
struct Hlt1TwoTrackMVA_Non_Restricted__dev_decisions_t : two_track_mva_line::Parameters::dev_decisions_t {
  using type = two_track_mva_line::Parameters::dev_decisions_t::type;
  using deps = two_track_mva_line::Parameters::dev_decisions_t::deps;
};
struct Hlt1TrackMVA_Restricted__dev_decisions_offsets_t : track_mva_line::Parameters::dev_decisions_offsets_t {
  using type = track_mva_line::Parameters::dev_decisions_offsets_t::type;
  using deps = track_mva_line::Parameters::dev_decisions_offsets_t::deps;
};
struct Hlt1TwoTrackMVA_Restricted__dev_decisions_offsets_t : two_track_mva_line::Parameters::dev_decisions_offsets_t {
  using type = two_track_mva_line::Parameters::dev_decisions_offsets_t::type;
  using deps = two_track_mva_line::Parameters::dev_decisions_offsets_t::deps;
};
struct Hlt1TrackMVA_Non_Restricted__dev_decisions_offsets_t : track_mva_line::Parameters::dev_decisions_offsets_t {
  using type = track_mva_line::Parameters::dev_decisions_offsets_t::type;
  using deps = track_mva_line::Parameters::dev_decisions_offsets_t::deps;
};
struct Hlt1TwoTrackMVA_Non_Restricted__dev_decisions_offsets_t
  : two_track_mva_line::Parameters::dev_decisions_offsets_t {
  using type = two_track_mva_line::Parameters::dev_decisions_offsets_t::type;
  using deps = two_track_mva_line::Parameters::dev_decisions_offsets_t::deps;
};
struct Hlt1TrackMVA_Restricted__host_post_scaler_t : track_mva_line::Parameters::host_post_scaler_t {
  using type = track_mva_line::Parameters::host_post_scaler_t::type;
  using deps = track_mva_line::Parameters::host_post_scaler_t::deps;
};
struct Hlt1TwoTrackMVA_Restricted__host_post_scaler_t : two_track_mva_line::Parameters::host_post_scaler_t {
  using type = two_track_mva_line::Parameters::host_post_scaler_t::type;
  using deps = two_track_mva_line::Parameters::host_post_scaler_t::deps;
};
struct Hlt1TrackMVA_Non_Restricted__host_post_scaler_t : track_mva_line::Parameters::host_post_scaler_t {
  using type = track_mva_line::Parameters::host_post_scaler_t::type;
  using deps = track_mva_line::Parameters::host_post_scaler_t::deps;
};
struct Hlt1TwoTrackMVA_Non_Restricted__host_post_scaler_t : two_track_mva_line::Parameters::host_post_scaler_t {
  using type = two_track_mva_line::Parameters::host_post_scaler_t::type;
  using deps = two_track_mva_line::Parameters::host_post_scaler_t::deps;
};
struct Hlt1TrackMVA_Restricted__host_post_scaler_hash_t : track_mva_line::Parameters::host_post_scaler_hash_t {
  using type = track_mva_line::Parameters::host_post_scaler_hash_t::type;
  using deps = track_mva_line::Parameters::host_post_scaler_hash_t::deps;
};
struct Hlt1TwoTrackMVA_Restricted__host_post_scaler_hash_t : two_track_mva_line::Parameters::host_post_scaler_hash_t {
  using type = two_track_mva_line::Parameters::host_post_scaler_hash_t::type;
  using deps = two_track_mva_line::Parameters::host_post_scaler_hash_t::deps;
};
struct Hlt1TrackMVA_Non_Restricted__host_post_scaler_hash_t : track_mva_line::Parameters::host_post_scaler_hash_t {
  using type = track_mva_line::Parameters::host_post_scaler_hash_t::type;
  using deps = track_mva_line::Parameters::host_post_scaler_hash_t::deps;
};
struct Hlt1TwoTrackMVA_Non_Restricted__host_post_scaler_hash_t
  : two_track_mva_line::Parameters::host_post_scaler_hash_t {
  using type = two_track_mva_line::Parameters::host_post_scaler_hash_t::type;
  using deps = two_track_mva_line::Parameters::host_post_scaler_hash_t::deps;
};

static_assert(
  all_host_or_all_device_v<Hlt1TrackMVA_Restricted__dev_decisions_t, track_mva_line::Parameters::dev_decisions_t>);
static_assert(all_host_or_all_device_v<
              Hlt1TwoTrackMVA_Restricted__dev_decisions_t,
              two_track_mva_line::Parameters::dev_decisions_t>);
static_assert(
  all_host_or_all_device_v<Hlt1TrackMVA_Non_Restricted__dev_decisions_t, track_mva_line::Parameters::dev_decisions_t>);
static_assert(all_host_or_all_device_v<
              Hlt1TwoTrackMVA_Non_Restricted__dev_decisions_t,
              two_track_mva_line::Parameters::dev_decisions_t>);
static_assert(all_host_or_all_device_v<
              Hlt1TrackMVA_Restricted__dev_decisions_offsets_t,
              track_mva_line::Parameters::dev_decisions_offsets_t>);
static_assert(all_host_or_all_device_v<
              Hlt1TwoTrackMVA_Restricted__dev_decisions_offsets_t,
              two_track_mva_line::Parameters::dev_decisions_offsets_t>);
static_assert(all_host_or_all_device_v<
              Hlt1TrackMVA_Non_Restricted__dev_decisions_offsets_t,
              track_mva_line::Parameters::dev_decisions_offsets_t>);
static_assert(all_host_or_all_device_v<
              Hlt1TwoTrackMVA_Non_Restricted__dev_decisions_offsets_t,
              two_track_mva_line::Parameters::dev_decisions_offsets_t>);
static_assert(all_host_or_all_device_v<
              Hlt1TrackMVA_Restricted__host_post_scaler_t,
              track_mva_line::Parameters::host_post_scaler_t>);
static_assert(all_host_or_all_device_v<
              Hlt1TwoTrackMVA_Restricted__host_post_scaler_t,
              two_track_mva_line::Parameters::host_post_scaler_t>);
static_assert(all_host_or_all_device_v<
              Hlt1TrackMVA_Non_Restricted__host_post_scaler_t,
              track_mva_line::Parameters::host_post_scaler_t>);
static_assert(all_host_or_all_device_v<
              Hlt1TwoTrackMVA_Non_Restricted__host_post_scaler_t,
              two_track_mva_line::Parameters::host_post_scaler_t>);
static_assert(all_host_or_all_device_v<
              Hlt1TrackMVA_Restricted__host_post_scaler_hash_t,
              track_mva_line::Parameters::host_post_scaler_hash_t>);
static_assert(all_host_or_all_device_v<
              Hlt1TwoTrackMVA_Restricted__host_post_scaler_hash_t,
              two_track_mva_line::Parameters::host_post_scaler_hash_t>);
static_assert(all_host_or_all_device_v<
              Hlt1TrackMVA_Non_Restricted__host_post_scaler_hash_t,
              track_mva_line::Parameters::host_post_scaler_hash_t>);
static_assert(all_host_or_all_device_v<
              Hlt1TwoTrackMVA_Non_Restricted__host_post_scaler_hash_t,
              two_track_mva_line::Parameters::host_post_scaler_hash_t>);

namespace gather_selections {
  namespace dev_input_selections_t {
    using tuple_t = std::tuple<
      Hlt1TrackMVA_Restricted__dev_decisions_t,
      Hlt1TwoTrackMVA_Restricted__dev_decisions_t,
      Hlt1TrackMVA_Non_Restricted__dev_decisions_t,
      Hlt1TwoTrackMVA_Non_Restricted__dev_decisions_t>;
  }
} // namespace gather_selections
namespace gather_selections {
  namespace dev_input_selections_offsets_t {
    using tuple_t = std::tuple<
      Hlt1TrackMVA_Restricted__dev_decisions_offsets_t,
      Hlt1TwoTrackMVA_Restricted__dev_decisions_offsets_t,
      Hlt1TrackMVA_Non_Restricted__dev_decisions_offsets_t,
      Hlt1TwoTrackMVA_Non_Restricted__dev_decisions_offsets_t>;
  }
} // namespace gather_selections
namespace gather_selections {
  namespace host_input_post_scale_factors_t {
    using tuple_t = std::tuple<
      Hlt1TrackMVA_Restricted__host_post_scaler_t,
      Hlt1TwoTrackMVA_Restricted__host_post_scaler_t,
      Hlt1TrackMVA_Non_Restricted__host_post_scaler_t,
      Hlt1TwoTrackMVA_Non_Restricted__host_post_scaler_t>;
  }
} // namespace gather_selections
namespace gather_selections {
  namespace host_input_post_scale_hashes_t {
    using tuple_t = std::tuple<
      Hlt1TrackMVA_Restricted__host_post_scaler_hash_t,
      Hlt1TwoTrackMVA_Restricted__host_post_scaler_hash_t,
      Hlt1TrackMVA_Non_Restricted__host_post_scaler_hash_t,
      Hlt1TwoTrackMVA_Non_Restricted__host_post_scaler_hash_t>;
  }
} // namespace gather_selections
