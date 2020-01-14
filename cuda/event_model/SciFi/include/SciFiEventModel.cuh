#pragma once

#include <ostream>
#include <stdint.h>

#include "States.cuh"
#include "SciFiDefinitions.cuh"

namespace SciFi {
  //----------------------------
  // Struct for hit information.
  //----------------------------
  struct Hit {
    float x0;
    float z0;
    float endPointY;
    uint channel;

    // Cluster reference:
    //   raw bank: 8 bits
    //   element (it): 8 bits
    //   Condition 1-2-3: 2 bits
    //   Condition 2.1-2.2: 1 bit
    //   Condition 2.1: log2(n+1) - 8 bits
    uint assembled_datatype;

    friend std::ostream& operator<<(std::ostream& stream, const Hit& hit)
    {
      stream << "SciFi hit {" << hit.x0 << ", " << hit.z0 << ", " << hit.channel << ", " << hit.assembled_datatype
             << "}";

      return stream;
    }
  };

  /**
   * @brief Offset and number of hits of each layer.
   */
  template<typename T>
  struct HitCount_t {
  private:
    typename ForwardType<T, uint>::t* m_mat_offsets;
    // TODO: Add "total number of hits" to information of this struct

  public:
    __host__ __device__ HitCount_t(typename ForwardType<T, uint>::t* base_pointer, const uint event_number) :
      m_mat_offsets(base_pointer + event_number * SciFi::Constants::n_mat_groups_and_mats)
    {}

    __host__ __device__ uint& mat_offsets(const uint mat_number)
    {
      assert(
        mat_number >= SciFi::Constants::n_consecutive_raw_banks * SciFi::Constants::n_mats_per_consec_raw_bank &&
        mat_number < SciFi::Constants::n_mats);
      const uint corrected_mat_number = mat_number - SciFi::Constants::mat_index_substract;
      return m_mat_offsets[corrected_mat_number];
    }

    __host__ __device__ uint mat_offsets(const uint mat_number) const
    {
      assert(
        mat_number >= SciFi::Constants::n_consecutive_raw_banks * SciFi::Constants::n_mats_per_consec_raw_bank &&
        mat_number < SciFi::Constants::n_mats);
      const uint corrected_mat_number = mat_number - SciFi::Constants::mat_index_substract;
      return m_mat_offsets[corrected_mat_number];
    }

    __host__ __device__ typename ForwardType<T, uint>::t* mat_offsets_p(const uint mat_number)
    {
      assert(
        mat_number >= SciFi::Constants::n_consecutive_raw_banks * SciFi::Constants::n_mats_per_consec_raw_bank &&
        mat_number < SciFi::Constants::n_mats);
      const uint corrected_mat_number = mat_number - SciFi::Constants::mat_index_substract;
      return m_mat_offsets + corrected_mat_number;
    }

    __host__ __device__ uint mat_number_of_hits(const uint mat_number) const
    {
      assert(mat_number >= SciFi::Constants::n_consecutive_raw_banks * SciFi::Constants::n_mats_per_consec_raw_bank);
      assert(mat_number < SciFi::Constants::n_mats);
      const uint corrected_mat_number = mat_number - SciFi::Constants::mat_index_substract;
      return m_mat_offsets[corrected_mat_number + 1] - m_mat_offsets[corrected_mat_number];
    }

    __host__ __device__ uint mat_group_offset(const uint mat_group_number) const
    {
      assert(mat_group_number < SciFi::Constants::n_consecutive_raw_banks);
      return m_mat_offsets[mat_group_number];
    }

    __host__ __device__ uint mat_group_number_of_hits(const uint mat_group_number) const
    {
      assert(mat_group_number < SciFi::Constants::n_consecutive_raw_banks);
      return m_mat_offsets[mat_group_number + 1] - m_mat_offsets[mat_group_number];
    }

    __host__ __device__ uint mat_group_or_mat_number_of_hits(const uint mat_or_mat_group_number) const
    {
      assert(mat_or_mat_group_number < SciFi::Constants::n_mat_groups_and_mats);
      return m_mat_offsets[mat_or_mat_group_number + 1] - m_mat_offsets[mat_or_mat_group_number];
    }

