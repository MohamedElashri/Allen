/***************************************************************************** \
 * (c) Copyright 2000-2023 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/

// Gaudi
#include "GaudiAlg/Transformer.h"
#include "GaudiKernel/StdArrayAsProperty.h"

// LHCb
#include "Event/Track.h"
#include "Event/Track_v3.h"
#include "Event/TrackEnums.h"
#include "Event/UniqueIDGenerator.h"
#include "Event/StateParameters.h"

// Allen
#include "Logger.h"
#include "VeloConsolidated.cuh"
#include "UTConsolidated.cuh"
#include "SciFiConsolidated.cuh"
#include "ParKalmanFittedTrack.cuh"
#include "States.cuh"
#include "ParticleTypes.cuh"

#include <AIDA/IHistogram1D.h>
#include <algorithm>
#include <type_traits>
#include <functional>

/**
 * Convert Allen::Views::.*::Consolidated::Tracks into LHCb::Event::v3::Tracks
 */

namespace { // Anonymous namespace for local implemenations
  using OutTracks = LHCb::Event::v3::Tracks;
  using OutTrackType = LHCb::Event::v3::TrackType;
  namespace OutTag = LHCb::Event::v3::Tag;
} // namespace

namespace GaudiAllen::Converters::v3 {
  /**
   * Type-traits associating Allen Consolidated::Track types to the
   * LHCb::Event::v3::Tag LHCbID fields for the subdector whose hits they
   * contain/reference.
   */
  template<typename>
  struct v3_hit_container {
  };

  template<>
  struct v3_hit_container<Allen::Views::Velo::Consolidated::Track> {
    using type = OutTag::VPHits;
    static inline bool check_id(const LHCb::LHCbID& id) { return id.isVP(); }
  };

  template<>
  struct v3_hit_container<Allen::Views::UT::Consolidated::Track> {
    using type = OutTag::UTHits;
    static inline bool check_id(const LHCb::LHCbID& id) { return id.isUT(); }
  };

  template<>
  struct v3_hit_container<Allen::Views::SciFi::Consolidated::Track> {
    using type = OutTag::FTHits;
    static inline bool check_id(const LHCb::LHCbID& id) { return id.isFT(); }
  };

  template<typename AllenTrack>
  using v3_hit_container_t = typename v3_hit_container<AllenTrack>::type;

  /**
   * Allen-specific equivalent of LHCb::Event::conversion::update_lhcb_ids
   * Copies LHCbIDs for an Allen track or track segment.
   * Can probably be easily improved if the hits for a track can be accessed
   * as a range.
   */
  template<typename TrackProxy, typename AllenTrack>
  void update_seg_lhcb_ids(TrackProxy& outTrack, const AllenTrack& track)
  {
    const unsigned n_hits = track.number_of_ids();
    outTrack.template field<v3_hit_container_t<AllenTrack>>().resize(n_hits);
    for (unsigned i = 0; i < n_hits; ++i) {
      const auto id = track.id(i);
      const LHCb::LHCbID lhcbid {id};
      assert(v3_hit_container<AllenTrack>::check_id(lhcbid));
      outTrack.template field<v3_hit_container_t<AllenTrack>>()[i].template field<OutTag::LHCbID>().set(lhcbid);
    }
  }

  /**
   * Adapter for the heterogenous track/particle types.
   */
  template<typename TrackProxy, typename AllenTrack>
  void update_lhcb_ids(TrackProxy& outTrack, const AllenTrack& track)
  {
    if constexpr (std::is_same_v<AllenTrack, Allen::Views::Physics::BasicParticle>) {
      /// fan-out track segments
      using Track = Allen::Views::Physics::Track;
      using segment = Track::segment;

      auto actual_track = static_cast<const Track&>(track.track());
      if (actual_track.has<segment::velo>()) update_seg_lhcb_ids(outTrack, actual_track.track_segment<segment::velo>());
      if (actual_track.has<segment::ut>()) update_seg_lhcb_ids(outTrack, actual_track.track_segment<segment::ut>());
      if (actual_track.has<segment::scifi>())
        update_seg_lhcb_ids(outTrack, actual_track.track_segment<segment::scifi>());
    }
    else if constexpr (std::is_same_v<AllenTrack, Allen::Views::UT::Consolidated::Track>) {
      /// include Velo segment referenced by UT Track
      update_seg_lhcb_ids(outTrack, track);
      update_seg_lhcb_ids(outTrack, track.velo_track());
    }
    else {
      update_seg_lhcb_ids(outTrack, track);
    }
  }

