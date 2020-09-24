/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "CudaCommon.h"

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

    __host__ __device__ Hits_t(T* base_pointer, const unsigned total_estimated_number_of_clusters, const unsigned offset = 0) :
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
    float x;
    float dx;
    float y;
    float dy;
    float z;
    unsigned int time;
    int tile;
    int uncrossed;
    int delta_time;
    int region;
  };
} // namespace Muon