    __host__ __device__ uint zone_offset(const uint zone_number) const
    {
      // TODO: Make this a constant
      // constexpr uint32_t first_corrected_unique_mat_in_zone[] = {
      //   0, 40, 80, 120, 160, 200, 240, 280, 320, 360, 400, 440, 480, 520, 560, 600, 640,
      //   688, 736, 784, 832, 880, 928, 976, 1024};
      constexpr uint32_t first_corrected_unique_mat_in_zone[] = {0,   10,  20,  30,  40,  50,  60,  70,  80,
                                                                 90,  100, 110, 120, 130, 140, 150, 160, 208,
                                                                 256, 304, 352, 400, 448, 496, 544};
      return m_mat_offsets[first_corrected_unique_mat_in_zone[zone_number]];
    }

    __host__ __device__ uint zone_number_of_hits(const uint zone_number) const
    {
      return zone_offset(zone_number + 1) - zone_offset(zone_number);
    }

    __host__ __device__ uint event_number_of_hits() const
    {
      return m_mat_offsets[SciFi::Constants::n_mat_groups_and_mats] - m_mat_offsets[0];
    }

    __host__ __device__ uint number_of_hits_in_zones_without_mat_groups() const
    {
      return m_mat_offsets[SciFi::Constants::n_mat_groups_and_mats] -
             m_mat_offsets[SciFi::Constants::n_consecutive_raw_banks];
    }

    __host__ __device__ uint event_offset() const { return m_mat_offsets[0]; }

    __host__ __device__ uint offset_zones_without_mat_groups() const
    {
      return m_mat_offsets[SciFi::Constants::n_consecutive_raw_banks];
    }
  };

  typedef const HitCount_t<const char> ConstHitCount;
  typedef HitCount_t<char> HitCount;

  template<typename T>
  struct Hits_t {
  private:
    typename ForwardType<T, float>::t* m_base_pointer;
    const uint m_total_number_of_hits;

  public:
    __host__ __device__
    Hits_t(T* base_pointer, const uint total_number_of_hits, const uint offset = 0) :
      m_base_pointer(reinterpret_cast<typename ForwardType<T, float>::t*>(base_pointer) + offset),
      m_total_number_of_hits(total_number_of_hits)
    {}

    // Const and lvalue accessors
    __host__ __device__ float x0(const uint index) const
    {
      assert(index < m_total_number_of_hits);
      return m_base_pointer[index];
    }

    __host__ __device__ float& x0(const uint index)
    {
      assert(index < m_total_number_of_hits);
      return m_base_pointer[index];
    }

    __host__ __device__ float z0(const uint index) const
    {
      assert(index < m_total_number_of_hits);
      return m_base_pointer[m_total_number_of_hits + index];
    }

    __host__ __device__ float& z0(const uint index)
    {
      assert(index < m_total_number_of_hits);
      return m_base_pointer[m_total_number_of_hits + index];
    }

    __host__ __device__ float endPointY(const uint index) const
    {
      assert(index < m_total_number_of_hits);
      return m_base_pointer[2 * m_total_number_of_hits + index];
    }

    __host__ __device__ float& endPointY(const uint index)
    {
      assert(index < m_total_number_of_hits);
      return m_base_pointer[2 * m_total_number_of_hits + index];
    }

    __host__ __device__ uint channel(const uint index) const
    {
      assert(index < m_total_number_of_hits);
      return reinterpret_cast<typename ForwardType<T, uint>::t*>(m_base_pointer)[3 * m_total_number_of_hits + index];
    }

    __host__ __device__ uint& channel(const uint index)
    {
      assert(index < m_total_number_of_hits);
      return reinterpret_cast<typename ForwardType<T, uint>::t*>(m_base_pointer)[3 * m_total_number_of_hits + index];
    }

    __host__ __device__ uint assembled_datatype(const uint index) const
    {
      assert(index < m_total_number_of_hits);
      return reinterpret_cast<typename ForwardType<T, uint>::t*>(m_base_pointer)[4 * m_total_number_of_hits + index];
    }

    __host__ __device__ uint& assembled_datatype(const uint index)
    {
      assert(index < m_total_number_of_hits);
      return reinterpret_cast<typename ForwardType<T, uint>::t*>(m_base_pointer)[4 * m_total_number_of_hits + index];
    }

    __host__ __device__ uint cluster_reference(const uint index) const
    {
      assert(index < m_total_number_of_hits);
      return reinterpret_cast<typename ForwardType<T, uint>::t*>(m_base_pointer)[5 * m_total_number_of_hits + index];
    }

    __host__ __device__ uint& cluster_reference(const uint index)
    {
      assert(index < m_total_number_of_hits);
      return reinterpret_cast<typename ForwardType<T, uint>::t*>(m_base_pointer)[5 * m_total_number_of_hits + index];
    }

    __host__ __device__ uint id(const uint index) const { return (10u << 28) + channel(index); };