  /**
   * Association from Allen Consolidated::Track types to its corresponding
   * LHCb::Event::Enum::Track::History.
   */
  template<typename>
  struct v3_history {
  };

  template<>
  struct v3_history<Allen::Views::Velo::Consolidated::Track> {
    static constexpr auto value = LHCb::Event::Enum::Track::History::PrPixel;
  };

  template<>
  struct v3_history<Allen::Views::UT::Consolidated::Track> {
    static constexpr auto value = LHCb::Event::Enum::Track::History::PrVeloUT;
  };

  template<>
  struct v3_history<Allen::Views::Physics::BasicParticle> {
    static constexpr auto value = LHCb::Event::Enum::Track::History::PrForward;
  };

  template<typename AllenTrack>
  constexpr auto v3_history_v = v3_history<AllenTrack>::value;

  namespace {
    /**
     * Augmented version of KalmanVeloState from States.cuh
     * Appends qop and its variance to the state to make the adaptation
     *   to LHCb track states easier.
     */
    struct KalmanVeloStateWithQoP : public KalmanVeloState {
      float qop, c44;

      KalmanVeloStateWithQoP() = default;
      KalmanVeloStateWithQoP(const KalmanVeloStateWithQoP&) = default;
      KalmanVeloStateWithQoP& operator=(const KalmanVeloStateWithQoP&) = default;

      KalmanVeloStateWithQoP(const KalmanVeloState _s, const float _qop, const float _c44) : KalmanVeloState(_s)
      {
        qop = _qop;
        c44 = _c44;
      }

      KalmanVeloStateWithQoP(
        const float _x,
        const float _y,
        const float _z,
        const float _tx,
        const float _ty,
        const float _c00,
        const float _c20,
        const float _c22,
        const float _c11,
        const float _c31,
        const float _c33,
        const float _qop,
        const float _c44) :
        KalmanVeloState(_x, _y, _z, _tx, _ty, _c00, _c20, _c22, _c11, _c31, _c33)
      {
        qop = _qop;
        c44 = _c44;
      }
    };

    /**
     * Adaptation of z position accessors for heterogenous hit types
     */
    template<typename HitType>
    float get_hit_z(const HitType h)
    {
      if constexpr (std::is_same_v<HitType, Allen::Views::UT::Consolidated::Hit>) {
        return h.zAtYEq0();
      }
      else if constexpr (std::is_same_v<HitType, Allen::Views::SciFi::Consolidated::Hit>) {
        return h.z0();
      }
      else {
        return h.z();
      }
    }

    /**
     * Helpers to find the "first measurement" hit and "last measurement" hit
     * on an Allen track.  This implementation assumes that
     *   - The hits of the Allen consolidated tracks are sorted, and that
     *   - The last hit in the container corresponds to the first measurement
     */
    /// generic
    /// SciFi tracks (T-tracks) have differently named accessor method
    /// will require another specialization if needed for SciFi Tracks
    template<typename AllenTrack>
    auto first_hit(const AllenTrack& track)
    {
      return track.hit(track.number_of_ids() - 1);
    }

    /// for UT track, descend to Velo track
    template<>
    auto first_hit<Allen::Views::UT::Consolidated::Track>(const Allen::Views::UT::Consolidated::Track& track)
    {
      return first_hit(track.velo_track());
    }

    /// for Physics track, descend to its Velo track
    template<>
    auto first_hit<Allen::Views::Physics::Track>(const Allen::Views::Physics::Track& track)
    {
      using Track = Allen::Views::Physics::Track;
      using segment = Track::segment;
      auto tref = static_cast<const Track&>(track);
      return first_hit(tref.track_segment<segment::velo>());
    }

    /// for BasicParticle, use its Physics track
    template<>
    auto first_hit<Allen::Views::Physics::BasicParticle>(const Allen::Views::Physics::BasicParticle& track)
    {
      return first_hit(track.track());
    }

    /// generic
    template<typename AllenTrack>
    auto last_hit(const AllenTrack& track)
    {
      return track.hit(0);
    }

