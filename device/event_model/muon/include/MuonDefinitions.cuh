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

#include "SystemOfUnits.h"
#include "States.cuh"

namespace Muon {

  static constexpr size_t batches_per_bank = 4;

  namespace Constants {
    /* Detector description
       There are four stations with number of regions in it
       in current implementation regions are ignored
    */
    static constexpr unsigned n_stations = 4;
    static constexpr unsigned n_regions = 4;
    static constexpr unsigned n_quarters = 4;
    static constexpr int M2 {0}, M3 {1}, M4 {2}, M5 {3};

    // v3 geometry
    static constexpr unsigned maxTell40Number = 22;
    static constexpr unsigned int maxTell40PCINumber = 2;
    static constexpr unsigned int maxNumberLinks = 24;
    static constexpr unsigned int ODEFrameSize = 48;

    // MuonID NN
    static constexpr unsigned n_muon_id_features = 5;

    __host__ __device__ inline std::array<uint8_t, 8> single_bit_position()
    {
      return {0x80, 0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01};
    }

    /* Cut-offs */
    static constexpr unsigned max_numhits_per_event = 600 * n_stations;
    static constexpr unsigned max_hits_per_track = 4;

    static constexpr float SQRT3 = 1.7320508075688772;
    static constexpr float INVSQRT3 = 0.5773502691896258;
    // Multiple scattering factor 13.6 / (sqrt(6 * 17.58))
    static constexpr float MSFACTOR = 1.324200805763835;

    /*Muon Catboost model uses 5 features for each station: Delta time, Time, Crossed, X residual, Y residual*/
    static constexpr unsigned n_catboost_features = 5 * n_stations;

    // Number of layouts
    static constexpr unsigned n_layouts = 2;

    /* IsMuon constants */
    namespace FoiParams {
      static constexpr unsigned n_parameters = 3;
      static constexpr unsigned a = 0;
      static constexpr unsigned b = 1;
      static constexpr unsigned c = 2;

      static constexpr unsigned n_coordinates = 2;
      static constexpr unsigned x = 0;
      static constexpr unsigned y = 1;
    } // namespace FoiParams

    static constexpr float momentum_cuts[] = {3 * Allen::Units::GeV, 6 * Allen::Units::GeV, 10 * Allen::Units::GeV};
    struct FieldOfInterest {
    private:
      /* FOI_x = a_x + b_x * exp(-c_x * p)
       *  FOI_y = a_y + b_y * exp(-c_y * p)
       */
      float m_factor = 1.2f;
      float m_params[Constants::n_stations * FoiParams::n_parameters * FoiParams::n_coordinates * Constants::n_regions];

    public:
      __host__ __device__ float factor() const { return m_factor; }

      __host__ __device__ void set_factor(const float factor) { m_factor = factor; }

      __host__ __device__ float
      param(const unsigned param, const unsigned coord, const unsigned station, const unsigned region) const
      {
        return m_params
          [station * FoiParams::n_parameters * FoiParams::n_coordinates * Constants::n_regions +
           param * FoiParams::n_coordinates * Constants::n_regions + coord * Constants::n_regions + region];
      }

      __host__ __device__ void set_param(
        const unsigned param,
        const unsigned coord,
        const unsigned station,
        const unsigned region,
        const float value)
      {
        m_params
          [station * FoiParams::n_parameters * FoiParams::n_coordinates * Constants::n_regions +
           param * FoiParams::n_coordinates * Constants::n_regions + coord * Constants::n_regions + region] = value;
      }

      __host__ __device__ float* params_begin() { return reinterpret_cast<float*>(m_params); }

      __host__ __device__ const float* params_begin_const() const { return reinterpret_cast<const float*>(m_params); }
    };
    struct MatchWindows {
      float Xmax[16] = {
        //   R1  R2   R3   R4
        100.,
        200.,
        300.,
        400., // M2
        100.,
        200.,
        300.,
        400., // M3
        400.,
        400.,
        400.,
        400., // M4
        400.,
        400.,
        400.,
        400.}; // M5

      float Ymax[16] = {
        //  R1   R2   R3   R4
        60.,
        120.,
        180.,
        240., // M2
        60.,
        120.,
        240.,
        240., // M3
        60.,
        120.,
        240.,
        480., // M4
        60.,
        120.,
        240.,
        480., // M5

      };

      float z_station[4] {15205.f, 16400.f, 17700.f, 18850.f};
    };
    static constexpr unsigned max_number_of_tracks = 2000;
  } // namespace Constants
} // namespace Muon
