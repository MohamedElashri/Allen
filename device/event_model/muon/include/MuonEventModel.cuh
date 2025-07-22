/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "BackendCommon.h"
#include "MuonTileID.cuh"
#include <ostream>
#include <iomanip>
#include <limits>

namespace Muon {
  /**
   * @brief Structure to access Muon hits.
   * @detail SOA to:
   *
   * float x
   * float dx
   * float y
   * float dy
   * float z
   * float dz
   * unsigned int time
   * int tile
   * int uncrossed
   * int delta_time
   * int cluster_size
   * int region_id
   */
  template<typename T>
  struct Hits_t {
  protected:
    typename ForwardType<T, float>::t* m_base_pointer;
    const unsigned m_total_number_of_hits;
    const unsigned m_offset;

  public:
    constexpr static unsigned element_size = 5 * sizeof(float) + 4 * sizeof(int) + sizeof(unsigned);

    __host__ __device__
    Hits_t(T* base_pointer, const unsigned total_estimated_number_of_clusters, const unsigned offset = 0) :
      m_base_pointer(reinterpret_cast<typename ForwardType<T, float>::t*>(base_pointer)),
      m_total_number_of_hits(total_estimated_number_of_clusters), m_offset(offset)
    {}

    __host__ __device__ Hits_t(const Hits_t<T>& clusters) :
      m_base_pointer(clusters.m_base_pointer), m_total_number_of_hits(clusters.m_total_number_of_hits),
      m_offset(clusters.m_offset)
    {}

    // Accessors and lvalue references for all types
    __host__ __device__ float x(const unsigned index) const
    {
      assert(m_offset + index < m_total_number_of_hits);
      return m_base_pointer[m_offset + index];
    }

    __host__ __device__ float& x(const unsigned index)
    {
      assert(m_offset + index < m_total_number_of_hits);
      return m_base_pointer[m_offset + index];
    }

    __host__ __device__ float dx(const unsigned index) const
    {
      assert(m_offset + index < m_total_number_of_hits);
      return m_base_pointer[m_total_number_of_hits + m_offset + index];
    }

    __host__ __device__ float& dx(const unsigned index)
    {
      assert(m_offset + index < m_total_number_of_hits);
      return m_base_pointer[m_total_number_of_hits + m_offset + index];
    }

    __host__ __device__ float y(const unsigned index) const
    {
      assert(m_offset + index < m_total_number_of_hits);
      return m_base_pointer[2 * m_total_number_of_hits + m_offset + index];
    }

    __host__ __device__ float& y(const unsigned index)
    {
      assert(m_offset + index < m_total_number_of_hits);
      return m_base_pointer[2 * m_total_number_of_hits + m_offset + index];
    }

    __host__ __device__ float dy(const unsigned index) const
    {
      assert(m_offset + index < m_total_number_of_hits);
      return m_base_pointer[3 * m_total_number_of_hits + m_offset + index];
    }

    __host__ __device__ float& dy(const unsigned index)
    {
      assert(m_offset + index < m_total_number_of_hits);
      return m_base_pointer[3 * m_total_number_of_hits + m_offset + index];
    }

    __host__ __device__ float z(const unsigned index) const
    {
      assert(m_offset + index < m_total_number_of_hits);
      return m_base_pointer[4 * m_total_number_of_hits + m_offset + index];
    }

    __host__ __device__ float& z(const unsigned index)
    {
      assert(m_offset + index < m_total_number_of_hits);
      return m_base_pointer[4 * m_total_number_of_hits + m_offset + index];
    }

    __host__ __device__ unsigned time(const unsigned index) const
    {
      assert(m_offset + index < m_total_number_of_hits);
      return reinterpret_cast<typename ForwardType<T, unsigned>::t*>(
        m_base_pointer)[5 * m_total_number_of_hits + m_offset + index];
    }

    __host__ __device__ unsigned& time(const unsigned index)
    {
      assert(m_offset + index < m_total_number_of_hits);
      return reinterpret_cast<typename ForwardType<T, unsigned>::t*>(
        m_base_pointer)[5 * m_total_number_of_hits + m_offset + index];
    }