    /// for Physics track, descend to its SciFi track
    template<>
    auto last_hit<Allen::Views::Physics::Track>(const Allen::Views::Physics::Track& track)
    {
      using Track = Allen::Views::Physics::Track;
      using segment = Track::segment;
      auto tref = static_cast<const Track&>(track);
      return last_hit(tref.track_segment<segment::scifi>());
    }

    /// for BasicParticle, use its Physics track
    template<>
    auto last_hit<Allen::Views::Physics::BasicParticle>(const Allen::Views::Physics::BasicParticle& track)
    {
      return last_hit(track.track());
    }

    /**
     * Calculate z-position of states for the various states expected by
     *   v3::Tracks.
     * Depends on one of the following:
     *   - An external detector constant in Event/StateParameters.h,
     *   - The z-position of the beamline state, or
     *   - The z-position of a hit on the track.
     */
    template<OutTracks::StateLocation L, typename AllenTrack, typename AllenState>
    float z_of(const AllenTrack track, const AllenState state)
    {
      using SL = OutTracks::StateLocation;
      /// states at constant positions
      if constexpr (L == SL::BegRich1) {
        return StateParameters::ZBegRich1;
      }
      else if constexpr (L == SL::EndRich1) {
        return StateParameters::ZEndRich1;
      }
      else if constexpr (L == SL::BegRich2) {
        return StateParameters::ZBegRich2;
      }
      else if constexpr (L == SL::EndRich2) {
        return StateParameters::ZEndRich2;
      }
      /// position of beamline state can only be determined from input
      else if constexpr (L == SL::ClosestToBeam) {
        return state.z;
      }
      /// position of hits on the track
      else if constexpr (L == SL::FirstMeasurement) {
        return get_hit_z(first_hit(track));
      }
      else if constexpr (L == SL::LastMeasurement) {
        return get_hit_z(last_hit(track));
      }
    }

  } // namespace

  /**
   * Allen-specific equivalent of LHCb::Event::conversion::update_velo_state
   * Copies a state into the specified location of the new track.
   */
  template<OutTracks::StateLocation L, typename TrackProxy>
  bool update_velo_state(TrackProxy& outTrack, const KalmanVeloStateWithQoP& state)
  {
    outTrack.template field<OutTag::States>()[outTrack.state_index(L)].setPosition(state.x, state.y, state.z);
    outTrack.template field<OutTag::States>()[outTrack.state_index(L)].setDirection(state.tx, state.ty);
    outTrack.template field<OutTag::States>()[outTrack.state_index(L)].setQOverP(state.qop);

    // Transfer state vector covariance
    // ToDo:  Find the right meta-incantation to set individual elements.
    outTrack.template field<OutTag::StateCovs>()[outTrack.state_index(L)].setXCovariance(
      state.c00, 0.f, state.c20, 0.f, 0.f);
    outTrack.template field<OutTag::StateCovs>()[outTrack.state_index(L)].setYCovariance(
      state.c11, 0.f, state.c31, 0.f);
    outTrack.template field<OutTag::StateCovs>()[outTrack.state_index(L)].setTXCovariance(state.c22, 0.f, 0.f);
    outTrack.template field<OutTag::StateCovs>()[outTrack.state_index(L)].setTYCovariance(state.c33, 0.f);
    outTrack.template field<OutTag::StateCovs>()[outTrack.state_index(L)].setQoverPCovariance(state.c44);

    return true;
  }

  namespace {
    /**
     * Linear state extrapolation of a KalmanVeloState.
     * Duplicated from the end of velo_kalman_filter::simplified_fit()
     */
    KalmanVeloStateWithQoP extrap_state(const KalmanVeloStateWithQoP instate, const float z)
    {
      KalmanVeloStateWithQoP state(instate);

      const float delta_z = z - state.z;

      // Propagate the state
      state.x = state.x + state.tx * delta_z;
      state.y = state.y + state.ty * delta_z;
      state.z = state.z + delta_z;

      // Propagate the covariance matrix
      const auto dz2 = delta_z * delta_z;
      state.c00 += dz2 * state.c22 + 2.f * delta_z * state.c20;
      state.c11 += dz2 * state.c33 + 2.f * delta_z * state.c31;
      state.c20 += state.c22 * delta_z;
      state.c31 += state.c33 * delta_z;

      // finally, store the state
      return state;
    }

