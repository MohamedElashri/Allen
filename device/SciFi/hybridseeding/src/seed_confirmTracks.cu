/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "BinarySearch.cuh"
#include "memory_optim.cuh"

#include "seed_confirmTracks.cuh"

#include "hybrid_seeding_helpers.cuh"
#include "hybrid_seeding_case.cuh"
/**
 * @brief Seeding in SciFi confirming xz segments
 * @detail first implementation of seeding starting with x_z layers to fit under HLT1 timing budget.
 */
INSTANTIATE_ALGORITHM(seed_confirmTracks::seed_confirmTracks_t);
void seed_confirmTracks::seed_confirmTracks_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  int sizeTracks = first<host_number_of_events_t>(arguments) * SciFi::Constants::Nmax_seeds;
  int sizeInts = first<host_number_of_events_t>(arguments);
  // host outputs
  set_size<host_seeding_tracks_t>(arguments, sizeTracks);
  set_size<host_seeding_number_of_tracks_t>(arguments, sizeInts);

  // working memory
  set_size<dev_hits_working_mem_t>(arguments, size<dev_scifi_hits_t>(arguments) / sizeof(SciFi::ConstHits));
  set_size<dev_count_hits_working_mem_t>(arguments, 1);

  // device outputs
  set_size<dev_seeding_number_of_tracks_t>(arguments, sizeInts);
  set_size<dev_seeding_tracks_t>(arguments, sizeTracks);
  set_size<dev_seeding_confirmTracks_atomics_t>(arguments, sizeInts);
}

void seed_confirmTracks::seed_confirmTracks_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_seeding_confirmTracks_atomics_t>(arguments, 0, context);
  Allen::memset_async<dev_count_hits_working_mem_t>(arguments, 0, context);

  global_function(seed_confirmTracks)(dim3(size<dev_event_list_t>(arguments)), dim3(128), context)(arguments);
}

__device__ int seed_confirmTracks::findHit(const float tolRem, float predPos, int startPos, int nHits, float* coords)
{
  auto minIdx = seeding::searchBin(predPos, coords, startPos, nHits);
  if (std::fabs(coords[minIdx] - predPos) > tolRem) return SciFi::Constants::INVALID_IDX;
  return minIdx;
}