    __host__ __device__ int tile(const unsigned index) const
    {
      assert(m_offset + index < m_total_number_of_hits);
      return reinterpret_cast<typename ForwardType<T, unsigned>::t*>(
        m_base_pointer)[6 * m_total_number_of_hits + m_offset + index];
    }

    __host__ __device__ int& tile(const unsigned index)
    {
      assert(m_offset + index < m_total_number_of_hits);
      return reinterpret_cast<typename ForwardType<T, int>::t*>(
        m_base_pointer)[6 * m_total_number_of_hits + m_offset + index];
    }

    __host__ __device__ int uncrossed(const unsigned index) const
    {
      assert(m_offset + index < m_total_number_of_hits);
      return reinterpret_cast<typename ForwardType<T, int>::t*>(
        m_base_pointer)[7 * m_total_number_of_hits + m_offset + index];
    }

    __host__ __device__ int& uncrossed(const unsigned index)
    {
      assert(m_offset + index < m_total_number_of_hits);
      return reinterpret_cast<typename ForwardType<T, int>::t*>(
        m_base_pointer)[7 * m_total_number_of_hits + m_offset + index];
    }

    __host__ __device__ int delta_time(const unsigned index) const
    {
      assert(m_offset + index < m_total_number_of_hits);
      return reinterpret_cast<typename ForwardType<T, int>::t*>(
        m_base_pointer)[8 * m_total_number_of_hits + m_offset + index];
    }

    __host__ __device__ int& delta_time(const unsigned index)
    {
      assert(m_offset + index < m_total_number_of_hits);
      return reinterpret_cast<typename ForwardType<T, int>::t*>(
        m_base_pointer)[8 * m_total_number_of_hits + m_offset + index];
    }

    __host__ __device__ int region(const unsigned index) const
    {
      assert(m_offset + index < m_total_number_of_hits);
      return reinterpret_cast<typename ForwardType<T, int>::t*>(
        m_base_pointer)[9 * m_total_number_of_hits + m_offset + index];
    }

    __host__ __device__ int& region(const unsigned index)
    {
      assert(m_offset + index < m_total_number_of_hits);
      return reinterpret_cast<typename ForwardType<T, int>::t*>(
        m_base_pointer)[9 * m_total_number_of_hits + m_offset + index];
    }
  };

  typedef const Hits_t<const char> ConstHits;
  typedef Hits_t<char> Hits;

  struct Hit {
    float x = 0.f;
    float dx = 0.f;
    float y = 0.f;
    float dy = 0.f;
    float z = 0.f;
    unsigned int time = std::numeric_limits<unsigned>::max();
    int tile = std::numeric_limits<int>::max();
    int uncrossed = -1;
    int delta_time = std::numeric_limits<int>::max();
    int region = -1;

    __device__ Hit(
      const float _x,
      const float _dx,
      const float _y,
      const float _dy,
      const float _z,
      const unsigned int _time,
      const int _tile,
      const int _uncrossed,
      const int _delta_time,
      const int _region) :
      x(_x),
      dx(_dx), y(_y), dy(_dy), z(_z), time(_time), tile(_tile), uncrossed(_uncrossed), delta_time(_delta_time),
      region(_region)
    {}

    friend std::ostream& operator<<(std::ostream& stream, const Hit& muon_hit)
    {
      constexpr int prec = 6, wide = 12, narrow = 4;
      stream << std::setprecision(prec) << " Muon hit" << std::setw(narrow) << Muon::MuonTileID::station(muon_hit.tile)
             << std::setw(narrow) << muon_hit.region << std::setw(wide) << muon_hit.tile << std::setw(wide)
             << muon_hit.x << std::setw(wide) << muon_hit.y << std::setw(wide) << muon_hit.z << std::setw(wide)
             << muon_hit.dx << std::setw(wide) << muon_hit.dy << std::setw(narrow) << muon_hit.uncrossed
             << std::setw(narrow) << muon_hit.time << std::setw(narrow) << muon_hit.delta_time;
      return stream;
    }
  };
} // namespace Muon

struct MuonTrack {
  int m_hits[4] {-1, -1, -1, -1};
  uint8_t m_number_of_hits = 0;
  float m_tx;
  float m_ty;
  float m_ax;
  float m_ay;
  float m_chi2x;
  float m_chi2y;
  int m_state_muon_index;

