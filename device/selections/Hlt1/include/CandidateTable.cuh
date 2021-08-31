/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

namespace Selections {

  struct CandidateTable {

  private:
    unsigned m_candidate_count;
    unsigned* m_candidate_indices;
    unsigned* m_candidate_inserts;

  public:
    __host__ __device__
    CandidateTable(unsigned candidate_count, unsigned* candidate_indices_base, unsigned* candidate_inserts_base) :
      m_candidate_count(candidate_count),
      m_candidate_indices(candidate_indices_base), m_candidate_inserts(candidate_inserts_base)
    {}

    __host__ __device__ unsigned get_insert_from_index(const unsigned index) const
    {
      return m_candidate_inserts[index];
    }

    __host__ __device__ unsigned get_index_from_insert(const unsigned insert) const
    {
      assert(insert < m_candidate_count);
      return m_candidate_indices[insert];
    }

    __host__ __device__ unsigned n_candidates() const { return m_candidate_count; }
  };

} // namespace Selections