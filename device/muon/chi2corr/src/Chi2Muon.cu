/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "ArgumentOps.cuh"
#include "Chi2Muon.cuh"
#include "SystemOfUnits.h"

INSTANTIATE_ALGORITHM(chi2_muon::chi2_muon_t)

template<typename T>
inline __host__ __device__ T square(const T a)
{
  return a * a;
}

void chi2_muon::chi2_muon_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_chi2_muon_t>(arguments, first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
  set_size<dev_chi2uncorr_muon_t>(arguments, first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
}

void chi2_muon::chi2_muon_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_chi2_muon_t>(arguments, 10, context);
  Allen::memset_async<dev_chi2uncorr_muon_t>(arguments, 10, context);

  global_function(chi2_muon)(dim3(size<dev_event_list_t>(arguments)), dim3(m_block_dim_x), context)(arguments);
}

__device__ void invert_matrix(float (&matrix)[4][4], float (&invMatrix)[4][4], unsigned dimension)
{

  float deter;

  float minor[4][4] = {{0.f, 0.f, 0.f, 0.f}, {0.f, 0.f, 0.f, 0.f}, {0.f, 0.f, 0.f, 0.f}, {0.f, 0.f, 0.f, 0.f}};

  if (dimension == 1) {
    invMatrix[0][0] = 1 / matrix[0][0];
  }

  else if (dimension == 2) {
    minor[0][0] = matrix[1][1];
    minor[0][1] = matrix[1][0];
    minor[1][0] = minor[0][1];
    minor[1][1] = matrix[0][0];
    deter = fabsf(matrix[0][0] * matrix[1][1] - matrix[1][0] * matrix[0][1]);
    invMatrix[0][0] = minor[0][0] / deter;
    invMatrix[0][1] = -minor[0][1] / deter;
    invMatrix[1][0] = -minor[1][0] / deter;
    invMatrix[1][1] = minor[1][1] / deter;
  }
  else if (dimension == 3) {
    minor[0][0] = matrix[1][1] * matrix[2][2] - matrix[1][2] * matrix[2][1];
    minor[0][1] = matrix[1][0] * matrix[2][2] - matrix[1][2] * matrix[2][0];
    minor[0][2] = matrix[1][0] * matrix[2][1] - matrix[1][1] * matrix[2][0];
    minor[1][0] = minor[0][1];
    minor[1][1] = matrix[0][0] * matrix[2][2] - matrix[0][2] * matrix[2][0];
    minor[1][2] = matrix[0][0] * matrix[2][1] - matrix[0][1] * matrix[2][0];
    minor[2][0] = minor[0][2];
    minor[2][1] = minor[1][2];
    minor[2][2] = matrix[0][0] * matrix[1][1] - matrix[0][1] * matrix[1][0];
    deter = fabsf(matrix[0][0] * minor[0][0] - matrix[0][1] * minor[0][1] + matrix[0][2] * minor[0][2]);
    invMatrix[0][0] = minor[0][0] / deter;
    invMatrix[0][1] = -minor[0][1] / deter;
    invMatrix[0][2] = minor[0][2] / deter;
    invMatrix[1][0] = -minor[1][0] / deter;
    invMatrix[1][1] = minor[1][1] / deter;
    invMatrix[1][2] = -minor[1][2] / deter;
    invMatrix[2][0] = minor[2][0] / deter;
    invMatrix[2][1] = -minor[2][1] / deter;
    invMatrix[2][2] = minor[2][2] / deter;
  }
  else if (dimension == 4) {
    minor[0][0] = matrix[1][1] * matrix[2][2] * matrix[3][3] + matrix[2][1] * matrix[3][2] * matrix[1][3] +
                  matrix[1][2] * matrix[2][3] * matrix[3][1] - matrix[1][3] * matrix[2][2] * matrix[3][1] -
                  matrix[1][2] * matrix[2][1] * matrix[3][3] - matrix[2][3] * matrix[3][2] * matrix[1][1];
    minor[0][1] = matrix[1][0] * matrix[2][2] * matrix[3][3] + matrix[2][0] * matrix[3][2] * matrix[1][3] +
                  matrix[1][2] * matrix[2][3] * matrix[3][0] - matrix[1][3] * matrix[2][2] * matrix[3][0] -
                  matrix[1][2] * matrix[2][0] * matrix[3][3] - matrix[2][3] * matrix[3][2] * matrix[1][0];
    minor[0][2] = matrix[1][0] * matrix[2][1] * matrix[3][3] + matrix[2][0] * matrix[3][1] * matrix[1][3] +
                  matrix[1][1] * matrix[2][3] * matrix[3][0] - matrix[1][3] * matrix[2][1] * matrix[3][0] -
                  matrix[1][1] * matrix[2][0] * matrix[3][3] - matrix[2][3] * matrix[3][1] * matrix[1][0];
    minor[0][3] = matrix[1][0] * matrix[2][1] * matrix[3][2] + matrix[2][0] * matrix[3][1] * matrix[1][2] +
                  matrix[1][1] * matrix[2][2] * matrix[3][0] - matrix[1][2] * matrix[2][1] * matrix[3][0] -
                  matrix[1][1] * matrix[2][0] * matrix[3][2] - matrix[2][2] * matrix[3][1] * matrix[1][0];
    minor[1][0] = minor[0][1];
    minor[1][1] = matrix[0][0] * matrix[2][2] * matrix[3][3] + matrix[2][0] * matrix[3][2] * matrix[0][3] +
                  matrix[0][2] * matrix[2][3] * matrix[3][0] - matrix[0][3] * matrix[2][2] * matrix[3][0] -
                  matrix[0][2] * matrix[2][0] * matrix[3][3] - matrix[2][3] * matrix[3][2] * matrix[0][0];
    minor[1][2] = matrix[0][0] * matrix[2][1] * matrix[3][3] + matrix[2][0] * matrix[3][1] * matrix[0][3] +
                  matrix[0][1] * matrix[2][3] * matrix[3][0] - matrix[0][3] * matrix[2][1] * matrix[3][0] -
                  matrix[0][1] * matrix[2][0] * matrix[3][3] - matrix[2][3] * matrix[3][1] * matrix[0][0];
    minor[1][3] = matrix[0][0] * matrix[2][1] * matrix[3][2] + matrix[2][0] * matrix[3][1] * matrix[0][2] +
                  matrix[0][1] * matrix[2][2] * matrix[3][0] - matrix[0][2] * matrix[2][1] * matrix[3][0] -
                  matrix[0][1] * matrix[2][0] * matrix[3][2] - matrix[2][2] * matrix[3][1] * matrix[0][0];
    minor[2][0] = minor[0][2];
    minor[2][1] = minor[1][2];
    minor[2][2] = matrix[0][0] * matrix[1][1] * matrix[3][3] + matrix[1][0] * matrix[3][1] * matrix[0][3] +
                  matrix[0][1] * matrix[1][3] * matrix[3][0] - matrix[0][3] * matrix[1][1] * matrix[3][0] -
                  matrix[0][1] * matrix[1][0] * matrix[3][3] - matrix[1][3] * matrix[3][1] * matrix[0][0];
    minor[2][3] = matrix[0][0] * matrix[1][1] * matrix[3][2] + matrix[1][0] * matrix[3][1] * matrix[0][2] +
                  matrix[0][1] * matrix[1][2] * matrix[3][0] - matrix[0][2] * matrix[1][1] * matrix[3][0] -
                  matrix[0][1] * matrix[1][0] * matrix[3][2] - matrix[1][2] * matrix[3][1] * matrix[0][0];
    minor[3][0] = minor[0][3];
    minor[3][1] = minor[1][3];
    minor[3][2] = minor[2][3];
    minor[3][3] = matrix[0][0] * matrix[1][1] * matrix[2][2] + matrix[1][0] * matrix[2][1] * matrix[0][2] +
                  matrix[0][1] * matrix[1][2] * matrix[2][0] - matrix[0][2] * matrix[1][1] * matrix[2][0] -
                  matrix[0][1] * matrix[1][0] * matrix[2][2] - matrix[1][2] * matrix[2][1] * matrix[0][0];
    deter = fabsf(
      matrix[0][0] * minor[0][0] - matrix[0][1] * minor[0][1] + matrix[0][2] * minor[0][2] -
      matrix[0][3] * minor[0][3]);
    invMatrix[0][0] = minor[0][0] / deter;
    invMatrix[0][1] = -minor[0][1] / deter;
    invMatrix[0][2] = minor[0][2] / deter;
    invMatrix[0][3] = -minor[0][3] / deter;
    invMatrix[1][0] = -minor[1][0] / deter;
    invMatrix[1][1] = minor[1][1] / deter;
    invMatrix[1][2] = -minor[1][2] / deter;
    invMatrix[1][3] = minor[1][3] / deter;
    invMatrix[2][0] = minor[2][0] / deter;
    invMatrix[2][1] = -minor[2][1] / deter;
    invMatrix[2][2] = minor[2][2] / deter;
    invMatrix[2][3] = -minor[2][3] / deter;
    invMatrix[3][0] = -minor[3][0] / deter;
    invMatrix[3][1] = minor[3][1] / deter;
    invMatrix[3][2] = -minor[3][2] / deter;
    invMatrix[3][3] = minor[3][3] / deter;
  }
}
__global__ void chi2_muon::chi2_muon(chi2_muon::Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  const auto long_tracks = parameters.dev_long_tracks_view->container(event_number);

  const unsigned number_of_tracks_event = long_tracks.size();
  const unsigned event_offset = long_tracks.offset();

  constexpr float SQRT12 = 3.46410161f;
  for (unsigned track_idx = threadIdx.x; track_idx < number_of_tracks_event; track_idx += blockDim.x) {
    const auto scifi_idx_with_offset = track_idx + event_offset;
    // Select only tracks which passed isMuon
    if (parameters.dev_is_muon[scifi_idx_with_offset]) {

      const auto track = long_tracks.track(track_idx);
      const float momentum = 1 / fabsf(long_tracks.qop(track_idx));

      unsigned int dimension = 0;

      float cand_dx[4] = {0.f, 0.f, 0.f, 0.f};
      float cand_dy[4] = {0.f, 0.f, 0.f, 0.f};
      float cand_padx[4] = {0.f, 0.f, 0.f, 0.f};
      float cand_pady[4] = {0.f, 0.f, 0.f, 0.f};
      float cand_z[4] = {0.f, 0.f, 0.f, 0.f}; // z position of the stations

      // z position of the absorber
      float msz[5] {
        12800.f * Allen::Units::mm, // ECAL + SPD + PS
        14300.f * Allen::Units::mm, // HCAL
        15800.f * Allen::Units::mm, // M23 filter
        17100.f * Allen::Units::mm, // M34 filter
        18300.f * Allen::Units::mm  // M45 filter
      };

      // Radiation lenghts z/X0
      float msrl[5] {28., 53., 47.5, 47.5, 47.5};

      using segment = Allen::Views::Physics::Track::segment;
      const auto* muon_segment = track.track_segment_ptr<segment::muon>();
      const auto scifi_state = parameters.dev_scifi_states[scifi_idx_with_offset];
      MuonTrack muon_stub;
      if (muon_segment != nullptr) {
        dimension = momentum > 6000 ? muon_segment->number_of_ids() : 2;
      }

      for (unsigned i_muon_hit = 0; i_muon_hit < dimension; i_muon_hit++) {
        cand_padx[i_muon_hit] = muon_segment->hit(i_muon_hit).dx() / SQRT12;
        cand_pady[i_muon_hit] = muon_segment->hit(i_muon_hit).dy() / SQRT12;
        const float extrapolation_x =
          scifi_state.x() + scifi_state.tx() * (muon_segment->hit(i_muon_hit).z() - scifi_state.z());
        const float extrapolation_y =
          scifi_state.y() + scifi_state.ty() * (muon_segment->hit(i_muon_hit).z() - scifi_state.z());

        cand_dx[i_muon_hit] = muon_segment->hit(i_muon_hit).x() - extrapolation_x;
        cand_dy[i_muon_hit] = muon_segment->hit(i_muon_hit).y() - extrapolation_y;
        cand_z[i_muon_hit] = muon_segment->hit(i_muon_hit).z();
      }
      // Build covariance matrices
      float covX[4][4] = {{0.f, 0.f, 0.f, 0.f}, {0.f, 0.f, 0.f, 0.f}, {0.f, 0.f, 0.f, 0.f}, {0.f, 0.f, 0.f, 0.f}};

      float covY[4][4] = {{0.f, 0.f, 0.f, 0.f}, {0.f, 0.f, 0.f, 0.f}, {0.f, 0.f, 0.f, 0.f}, {0.f, 0.f, 0.f, 0.f}};

      float zj = 0;
      float zk = 0;

      // Covariance matrix in x and y (maybe call a function in device memory?)

      for (unsigned int j = 0; j < dimension; j++) {

        covX[j][j] += square(cand_padx[j]);
        covY[j][j] += square(cand_pady[j]);
        zj = cand_z[j];

        for (unsigned int k = 0; k < dimension; k++) {
          zk = cand_z[k];

          for (unsigned int i = 0; i < 5; i++) { // how to take the size of
            // the z of the absorber has to be smaller than the z of the hit station
            if (msz[i] < min(zj, zk)) {

              covX[j][k] += (zj - msz[i]) * (zk - msz[i]) * square((13.6f * Allen::Units::MeV) / momentum) * msrl[i];
              covY[j][k] += (zj - msz[i]) * (zk - msz[i]) * square((13.6f * Allen::Units::MeV) / momentum) * msrl[i];
            }
          } // end i
        }   // end k
      }     // end j

      // Inversion by hand in x and y (maybe call a function in device memory?)

      float invCovX[4][4] = {{0.f, 0.f, 0.f, 0.f}, {0.f, 0.f, 0.f, 0.f}, {0.f, 0.f, 0.f, 0.f}, {0.f, 0.f, 0.f, 0.f}};

      float invCovY[4][4] = {{0.f, 0.f, 0.f, 0.f}, {0.f, 0.f, 0.f, 0.f}, {0.f, 0.f, 0.f, 0.f}, {0.f, 0.f, 0.f, 0.f}};

      // We need invCovX and invCovY
      invert_matrix(covX, invCovX, dimension);
      invert_matrix(covY, invCovY, dimension);
      float chi2corr = 0;
      float chi2uncorr = 0;
      for (unsigned i = 0; i < dimension; ++i) {
        for (unsigned j = 0; j < i; ++j) {
          chi2corr += 2 * ((cand_dx[i] * invCovX[i][j] * cand_dx[j]) + (cand_dy[i] * invCovY[i][j] * cand_dy[j]));
        }
        chi2corr += square(cand_dx[i]) * invCovX[i][i] + square(cand_dy[i]) * invCovY[i][i];
        chi2uncorr += square(cand_dx[i] / cand_padx[i]) + square(cand_dy[i] / cand_pady[i]);
      }

      chi2corr = chi2corr / dimension;
      chi2uncorr = chi2uncorr / dimension;
      parameters.dev_chi2_muon[scifi_idx_with_offset] = log10f(chi2corr);
      parameters.dev_chi2uncorr_muon[scifi_idx_with_offset] = log10f(chi2uncorr);
    } // if is_muon
  }   // loop on tracks
} // end of global
