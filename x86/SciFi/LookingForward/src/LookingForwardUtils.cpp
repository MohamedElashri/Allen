#include "LookingForwardUtils.h"

// access hits from a layer
// first zone number: y < 0
// second zone number: y > 0
void get_offset_and_n_hits_for_layer(
  const int first_zone,
  const SciFi::HitCount& SciFi_hit_count,
  const float y,
  int& n_hits,
  int& zone_offset)
{
  assert(first_zone < SciFi::Constants::n_zones - 1);

  if (y < 0) {
    n_hits = SciFi_hit_count.zone_number_of_hits(first_zone);
    zone_offset = SciFi_hit_count.zone_offset(first_zone);
  }
  else {
    n_hits = SciFi_hit_count.zone_number_of_hits(first_zone + 1);
    zone_offset = SciFi_hit_count.zone_offset(first_zone + 1);
  }
}

// straight line extrapolation of MiniState to other z position
MiniState state_at_z(const MiniState& state, const float z)
{
  MiniState extrap_state;
  extrap_state.tx = state.tx;
  extrap_state.ty = state.ty;
  extrap_state.x = state.x + (z - state.z) * state.tx;
  extrap_state.y = state.y + (z - state.z) * state.ty;
  extrap_state.z = z;
  return extrap_state;
}

// straight line extrapolation of y to other z position
float y_at_z(const MiniState& state, const float z)
{
  float yf = state.y + (z - state.z) * state.ty;
  return yf;
}

float x_at_z(const MiniState& state, const float z)
{
  float xf = state.x + (z - state.z) * state.tx;
  return xf;
}

MiniState propagate_state_from_velo(const MiniState& UT_state, float qop, int layer)
{
  MiniState final_state;
  MiniState magnet_state;

  float x_mag_correction;

  float y_mag_correction;

  // center of the magnet
  magnet_state = state_at_z(UT_state, SciFi::LookingForward::zMagnetParams[0]);

  final_state = magnet_state;

  final_state.tx = SciFi::LookingForward::ds_p_param[layer] * qop + UT_state.tx;

  // TODO this could be done withoud brancing
  if (qop > 0) {
    y_mag_correction = SciFi::LookingForward::dp_y_mag_plus[layer][0] +
                       magnet_state.y * SciFi::LookingForward::dp_y_mag_plus[layer][1] +
                       magnet_state.y * magnet_state.y * SciFi::LookingForward::dp_y_mag_plus[layer][2] + 10;
    // SciFi::LookingForward::dp_plus_offset[layer];

    x_mag_correction =
      SciFi::LookingForward::dp_x_mag_plus[layer][0] + magnet_state.x * SciFi::LookingForward::dp_x_mag_plus[layer][1] +
      magnet_state.x * magnet_state.x * SciFi::LookingForward::dp_x_mag_plus[layer][2] +
      magnet_state.x * magnet_state.x * magnet_state.x * SciFi::LookingForward::dp_x_mag_plus[layer][3] +
      magnet_state.x * magnet_state.x * magnet_state.x * magnet_state.x *
        SciFi::LookingForward::dp_x_mag_plus[layer][4];
  }
  else {
    y_mag_correction = SciFi::LookingForward::dp_y_mag_minus[layer][0] +
                       magnet_state.y * SciFi::LookingForward::dp_y_mag_minus[layer][1] +
                       magnet_state.y * magnet_state.y * SciFi::LookingForward::dp_y_mag_minus[layer][2] - 10; //+
    // SciFi::LookingForward::dp_minus_offset[layer];

    x_mag_correction =
      SciFi::LookingForward::dp_x_mag_minus[layer][0] +
      magnet_state.x * SciFi::LookingForward::dp_x_mag_minus[layer][1] +
      magnet_state.x * magnet_state.x * SciFi::LookingForward::dp_x_mag_minus[layer][2] +
      magnet_state.x * magnet_state.x * magnet_state.x * SciFi::LookingForward::dp_x_mag_minus[layer][3] +
      magnet_state.x * magnet_state.x * magnet_state.x * magnet_state.x *
        SciFi::LookingForward::dp_x_mag_minus[layer][4];
  }
  final_state = state_at_z(final_state, SciFi::LookingForward::Zone_zPos[layer]);
  final_state.x += -y_mag_correction - x_mag_correction;

  return final_state;
}
