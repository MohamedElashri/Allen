#include "LookingForwardUtils.h"

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