__global__ void seed_confirmTracks::seed_confirmTracks(Parameters parameters)
{
  /*
    Reconstructs full tracks from XZ candidates.
    Parallelised over tracks :
  */
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  // SciFi hits
  const uint total_number_of_hits =
    parameters.dev_scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats];
  SciFi::ConstHitCount scifi_hit_count {parameters.dev_scifi_hit_count, event_number};
  SciFi::ConstHits scifi_hits {parameters.dev_scifi_hits, total_number_of_hits};

  int shiftCaseTracks = 0;
  for (unsigned int part = 0; part < SciFi::Constants::n_parts; part++) {
    __shared__ int nTracksPerPart;
    if (threadIdx.x == 0) nTracksPerPart = 0;

    // Define geometry factors
    const auto nLayers = seed_uv::geomInfo::nLayers;
    // 0 2 4 6  8 10 12 14  16 18 20 22
    //   1 5       0  3         4  2
    unsigned int uvCodes[nLayers] = {10 + part, 2 + part, 20 + part, 12 + part, 18 + part, 4 + part}; // FIXME

    // Storing hits
    static constexpr unsigned int maxNHits = 300; // FIXME
    __shared__ float hits_shared[nLayers * maxNHits];
    seeding::HitCache hits;
    unsigned zone_offset[6];
    // Load the hits in shared:
    unsigned totalHits = 0;
    for (unsigned int iLayer = 0; iLayer < nLayers; iLayer++) {
      hits.size[iLayer] = scifi_hit_count.zone_number_of_hits(uvCodes[iLayer]);
      totalHits += hits.size[iLayer];
    }

    shared_or_global<float>(
      totalHits,
      nLayers * maxNHits,
      hits_shared,
      parameters.dev_hits_working_mem,
      parameters.dev_count_hits_working_mem,
      [&](float* ptr) {
        hits.data = ptr;

        hits.start[0] = 0;
        for (unsigned int iLayer = 0; iLayer < nLayers; iLayer++) {
          if (iLayer > 0) hits.start[iLayer] = hits.start[iLayer - 1] + hits.size[iLayer - 1];
          zone_offset[iLayer] = scifi_hit_count.zone_offset(uvCodes[iLayer]);
          for (unsigned int iHit = threadIdx.x; iHit < hits.size[iLayer]; iHit += blockDim.x) {
            hits.hit(iLayer, iHit) = scifi_hits.x0(zone_offset[iLayer] + iHit);
          }
        }
        __syncthreads();
        float partSign = (part == 1) * 2.f - 1.f;
        float yCenter = seed_uv::geomInfo::yCenter * partSign;
        float yEdge = seed_uv::geomInfo::yEdge * partSign;
        float dxMin[nLayers], dxMax[nLayers];
        for (int iLayer = 0; iLayer != nLayers; iLayer++) {
          float dxCenter = yCenter * seed_uv::geomInfo::dxDy[iLayer];
          float dxEdge = yEdge * seed_uv::geomInfo::dxDy[iLayer];
          dxMin[iLayer] = min(dxCenter, dxEdge);
          dxMax[iLayer] = max(dxCenter, dxEdge);
        }
        // We can fully parallelise over tracks (they are only weakly ordered)
        const auto xTracks = parameters.dev_seeding_tracksXZ;
        int shiftTrack =
          (part == 0) ?
            0 :
            parameters
              .dev_seeding_number_of_tracksXZ_part0[event_number]; // FIXME: LC: we can probably find an easier solution
        int startTrack = event_number * SciFi::Constants::Nmax_seed_xz + shiftTrack;
        int endTrack = (part == 0) ? parameters.dev_seeding_number_of_tracksXZ_part0[event_number] :
                                     parameters.dev_seeding_number_of_tracksXZ_part1[event_number];
        endTrack += startTrack;
        for (int iTrack = startTrack + threadIdx.x; iTrack < endTrack; iTrack += blockDim.x) {
          constexpr int TUNING_NHITS = 10;        // FIXME
          constexpr float TUNING_TOLCHI2 = 100.f; // FIXME
          constexpr float TUNING_TOL = 2.f;       // FIXME
          const auto xTrack = xTracks[iTrack];
          const unsigned int nTarget = TUNING_NHITS - xTrack.number_of_hits;
          // Calculate the predicted x(z) position of the track in all U/V layers
          float xPred[nLayers];
          for (unsigned int iLayer = 0; iLayer < nLayers; iLayer++) {
            xPred[iLayer] =
              xTrack.ax + xTrack.bx * seed_uv::geomInfo::dz[iLayer] + xTrack.cx * seed_uv::geomInfo::dz2[iLayer];
          }
          // Collect hits in the first layer and parallelise over them as well. There are up to few tens of them
          float bestChi2Ndof = TUNING_TOLCHI2;
          seed_uv::multiHitCombination bestHitComb;
          // For each hit in first layer and tolerance, look for hit combinations that match that hypothesis
          unsigned int minXPredIdx[nLayers], nIdx[nLayers];
          for (unsigned int iLayer = 0; iLayer < nLayers; iLayer++) {
            auto minXPred = xPred[iLayer] + dxMin[iLayer];
            auto maxXPred = xPred[iLayer] + dxMax[iLayer];
            minXPredIdx[iLayer] =
              hybrid_seeding::binary_search_leftmost_unrolled(hits.layer(iLayer), hits.size[iLayer], minXPred);
            auto maxXPredIdx =
              hybrid_seeding::binary_search_leftmost_unrolled(hits.layer(iLayer), hits.size[iLayer], maxXPred);
            nIdx[iLayer] = maxXPredIdx - minXPredIdx[iLayer];
            if (maxXPredIdx != hits.size[iLayer]) nIdx[iLayer]++;
          }
          // First loop
          for (unsigned int iHitFirst = minXPredIdx[0]; iHitFirst < minXPredIdx[0] + nIdx[0]; iHitFirst++) {
            seed_uv::multiHitCombination hitComb;
            // We now have a tY hypothesis. We look in all 5 remaining layers for hits close to expected position
            // this is basically the same thing as looking for the first hit, but with tY in a smaller interval
            hitComb.idx[0] = iHitFirst;
            hitComb.y[0] = (xPred[0] - hits.hit(0, iHitFirst)) / seed_uv::geomInfo::dxDy[0];
            float ty = hitComb.y[0] / (seed_uv::geomInfo::z[0]);
            for (unsigned int iRemaining = 1; iRemaining < nLayers; iRemaining++) {
              // Check if we can even find enough hits
              if (hitComb.number_of_hits + (nLayers - iRemaining) < nTarget) break;
              float xMeasPred =
                xPred[iRemaining] - ty * seed_uv::geomInfo::dxDy[iRemaining] * seed_uv::geomInfo::z[iRemaining];
              hitComb.idx[iRemaining] =
                findHit(TUNING_TOL, xMeasPred, minXPredIdx[iRemaining], nIdx[iRemaining], hits.layer(iRemaining));
              if (hitComb.idx[iRemaining] != SciFi::Constants::INVALID_IDX) {
                hitComb.y[iRemaining] = (xPred[iRemaining] - hits.hit(iRemaining, hitComb.idx[iRemaining])) /
                                        seed_uv::geomInfo::dxDy[iRemaining];
                // refine ty:
                ty = (ty + hitComb.y[iRemaining] / seed_uv::geomInfo::z[iRemaining]) * 0.5f;
                ++hitComb.number_of_hits;
              }
            }
            if (xTrack.number_of_hits + hitComb.number_of_hits < TUNING_NHITS) continue;
            if (hitComb.number_of_hits < bestHitComb.number_of_hits) continue;
            fitYZ(hitComb);
            if (hitComb.number_of_hits == bestHitComb.number_of_hits && hitComb.chi2 > bestChi2Ndof) continue;
            bestChi2Ndof = hitComb.chi2;
            bestHitComb = hitComb;
          }
          // Second loop
          for (unsigned int iHitFirst = minXPredIdx[1]; iHitFirst < minXPredIdx[1] + nIdx[1]; iHitFirst++) {
            seed_uv::multiHitCombination hitComb;
            // We now have a tY hypothesis. We look in all 5 remaining layers for hits close to expected position
            // this is basically the same thing as looking for the first hit, but with tY in a smaller interval
            hitComb.idx[0] = SciFi::Constants::INVALID_IDX;
            hitComb.idx[1] = iHitFirst;
            hitComb.y[1] = (xPred[1] - hits.hit(1, iHitFirst)) / seed_uv::geomInfo::dxDy[1];
            float ty = hitComb.y[1] / (seed_uv::geomInfo::z[1]);
            for (unsigned int iRemaining = 2; iRemaining < nLayers; iRemaining++) {
              // Check if we can even find enough hits
              if (hitComb.number_of_hits + (nLayers - iRemaining) < nTarget) break;
              float xMeasPred =
                xPred[iRemaining] - ty * seed_uv::geomInfo::dxDy[iRemaining] * seed_uv::geomInfo::z[iRemaining];
              hitComb.idx[iRemaining] =
                findHit(TUNING_TOL, xMeasPred, minXPredIdx[iRemaining], nIdx[iRemaining], hits.layer(iRemaining));
              if (hitComb.idx[iRemaining] != SciFi::Constants::INVALID_IDX) {
                hitComb.y[iRemaining] = (xPred[iRemaining] - hits.hit(iRemaining, hitComb.idx[iRemaining])) /
                                        seed_uv::geomInfo::dxDy[iRemaining];
                // refine ty:
                ty = (ty + hitComb.y[iRemaining] / seed_uv::geomInfo::z[iRemaining]) * 0.5f;
                ++hitComb.number_of_hits;
              }
            }
            if (xTrack.number_of_hits + hitComb.number_of_hits < TUNING_NHITS) continue;
            fitYZ(hitComb);
            if (hitComb.number_of_hits < bestHitComb.number_of_hits) continue;
            if (hitComb.number_of_hits == bestHitComb.number_of_hits && hitComb.chi2 > bestChi2Ndof) continue;
            bestChi2Ndof = hitComb.chi2;
            bestHitComb = hitComb;
          }

          if (xTrack.number_of_hits + bestHitComb.number_of_hits < TUNING_NHITS) continue;
          // We have found at least one combination that matches the XZ track. Build the full track.
          SciFi::Seeding::Track fullTrack;
          for (auto iHit = 0; iHit < xTrack.number_of_hits; iHit++) {
            fullTrack.hits[iHit] = xTrack.hits[iHit];
          }
          auto iHit = 0;
          for (unsigned iLayer = 0; iLayer < nLayers; iLayer++) {
            if (bestHitComb.idx[iLayer] == SciFi::Constants::INVALID_IDX) continue;
            fullTrack.hits[xTrack.number_of_hits + iHit] =
              scifi_hit_count.zone_offset(uvCodes[iLayer]) + bestHitComb.idx[iLayer];
            iHit++;
          }

          fullTrack.number_of_hits = xTrack.number_of_hits + bestHitComb.number_of_hits;
          fullTrack.ay = bestHitComb.ay;
          fullTrack.by = bestHitComb.by;
          fullTrack.ax = xTrack.ax;
          fullTrack.bx = xTrack.bx;
          fullTrack.cx = xTrack.cx;
          auto startIndex = SciFi::Constants::Nmax_seeds * event_number + shiftCaseTracks;
          auto idx = atomicAdd(&nTracksPerPart, 1);
          if (idx >= SciFi::Constants::Nmax_seeds_per_part) break;
          parameters.dev_seeding_tracks[startIndex + idx] = fullTrack;
        }
        __syncthreads();
        shiftCaseTracks += min(nTracksPerPart, SciFi::Constants::Nmax_seeds_per_part);
        __syncthreads();
      });
  } // end the loop on parts
  if (threadIdx.x == 0) {
    parameters.dev_seeding_number_of_tracks[event_number] = shiftCaseTracks;
    parameters.dev_seeding_confirmTracks_atomics[event_number] = shiftCaseTracks;
  }
}