    __host__ __device__ uint mat(const uint index) const { return assembled_datatype(index) & 0x7ff; };

    __host__ __device__ uint pseudoSize(const uint index) const { return (assembled_datatype(index) >> 11) & 0xf; };

    __host__ __device__ uint planeCode(const uint index) const { return (assembled_datatype(index) >> 15) & 0x1f; };

    __host__ __device__ uint fraction(const uint index) const { return (assembled_datatype(index) >> 20) & 0x1; };

    __host__ __device__ Hit get(const uint hit_number) const
    {
      return SciFi::Hit {
        x0(hit_number), z0(hit_number), endPointY(hit_number), channel(hit_number), assembled_datatype(hit_number)};
    }

    // Pointer accessor for binary search
    __host__ __device__ typename ForwardType<T, float>::t* x0_p(const uint index) const
    {
      assert(index < m_total_number_of_hits);
      return m_base_pointer + index;
    }
  };

  typedef const Hits_t<const char> ConstHits;
  typedef Hits_t<char> Hits;

  template<typename T>
  struct ExtendedHits_t : public Hits_t<T> {
  private:
    const float* m_inv_clus_res;
    const SciFiGeometry* m_geom;

  public:
    __host__ __device__ ExtendedHits_t(
      T* base_pointer,
      const uint total_number_of_hits,
      const float* inv_clus_res,
      const SciFiGeometry* geom,
      const uint offset = 0) :
      Hits_t<T>(base_pointer, total_number_of_hits, offset),
      m_inv_clus_res(inv_clus_res), m_geom(geom)
    {}

    using Hits_t<T>::pseudoSize;
    using Hits_t<T>::endPointY;
    using Hits_t<T>::channel;
    using Hits_t<T>::mat;

    // Additional accessors provided by having inv clus res and geometry information
    __host__ __device__ float w(const uint index) const
    {
      assert(pseudoSize(index) < 9 && "Wrong pseudo size.");
      const auto werrX = m_inv_clus_res[pseudoSize(index)];
      return werrX * werrX;
    };

    __host__ __device__ float dxdy(const uint index) const { return m_geom->dxdy[mat(index)]; };

    __host__ __device__ float dzdy(const uint index) const { return m_geom->dzdy[mat(index)]; };

    __host__ __device__ float yMin(const uint index) const
    {
      const SciFiChannelID id(channel(index));
      return endPointY(index) + id.isBottom() * m_geom->globaldy[mat(index)];
    };

    __host__ __device__ float yMax(const uint index) const
    {
      const SciFiChannelID id(channel(index));
      return endPointY(index) + !id.isBottom() * m_geom->globaldy[mat(index)];
    };

    // Deprecated code?
    // __host__ __device__ float endPointY(const uint index) const
    // {
    //   const SciFiChannelID id(channel[index]);
    //   float uFromChannel =
    //     m_geom->uBegin[mat(index)] + (2 * id.channel() + 1 + fraction(index)) * m_geom->halfChannelPitch[mat(index)];
    //   if (id.die()) uFromChannel += m_geom->dieGap[mat(index)];
    //   return m_geom->mirrorPointY[mat(index)] + m_geom->ddxY[mat(index)] * uFromChannel;
    // }
  };

  typedef const ExtendedHits_t<const char> ConstExtendedHits;
  typedef ExtendedHits_t<char> ExtendedHits;

  /**
   * Track object used for storing tracks
   */
  struct TrackCandidate {
    float quality = 0.f;
    float qop;
    uint16_t ut_track_index;
    uint16_t hits[SciFi::Constants::max_track_candidate_size];
    uint8_t hitsNum = 0;

    __host__ __device__ TrackCandidate() {};

    __host__ __device__ TrackCandidate(const TrackCandidate& candidate) :
      quality(candidate.quality), qop(candidate.qop), ut_track_index(candidate.ut_track_index),
      hitsNum(candidate.hitsNum)
    {
      for (int i = 0; i < hitsNum; ++i) {
        hits[i] = candidate.hits[i];
      }
    }

    __host__ __device__
    TrackCandidate(const uint16_t h0, const uint16_t h1, const uint16_t param_ut_track_index, const float param_qop) :
      quality(0.f),
      qop(param_qop), ut_track_index(param_ut_track_index), hitsNum(2)
    {
      hits[0] = h0;
      hits[1] = h1;
    };

    __host__ __device__ void add_hit(uint16_t hit_index)
    {
      assert(hitsNum < SciFi::Constants::max_track_candidate_size);
      hits[hitsNum++] = hit_index;
    }