    KalmanVeloStateWithQoP closest_state(std::vector<KalmanVeloStateWithQoP> states, const float z)
    {
      return *std::min_element(states.begin(), states.end(), [&](auto s1, auto s2) {
        return std::abs(s1.z - z) < std::abs(s2.z - z) ? true : false;
      });
    }

    KalmanVeloStateWithQoP extrap_from_closest_state(std::vector<KalmanVeloStateWithQoP> states, const float z)
    {
      return extrap_state(closest_state(states, z), z);
    }

    /// Actual implementation of update states
    /// Assumes that the beamline state is the first element of the states vector
    template<typename TrackProxy, typename AllenTrack, OutTracks::StateLocation... L>
    static bool update_states_impl(
      TrackProxy& outTrack,
      const AllenTrack& track,
      std::vector<KalmanVeloStateWithQoP> states,
      LHCb::Event::v3::state_collection<L...>)
    {
      return (update_velo_state<L>(outTrack, extrap_from_closest_state(states, z_of<L>(track, states[0]))) && ...);
    }
  } // namespace

  /**
   * Allen-specific equivalent of LHCb::Event::conversion::update_states.
   * Determine states to update based on TrackProxy type.
   * Only a subset of the LHCb::Event::v3::TrackType currently implemented.
   */
  template<typename TrackProxy, typename AllenTrack>
  static bool update_states(TrackProxy& outTrack, const AllenTrack& track, std::vector<KalmanVeloStateWithQoP> states)
  {

    switch (outTrack.type()) {
    case OutTrackType::Velo:
      return update_states_impl(outTrack, track, states, LHCb::Event::v3::available_states_t<OutTrackType::Velo> {});
    case OutTrackType::VeloBackward:
      return update_states_impl(
        outTrack, track, states, LHCb::Event::v3::available_states_t<OutTrackType::VeloBackward> {});
    case OutTrackType::Upstream:
      return update_states_impl(
        outTrack, track, states, LHCb::Event::v3::available_states_t<OutTrackType::Upstream> {});
    case OutTrackType::Long:
      return update_states_impl(outTrack, track, states, LHCb::Event::v3::available_states_t<OutTrackType::Long> {});
    case OutTrackType::FittedForward:
      return update_states_impl(
        outTrack, track, states, LHCb::Event::v3::available_states_t<OutTrackType::FittedForward> {});
    default: throw GaudiException("unknown v3 track type", "GaudiAllenTrackViewsToV3Tracks", StatusCode::FAILURE);
    }
  }

  /**
   * Allen-specific equivalent of LHCb::Event::conversion::convert_track.
   * States are not generally directly accessible from Allen tracks.
   * They must be provided as separate input.
   * Only a subset of the LHCb::Event::v3::TrackType currently implemented.
   */
  template<typename TrackProxy, typename AllenTrack>
  void convert_track(
    TrackProxy& newTrack,
    const AllenTrack& track,
    std::vector<KalmanVeloStateWithQoP> states,
    const LHCb::UniqueIDGenerator& unique_id_gen)
  {
    // add hits
    update_lhcb_ids(newTrack, track);

    // track history
    newTrack.template field<OutTag::history>().set(v3_history_v<AllenTrack>);

    // identifier
    using int_v = decltype(newTrack.template field<OutTag::UniqueID>().get());
    newTrack.template field<OutTag::UniqueID>().set(unique_id_gen.generate<int_v>().value());

    // set chi2 and ndof if available
    if constexpr (std::is_same_v<AllenTrack, Allen::Views::Physics::BasicParticle>) {
      newTrack.template field<OutTag::Chi2>().set(track.chi2());
      newTrack.template field<OutTag::nDoF>().set(static_cast<int>(track.ndof()));
    }
    else {
      newTrack.template field<OutTag::Chi2>().set(0.);
      newTrack.template field<OutTag::nDoF>().set(0);
    }

    // convert states
    update_states(newTrack, track, states);
  }

