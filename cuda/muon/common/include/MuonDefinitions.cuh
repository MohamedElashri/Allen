#include "SystemOfUnits.h"
#pragma once

namespace Muon {
  namespace Constants {
    /* Detector description
       There are four stations with number of regions in it
       in current implementation regions are ignored
    */
    static constexpr uint n_stations            = 4;
    static constexpr uint n_regions             = 4;
    /* Cut-offs */
    static constexpr uint max_numhits_per_event = 400 * n_stations;

    static constexpr float SQRT3 = 1.7320508075688772;
    static constexpr float INVSQRT3 = 0.5773502691896258;
    // Multiple scattering factor 13.6 / (sqrt(6 * 17.58))
    static constexpr float MSFACTOR = 1.324200805763835;

    /*Muon Catboost model uses 5 features for each station: Delta time, Time, Crossed, X residual, Y residual*/
    static constexpr uint n_catboost_features   = 5 * n_stations;

    /* IsMuon constants */
    static constexpr float momentum_cuts[]      = {3 * Gaudi::Units::GeV, 6 * Gaudi::Units::GeV, 10 * Gaudi::Units::GeV};
    struct FieldOfInterest {
      /* FOI_x = a_x + b_x * exp(-c_x * p)
      *  FOI_y = a_y + b_y * exp(-c_y * p)
      */
      const float factor = 1.2;
      float param_a_x[Constants::n_stations][Constants::n_regions];
      float param_a_y[Constants::n_stations][Constants::n_regions];
      float param_b_x[Constants::n_stations][Constants::n_regions];
      float param_b_y[Constants::n_stations][Constants::n_regions];
      float param_c_x[Constants::n_stations][Constants::n_regions];
      float param_c_y[Constants::n_stations][Constants::n_regions];
    };
  }
  /* SoA for hit variables
    The hits for every layer are written behind each other, the offsets
    are stored for access;
    one Hits structure exists per event
  */
  struct HitsSoA {
    int number_of_hits_per_station[Constants::n_stations] = {0};
    int station_offsets[Constants::n_stations] = {0};
    int tile[Constants::max_numhits_per_event] = {0};
    float x[Constants::max_numhits_per_event] = {0};
    float dx[Constants::max_numhits_per_event] = {0};
    float y[Constants::max_numhits_per_event] = {0};
    float dy[Constants::max_numhits_per_event] = {0};
    float z[Constants::max_numhits_per_event] = {0};
    float dz[Constants::max_numhits_per_event] = {0};
    int uncrossed[Constants::max_numhits_per_event] = {0};
    unsigned int time[Constants::max_numhits_per_event] = {0};
    int delta_time[Constants::max_numhits_per_event] = {0};
    int cluster_size[Constants::max_numhits_per_event] = {0};
    int region_id[Constants::max_numhits_per_event] = {0};

    void addAtIndex(size_t index, int tile, float x, float dx, float y, float dy, float z, float dz,
         int uncrossed, unsigned int time, int delta_time, int cluster_size, int region) {
      this->tile[index] = tile;
      this->x[index] = x;
      this->dx[index] = dx;
      this->y[index] = y;
      this->dy[index] = dy;
      this->z[index] = z;
      this->dz[index] = dz;
      this->uncrossed[index] = uncrossed;
      this->time[index] = time;
      this->delta_time[index] = delta_time;
      this->cluster_size[index] = cluster_size;
      this->region_id[index] = region;
    }
  };
} // namespace Muon