__device__ void seed_confirmTracks::fitYZ(seed_uv::multiHitCombination& multiHitComb)
{
  float m00 = multiHitComb.number_of_hits;
  float m01 = 0.f;
  float m11 = 0.f;
  float r0 = 0.f;
  float r1 = 0.f;
  float ay = 0.f;
  float by = 0.f;
  // initialize matrix
  for (unsigned int i = 0; i < seed_uv::geomInfo::nLayers; i++) {
    if (multiHitComb.idx[i] == SciFi::Constants::INVALID_IDX) continue;
    m01 += seed_uv::geomInfo::dz[i];
    m11 += seed_uv::geomInfo::dz[i] * seed_uv::geomInfo::dz[i];
    r0 += multiHitComb.y[i];
    r1 += multiHitComb.y[i] * seed_uv::geomInfo::dz[i];
  }
  // calculate the determinants and apply Cramer's rule
  float detM = m00 * m11 - m01 * m01; // never 0, no need to test
  ay += (r0 * m11 - r1 * m01) / detM;
  by += (r1 * m00 - r0 * m01) / detM;
  float score = 0.f;
  for (unsigned int i = 0; i < seed_uv::geomInfo::nLayers; i++) {
    if (multiHitComb.idx[i] == SciFi::Constants::INVALID_IDX) continue;
    float hit_chi2 = (multiHitComb.y[i] - (ay + by * seed_uv::geomInfo::dz[i]));
    hit_chi2 *= hit_chi2;
    score += hit_chi2;
  }
  multiHitComb.ay = ay;
  multiHitComb.by = by;
  multiHitComb.chi2 = score;
}