    __host__ __device__ void add_hit_with_quality(uint16_t hit_index, float chi2)
    {
      assert(hitsNum < SciFi::Constants::max_track_candidate_size);
      hits[hitsNum++] = hit_index;
      quality += chi2;
    }
  };

  /**
   * Track object used for storing tracks
   */
  struct TrackHits {
    float quality = 0.f;
    float qop;
    uint16_t ut_track_index;
    uint16_t hits[SciFi::Constants::max_track_size];
    uint8_t hitsNum = 0;

    __host__ __device__ TrackHits operator=(const TrackHits& other)
    {
      quality = other.quality;
      qop = other.qop;
      ut_track_index = other.ut_track_index;
      hitsNum = other.hitsNum;
      for (int i = 0; i < SciFi::Constants::max_track_size; ++i) {
        hits[i] = other.hits[i];
      }

      return *this;
    }

    __host__ __device__ TrackHits() {};

    __host__ __device__ TrackHits(const TrackHits& other) :
      quality(other.quality), qop(other.qop), ut_track_index(other.ut_track_index), hitsNum(other.hitsNum)
    {
      for (int i = 0; i < hitsNum; ++i) {
        hits[i] = other.hits[i];
      }
    }

    __host__ __device__ TrackHits(const TrackCandidate& candidate) :
      quality(candidate.quality), qop(candidate.qop), ut_track_index(candidate.ut_track_index),
      hitsNum(candidate.hitsNum)
    {
      for (int i = 0; i < hitsNum; ++i) {
        hits[i] = candidate.hits[i];
      }
    }

    __host__ __device__ TrackHits(
      const uint16_t h0,
      const uint16_t h1,
      const uint16_t h2,
      const float chi2,
      const float qop,
      const uint16_t ut_track_index) :
      quality(chi2),
      qop(qop), ut_track_index(ut_track_index)
    {
      hitsNum = 3;
      hits[0] = h0;
      hits[1] = h1;
      hits[2] = h2;
    }

    __host__ __device__ TrackHits(
      const uint16_t h0,
      const uint16_t h1,
      const uint16_t h2,
      const uint16_t layer_h0,
      const uint16_t layer_h1,
      const uint16_t layer_h2,
      const float chi2,
      const float qop,
      const uint16_t ut_track_index) :
      quality(chi2),
      qop(qop), ut_track_index(ut_track_index)
    {
      hitsNum = 3;
      hits[0] = h0;
      hits[1] = h1;
      hits[2] = h2;
      hits[SciFi::Constants::hit_layer_offset] = layer_h0;
      hits[SciFi::Constants::hit_layer_offset + 1] = layer_h1;
      hits[SciFi::Constants::hit_layer_offset + 2] = layer_h2;
    }

    __host__ __device__ uint16_t get_layer(uint8_t index) const
    {
      assert(hitsNum <= SciFi::Constants::hit_layer_offset);
      return hits[SciFi::Constants::hit_layer_offset + index];
    }

    __host__ __device__ void add_hit(uint16_t hit_index)
    {
      assert(hitsNum < SciFi::Constants::max_track_size);
      hits[hitsNum++] = hit_index;
    }

    __host__ __device__ void add_hit_with_quality(uint16_t hit_index, float chi2)
    {
      assert(hitsNum < SciFi::Constants::max_track_size);
      hits[hitsNum++] = hit_index;
      quality += chi2;
    }

    __host__ __device__ void add_hit_with_layer_and_quality(uint16_t hit_index, uint16_t layer, float chi2)
    {
      assert(hitsNum < SciFi::Constants::max_track_size);
      hits[hitsNum] = hit_index;
      hits[SciFi::Constants::hit_layer_offset + hitsNum++] = layer;
      quality += chi2;
    }

    __host__ __device__ float get_quality() const
    {
      assert(hitsNum > 2);
      return quality / ((float) hitsNum - 2);
    }

    __host__ __device__ void print(int event_number = -1) const
    {
      printf("Track with %i hits:", hitsNum);
      for (int i = 0; i < hitsNum; ++i) {
        printf(" %i,", hits[i]);
      }
      printf(
        " qop %f, quality %f, UT track %i", static_cast<double>(qop), static_cast<double>(quality), ut_track_index);
      if (event_number >= 0) {
        printf(" (event %i)", event_number);
      }
      printf("\n");
    }
  };

  struct CombinedValue {
    float chi2 = 10000.f;
    uint16_t h0 = 0;
    uint16_t h1 = 0;
    uint16_t h2 = 0;
  };
} // namespace SciFi