  namespace {
    /**
     * Find the Velo track segment associated with sundry input types.
     * Needed to access corresponding members of
     * Allen::Views::Physics::KalmanStates containers.
     */
    template<typename AllenTrack>
    auto get_velo_track(const AllenTrack track)
    {
      if constexpr (std::is_same_v<AllenTrack, Allen::Views::Velo::Consolidated::Track>) {
        return track;
      }
      else if constexpr (std::is_same_v<AllenTrack, Allen::Views::UT::Consolidated::Track>) {
        return track.velo_track();
      }
      else if constexpr (std::is_same_v<AllenTrack, Allen::Views::Physics::Track>) {
        using Track = Allen::Views::Physics::Track;
        using segment = Track::segment;
        auto tref = static_cast<const Track&>(track);
        return tref.track_segment<segment::velo>();
      }
      else if constexpr (std::is_same_v<AllenTrack, Allen::Views::Physics::BasicParticle>) {
        return get_velo_track(track.track());
      }
    }

    /**
     * Adaptor for heterogenous View member accessors (track or particle members)
     */
    template<typename ContainerView>
    auto get_member(const ContainerView& c, const unsigned i)
    {
      if constexpr (std::is_same_v<ContainerView, Allen::Views::Physics::BasicParticles>) {
        return c.particle(i);
      }
      else {
        return c.track(i);
      }
    }
  } // namespace

  /**
   * Association from Allen Consolidated::Track types to its corresponding
   * OutTrackType.  Will need revision/reconsideration for Velo bifurcation.
   */
  template<typename>
  struct v3_track_type {
  };

  template<>
  struct v3_track_type<Allen::Views::Velo::Consolidated::MultiEventTracks> {
    static constexpr auto value = OutTrackType::Velo;
    static constexpr auto value_fwd = OutTrackType::Velo;
    static constexpr auto value_bwd = OutTrackType::VeloBackward;
  };

  template<>
  struct v3_track_type<Allen::Views::UT::Consolidated::MultiEventTracks> {
    static constexpr auto value = OutTrackType::Upstream;
  };

  template<>
  struct v3_track_type<Allen::Views::Physics::MultiEventBasicParticles> {
    static constexpr auto value = OutTrackType::FittedForward;
  };

  template<typename AllenTrack>
  constexpr auto v3_track_type_v = v3_track_type<AllenTrack>::value;

  namespace {
    /**
     * Types to differentiate among containers of states and to associate
     * input key names to different types of states.
     */
    struct beamline_states {
      using type = Allen::Views::Physics::KalmanStates;
      static constexpr auto keyname = "allen_beamline_states_view";
    };

    struct endvelo_states {
      using type = Allen::Views::Physics::KalmanStates;
      static constexpr auto keyname = "allen_endvelo_states_view";
    };

    template<typename T>
    struct in_type {
      using type = T;
    };

    template<>
    struct in_type<beamline_states> {
      using type = beamline_states::type;
    };

    template<>
    struct in_type<endvelo_states> {
      using type = endvelo_states::type;
    };

    template<typename T>
    using in_type_t = typename in_type<T>::type;

    /**
     * Key names for input containers
     */
    template<typename AllenInput>
    auto get_input_name()
    {
      if constexpr (std::is_same_v<AllenInput, beamline_states> || std::is_same_v<AllenInput, endvelo_states>) {
        return AllenInput::keyname;
      }
      else {
        return "allen_tracks_mec";
      }
    }

    template<typename KeyValue, typename... AllenInput>
    auto get_input_names()
    {
      return std::make_tuple(
        (KeyValue {get_input_name<AllenInput>(), ""})...,
        KeyValue {"InputUniqueIDGenerator", LHCb::UniqueIDGeneratorLocation::Default});
    }

    /// Determines whether a parameter pack contains Velo input tracks type
    template<typename... InTypes>
    constexpr bool is_velo_input()
    {
      return (std::is_same_v<InTypes, Allen::Views::Velo::Consolidated::MultiEventTracks> || ...);
    };

    /**
     * One or two output containers dependent on wheter input is Velo
     */
    template<bool>
    struct switched_out_type {
    };

    template<>
    struct switched_out_type<false> {
      using type = std::tuple<OutTracks>;
    };

    template<>
    struct switched_out_type<true> {
      using type = std::tuple<OutTracks, OutTracks>;
    };

    template<typename... InTypes>
    using out_type_t = typename switched_out_type<is_velo_input<InTypes...>()>::type;