  __host__ __device__ MuonTrack() {}

  __host__ __device__ void add_hit_to_station(const unsigned hit_index, const int station_index)
  {
    ++m_number_of_hits;
    m_hits[station_index] = hit_index;
  }

  __host__ __device__ int hit(const int station_index) const { return m_hits[station_index]; }

  __host__ __device__ uint8_t number_of_hits() const { return m_number_of_hits; }

  __host__ __device__ float& tx() { return m_tx; }
  __host__ __device__ float& ty() { return m_ty; }
  __host__ __device__ float& ax() { return m_ax; }
  __host__ __device__ float& ay() { return m_ay; }
  __host__ __device__ float& chi2x() { return m_chi2x; }
  __host__ __device__ float& chi2y() { return m_chi2y; }
  __host__ __device__ int& state() { return m_state_muon_index; }

  __host__ __device__ float tx() const { return m_tx; }
  __host__ __device__ float ty() const { return m_ty; }
  __host__ __device__ float ax() const { return m_ax; }
  __host__ __device__ float ay() const { return m_ay; }
  __host__ __device__ float chi2x() const { return m_chi2x; }
  __host__ __device__ float chi2y() const { return m_chi2y; }
  __host__ __device__ int state() const { return m_state_muon_index; }
};

namespace MatchUpstreamMuon {
  static constexpr float kickOffset = 338.92f * Allen::Units::MeV; // KickOffset
  static constexpr float kickScale = 1218.62f * Allen::Units::MeV; // KickScale
  static constexpr float za = 5.331f * Allen::Units::m;            // MagnetPlaneParA
  static constexpr float zb = -0.958f * Allen::Units::m;           // MagnetPlaneParB
  static constexpr float ca = 25.17f * Allen::Units::mm;           // MagnetCorrParA
  static constexpr float cb = -701.5f * Allen::Units::mm;          // MagnetCorrParB

  static constexpr float maxChi2DoF = 20.f;
  // static constexpr bool fitY = false;
  // static constexpr bool setQOverP = false;

  static constexpr int M2 {0}, M3 {1}, M4 {2}, M5 {3};
  static constexpr int VeryLowP {0}, LowP {1}, MediumP {2}, HighP {3};

  struct Hit {
    /// Build a hit from a MuonID hit
    __device__ Hit(Muon::ConstHits& hits, const unsigned& i_muonhit) :
      x(hits.x(i_muonhit)), dx2(hits.dx(i_muonhit) * hits.dx(i_muonhit) / 12), y(hits.y(i_muonhit)),
      dy2(hits.dy(i_muonhit) * hits.dy(i_muonhit) / 12), z(hits.z(i_muonhit))
    {}
    /// Build a hit extrapolating the values from a state to the given point.
    __device__ Hit(const KalmanVeloState& state, const float& pz)
    {
      const float dz = pz - state.z();

      const float dz2 = dz * dz;

      x = state.x() + dz * state.tx();

      dx2 = state.c00() + dz2 * state.c22();

      y = state.y() + dz * state.ty();

      dy2 = state.c11() + dz2 * state.c33();

      z = pz;
    };
    __device__ Hit() : x {0.f}, dx2 {0.f}, y {0.f}, dy2 {0.f}, z {0.f} {};
    float x, dx2, y, dy2, z;
  };

  struct MuonChambers {
    int first[4] {M3, M4, M5, M5};
    int firstOffsets[4] {0, 1, 3, 4};

    int afterKick[6] {M2, M3, M2, M4, M3, M2};
    int afterKickOffsets[4] {0, 1, 3, 6};
  };

  struct SearchWindows {
    float Windows[8] {500.f * Allen::Units::mm, // M2
                      400.f * Allen::Units::mm,

                      600.f * Allen::Units::mm, // M3
                      500.f * Allen::Units::mm,

                      700.f * Allen::Units::mm, // M4
                      600.f * Allen::Units::mm,

                      800.f * Allen::Units::mm, // M5
                      700.f * Allen::Units::mm

    };
  };

} // namespace MatchUpstreamMuon