    /**
     * Key names for output containers
     */
    template<typename KeyValue, typename LHCbOutput>
    auto get_output_names()
    {
      if constexpr (std::is_same_v<LHCbOutput, switched_out_type<true>::type>) {
        return std::make_tuple(KeyValue {"OutputTracksForward", ""}, KeyValue {"OutputTracksBackward", ""});
      }
      else if constexpr (std::is_same_v<LHCbOutput, switched_out_type<false>::type>) {
        return std::make_tuple(KeyValue {"OutputTracks", ""});
      }
    }
  } // namespace

  /**
   * The first template parameter is assumed to be a view of track types.
   * If present, all other parameters are assumed to be views of states.
   *
   * Number of output containers is deduced from input type
   * - Two track containers for Velo input (forward and backward)
   * - One track container for all other types of input
   */
  template<typename AllenTracks, typename... AllenStates>
  class GaudiAllenTrackViewsToV3Tracks final : public Gaudi::Functional::MultiTransformer<out_type_t<AllenTracks>(
                                                 std::vector<AllenTracks> const&,
                                                 std::vector<in_type_t<AllenStates>> const&...,
                                                 const LHCb::UniqueIDGenerator&)> {

  public:
    using OutType = out_type_t<AllenTracks>;
    using base_class = Gaudi::Functional::MultiTransformer<OutType(
      std::vector<AllenTracks> const&,
      std::vector<in_type_t<AllenStates>> const&...,
      const LHCb::UniqueIDGenerator&)>;
    using KeyValue = typename base_class::KeyValue;

    /// Standard constructor
    GaudiAllenTrackViewsToV3Tracks(const std::string& name, ISvcLocator* pSvcLocator) :
      base_class(
        name,
        pSvcLocator,
        // Inputs
        get_input_names<KeyValue, AllenTracks, AllenStates...>(),
        // Outputs
        get_output_names<KeyValue, OutType>())
    {}

    /// Algorithm execution
    OutType operator()(
      std::vector<AllenTracks> const& allen_tracks_mec,
      std::vector<in_type_t<AllenStates>> const&... allen_states_containers,
      const LHCb::UniqueIDGenerator& unique_id_gen) const override
    {
      const unsigned i_event = 0;
      const auto allen_tracks_view = allen_tracks_mec[0].container(i_event);
      const auto number_of_tracks = allen_tracks_view.size();

      // Construct the output container
      auto output = make_output_container<std::decay_t<decltype(allen_tracks_mec[0])>>(unique_id_gen);
      for (unsigned int t = 0; t < number_of_tracks; t++) {
        const auto track = get_member(allen_tracks_view, t);
        auto states = get_input_states(track, allen_states_containers...);
        const bool backward = states[0].z > get_hit_z(last_hit(track));

        auto newTrack = get_new_out_track(output, backward);
        convert_track(newTrack, track, states, unique_id_gen);
      }

      assert(get_output_size(output) == number_of_tracks);
      return output;
    }

  private:
    Gaudi::Property<float> m_qopvar_rel {this, "relQoPVar", 0.1, "Default relative qop variance (qopVar/(qop*qop))"};
    Gaudi::Property<float> m_ptVelo {this, "ptVelo", 400 * Gaudi::Units::MeV, "Default pT for Velo tracks"};

    template<typename AllenTrack>
    OutType make_output_container(const LHCb::UniqueIDGenerator& unique_id_gen) const
    {
      auto zn = Zipping::generateZipIdentifier();
      if constexpr (std::tuple_size_v<OutType> == 2) {
        return {OutTracks(v3_track_type<AllenTrack>::value_fwd, unique_id_gen, zn),
                OutTracks(v3_track_type<AllenTrack>::value_bwd, true, unique_id_gen, zn)};
      }
      else {
        return {OutTracks(v3_track_type_v<AllenTrack>, unique_id_gen, zn)};
      }
    }

    auto get_new_out_track(OutType& output, bool backward = false) const
    {
      if constexpr (std::tuple_size_v<OutType> == 2) {
        auto& [outfwd, outbwd] = output;
        if (backward)
          return outbwd.template emplace_back<SIMDWrapper::InstructionSet::Scalar>();
        else
          return outfwd.template emplace_back<SIMDWrapper::InstructionSet::Scalar>();
      }
      else {
        auto& [outtrk] = output;
        return outtrk.template emplace_back<SIMDWrapper::InstructionSet::Scalar>();
      }
    }

    auto get_output_size(OutType& output) const
    {
      if constexpr (std::tuple_size_v<OutType> == 2) {
        auto& [outfwd, outbwd] = output;
        return outfwd.size() + outbwd.size();
      }
      else {
        auto& [outtrk] = output;
        return outtrk.size();
      }
    }

    template<typename AllenTrack, typename... States>
    std::pair<float, float> qop_and_var(const AllenTrack& track, const States&... input_states) const
    {
      float qop = 0.f;
      if constexpr (std::is_same_v<AllenTrack, Allen::Views::UT::Consolidated::Track>) {
        // if qop is a track member
        qop = track.qop();
      }
      else if constexpr (std::is_same_v<AllenTrack, Allen::Views::Physics::BasicParticle>) {
        // if there is a state member of the track with a defined qop
        qop = track.state().qop();
      }
      else if constexpr (sizeof...(input_states) > 0) {
        // if there is at least one independent state container, use default pT
        auto all_states = std::forward_as_tuple(input_states...);
        auto beamline_states = std::get<0>(all_states);
        auto velo_track = get_velo_track(track);
        auto beamline_state = velo_track.state(beamline_states[0]);

        // set charge based on hit 0 of the velo track
        //   (part of original implementation of GaudiAllenVeloToV2Tracks)
        const int firstRow = LHCb::LHCbID(velo_track.id(0)).channelID();
        const float charge = (firstRow % 2 == 0 ? -1.f : 1.f);

        const float tx1 = beamline_state.tx;
        const float ty1 = beamline_state.ty;
        const float slope2 = std::max(tx1 * tx1 + ty1 * ty1, 1.e-20f);
        qop = charge / (m_ptVelo * std::sqrt(1.f + 1.f / slope2));
      }
      float qopVar = m_qopvar_rel * qop * qop;
      return {qop, qopVar};
    }

    template<typename AllenTrack, typename... States>
    std::vector<KalmanVeloStateWithQoP> get_input_states(const AllenTrack& track, const States&... input_states) const
    {
      std::vector<KalmanVeloStateWithQoP> out;
      const auto qop_w_var = qop_and_var(track, input_states...);
      const float qop = qop_w_var.first;
      const float qopVar = qop_w_var.second;

      // if a state is part of the AllenTrack, then add it.
      if constexpr (std::is_same_v<AllenTrack, Allen::Views::Physics::BasicParticle>) {
        auto velo_beamline_state = static_cast<KalmanVeloState>(track.state());
        out.push_back({velo_beamline_state, qop, qopVar});
      }

      // add states provided in independent input containers
      if constexpr (sizeof...(input_states) > 0) {
        auto velo_track = get_velo_track(track);
        std::vector<KalmanVeloStateWithQoP> ins {{velo_track.state(input_states[0]), qop, qopVar}...};
        out.insert(out.end(), ins.begin(), ins.end());
      }
      return out;
    }
  };

  using GaudiAllenMEBasicParticlesToV3Tracks =
    GaudiAllenTrackViewsToV3Tracks<Allen::Views::Physics::MultiEventBasicParticles>;
  DECLARE_COMPONENT_WITH_ID(GaudiAllenMEBasicParticlesToV3Tracks, "GaudiAllenMEBasicParticlesToV3Tracks")

  using GaudiAllenVeloToV3Tracks =
    GaudiAllenTrackViewsToV3Tracks<Allen::Views::Velo::Consolidated::MultiEventTracks, beamline_states>;
  DECLARE_COMPONENT_WITH_ID(GaudiAllenVeloToV3Tracks, "GaudiAllenVeloToV3Tracks")

  using GaudiAllenUTToV3Tracks =
    GaudiAllenTrackViewsToV3Tracks<Allen::Views::UT::Consolidated::MultiEventTracks, beamline_states, endvelo_states>;
  DECLARE_COMPONENT_WITH_ID(GaudiAllenUTToV3Tracks, "GaudiAllenUTToV3Tracks")
} // namespace GaudiAllen::Converters::v3
