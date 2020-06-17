#pragma once

#include "SystemOfUnits.h"
#include "SciFiDefinitions.cuh"

#include <cstdint>

namespace LookingForward {
  // Enum only used for initial window search
  enum layer_bits {
    bit_layer0 = 0x01,
    bit_layer3 = 0x02,
    bit_layer4 = 0x04,
    bit_layer7 = 0x08,
    bit_layer8 = 0x10,
    bit_layer11 = 0x20,
    bit_layer1 = 0x0100,
    bit_layer2 = 0x0200,
    bit_layer5 = 0x0400,
    bit_layer6 = 0x0800,
    bit_layer9 = 0x1000,
    bit_layer10 = 0x2000
  };

  // Reference z plane
  constexpr float z_mid_t = 8520.f * Gaudi::Units::mm; // FIXME_GEOMETRY_HARDCODING

  // ==================================
  // Constants for lf search by triplet
  // ==================================
  constexpr int number_of_x_layers = 6;
  constexpr int number_of_uv_layers = 6;

  // Number of ints per track in initial window (xbegin, xend, uvbegin, uvend == 4)
  constexpr int number_of_elements_initial_window = 4;

  // Chi2 cuts for triplet of three x hits and when extending to other x and uv layers
  constexpr float chi2_max_triplet_single = 8.f;
  constexpr float chi2_max_extrapolation_to_x_layers_single = 2.f;

  // Maximum number of hits in window
  constexpr int max_number_of_hits_in_window = 32;
  constexpr int triplet_seeding_block_dim_x = 32;

  constexpr int n_triplet_seeds = 2;
  constexpr int maximum_number_of_triplets_per_thread = 8;
  constexpr int maximum_number_of_candidates_per_ut_track = 12;

  constexpr int track_min_hits = 9;
  constexpr float quality_filter_max_quality = 0.5f;
  constexpr float range_y_fit_end = 800.f;
  constexpr int num_atomics = 1;

  // z at the center of the magnet
  constexpr float z_magnet = 5212.38f; // FIXME_GEOMETRY_HARDCODING
  constexpr float z_last_UT_plane = 2642.f; // FIXME_GEOMETRY_HARDCODING

  // z difference between reference plane and end of SciFi
  constexpr float zReferenceEndTDiff = SciFi::Constants::ZEndT - z_mid_t;

  // ======================================
  // Constants for various parametrizations
  // ======================================

  // qop update parametrization
  constexpr float qop_p0 = -2.1156e-07f;
  constexpr float qop_p1 = 0.000829677f;
  constexpr float qop_p2 = -0.000174757f;

  // x at z parametrization
  constexpr float x_at_z_p0 = -0.819493;
  constexpr float x_at_z_p1 = 19.3897;
  constexpr float x_at_z_p2 = 16.6874;
  constexpr float x_at_z_p3 = -375.478;

  // d_ratio correction as in the seeding algorithm
  constexpr float d_ratio_par_0 = 0.000267957f;
  constexpr float d_ratio_par_1 = -8.651e-06f;
  constexpr float d_ratio_par_2 = 4.60324e-05f;

  // Sign check momentum threshold
  constexpr float sign_check_momentum_threshold = 5000.f;

  // Linear range qop setup
  constexpr float linear_range_qop_end = 0.0005f;
  constexpr float x_at_magnet_range_0 = 8.f;
  constexpr float x_at_magnet_range_1 = 40.f;

  // Parametrization of expected x1 in triplet formation
  constexpr float sagitta_alignment_x1_triplet0 = 1.00177513f;
  constexpr float sagitta_alignment_x1_triplet1 = 1.00142634f;

  // Windows
  constexpr int min_hits_or_ty_window = 11;
  constexpr float max_diff_ty_window = 0.02f;

  // Quality multipliers
  constexpr float track_9_hits_quality_multiplier = 5.f;
  constexpr float track_10_hits_quality_multiplier = 1.f;
  constexpr float track_11_hits_quality_multiplier = 0.8f;
  constexpr float track_12_hits_quality_multiplier = 0.5f;

  // Initial search windows parameters
  constexpr float initial_window_offset_xtol = 150.f;
  constexpr float initial_window_factor_qop = 2e6f;
  constexpr float initial_window_factor_assymmetric_opening = 100.f;
  constexpr float initial_windows_max_offset_uv_window = 800.f;

  struct Constants {
    int xZones[12] {0, 6, 8, 14, 16, 22, 1, 7, 9, 15, 17, 23};
    int uvZones[12] {2, 4, 10, 12, 18, 20, 3, 5, 11, 13, 19, 21};

    float
      Zone_zPos[12] {7826.f, 7896.f, 7966.f, 8036.f, 8508.f, 8578.f, 8648.f, 8718.f, 9193.f, 9263.f, 9333.f, 9403.f};
    float Zone_zPos_xlayers[6] {7826.f, 8036.f, 8508.f, 8718.f, 9193.f, 9403.f};
    float Zone_zPos_uvlayers[6] {7896.f, 7966.f, 8578.f, 8648.f, 9263.f, 9333.f};
    float zMagnetParams[4] {5212.38f, 406.609f, -1102.35f, -498.039f};
    float Zone_dxdy[4] {0.f, 0.0874892f, -0.0874892f, 0.f};
    float Zone_dxdy_uvlayers[2] {0.0874892f, -0.0874892f};

    /*=====================================
    Constant arrays for search by triplet
    ======================================*/

    // Triplet creation
    // Note: In the code there are several assumptions associated with these set of triplets:
    // * In the initial window search, where a track will only be processed if it has at least one candidate
    //   in {0, 2, 4} or {1, 3, 5}.
    // * In the triplet creation, the constants sagitta_alignment_x1_triplet0 and sagitta_alignment_x1_triplet1
    //   were created assuming triplets in X layers {0, 2, 4} and {1, 3, 5} respectively.
    // * In the extension of tracks to other X layers, hits 0, 1 and 2 are expected to
    //   be from T1, T2 and T3 respectively.
    // * Hit 0 and hit 2 of the track are expected to be a T1 and T3 hit,
    //   in the calculation of QualityFilter.cu of the updated qop.
    unsigned triplet_seeding_layers[n_triplet_seeds][3] {{0, 2, 4}, {1, 3, 5}};

    // Extrapolation to UV
    unsigned x_layers[6] {0, 3, 4, 7, 8, 11};
    unsigned extrapolation_uv_layers[6] {1, 2, 5, 6, 9, 10};
    unsigned reverse_layers[12] {0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5};

    // momentum Parametrization
    float momentumParams[6] = {1.21014f, 0.637339f, -0.200292f, 0.632298f, 3.23793f, -27.0259f};

    // Parametrization for calculation of initial search window
    float ds_multi_param[3 * 5 * 5] {
      1.17058336e+03f,  0.00000000e+00f, 6.39200125e+03f,  0.00000000e+00f,  -1.45707998e+05f,
      0.00000000e+00f,  0.00000000e+00f, 0.00000000e+00f,  0.00000000e+00f,  0.00000000e+00f,
      7.35087335e+03f,  0.00000000e+00f, -3.23044958e+05f, 0.00000000e+00f,  6.70953953e+06f,
      0.00000000e+00f,  0.00000000e+00f, 0.00000000e+00f,  0.00000000e+00f,  0.00000000e+00f,
      -3.32975119e+04f, 0.00000000e+00f, 0.00000000e+00f,  0.00000000e+00f,  0.00000000e+00f,

      1.21404549e+03f,  0.00000000e+00f, 6.39849243e+03f,  0.00000000e+00f,  -1.48282139e+05f,
      0.00000000e+00f,  0.00000000e+00f, 0.00000000e+00f,  0.00000000e+00f,  0.00000000e+00f,
      7.06915986e+03f,  0.00000000e+00f, -2.39992852e+05f, 0.00000000e+00f,  4.48409294e+06f,
      0.00000000e+00f,  3.21303132e+04f, 0.00000000e+00f,  -1.77557653e+06f, 0.00000000e+00f,
      -4.05086623e+04f, 0.00000000e+00f, 0.00000000e+00f,  0.00000000e+00f,  0.00000000e+00f,

      1.23813318e+03f,  0.00000000e+00f, 6.68779400e+03f,  0.00000000e+00f,  -1.51815852e+05f,
      0.00000000e+00f,  0.00000000e+00f, 0.00000000e+00f,  0.00000000e+00f,  0.00000000e+00f,
      6.72420095e+03f,  0.00000000e+00f, -3.25320622e+05f, 0.00000000e+00f,  6.32694612e+06f,
      0.00000000e+00f,  0.00000000e+00f, 0.00000000e+00f,  0.00000000e+00f,  0.00000000e+00f,
      -4.04562789e+04f, 0.00000000e+00f, 0.00000000e+00f,  0.00000000e+00f,  0.00000000e+00f};

    // Parametrization to extrapolate to UV layers
    float parametrization_layers[12 * 18] {
      2.3116041493668926f,      7.477938717159352f,       -7.071014828759516f,      -26.292581801152824f,
      -236.94656520755095f,     35.06881797141721f,       6.491665698088342e-05f,   8.389582979855681e-05f,
      -0.002233240476746105f,   -0.008615250517727664f,   -0.008840044630432257f,   0.011766804466546507f,
      -1.9220860744328974e-07f, -2.1411361185376335e-06f, 7.256658342250302e-06f,   -1.7861626019546253e-06f,
      6.085826424532421e-05f,   -0.00011105413272452379f, 2.2846023099082693f,      7.595388900378003f,
      -7.3677923539943f,        -26.385955504267272f,     -238.30698783166864f,     38.13964496896642f,
      5.892149532287553e-05f,   0.00010778824991912808f,  -0.002217116544014302f,   -0.008353446592995821f,
      -0.008867273870936263f,   0.011678099292054898f,    -1.8319314410280104e-07f, -2.032702259392156e-06f,
      6.967106233768601e-06f,   -1.865155152150757e-06f,  5.88279719924671e-05f,    -0.00010742220550217046f,
      2.2582018905726806f,      7.716181841225789f,       -7.644937105985349f,      -26.482856277193314f,
      -239.6387916776465f,      41.07053322370586f,       5.3232294148975774e-05f,  0.0001320724445740056f,
      -0.002199961929951024f,   -0.008101543022496781f,   -0.00889155950051415f,    0.011597614413701877f,
      -1.7431703530641373e-07f, -1.9330611958774454e-06f, 6.6848792609231845e-06f,  -1.916791951919106e-06f,
      5.6874192464041494e-05f,  -0.00010380652164508676f, 2.232394072100071f,       7.840663889858144f,
      -7.902929544192372f,      -26.591670710194588f,     -240.94420564278056f,     43.85838743574159f,
      4.783728369036442e-05f,   0.00015673555628245846f,  -0.0021817639284124613f,  -0.007861853075622103f,
      -0.008914179607725954f,   0.011523170488115773f,    -1.6559550857645588e-07f, -1.8420643766500866e-06f,
      6.410900514821867e-06f,   -1.9427734817816997e-06f, 5.499597340827766e-05f,   -0.00010023472016885852f,
      2.073678743926001f,       8.771777821458453f,       -9.196217935825745f,      -27.939010593472794f,
      -249.33982798974364f,     58.90519751947382f,       1.8258507403497694e-05f,  0.00032852997852593474f,
      -0.0020323443501805583f,  -0.006641411730120575f,   -0.00914330450883645f,    0.0109958748536746f,
      -1.1213330489533724e-07f, -1.420275182870557e-06f,  4.810613352964737e-06f,   -1.6418264176564915e-06f,
      4.4145802931631385e-05f,  -7.859708463727604e-05f,  2.0524199478120786f,      8.91933269932863f,
      -9.332103498837387f,      -28.233485573240117f,     -250.5560927593662f,      60.62144041490461f,
      1.4761083910018904e-05f,  0.00035357210822784023f,  -0.0020071092617613864f,  -0.006516585908659302f,
      -0.0091958380025257f,     0.01089930187474053f,     -1.0516074301601381e-07f, -1.3799279445837394e-06f,
      4.6099573411969064e-06f,  -1.5535242255413198e-06f, 4.2783699964573865e-05f,  -7.583168109320438e-05f,
      2.031755838232589f,       9.067741191113099f,       -9.456609240962283f,      -28.546620483840954f,
      -251.76643526922487f,     62.223996030884166f,      1.146514797442648e-05f,   0.0003781101935683316f,
      -0.0019814397809892336f,  -0.006403338181178914f,   -0.00925198222756464f,    0.010797342027081977f,
      -9.846708581834325e-08f,  -1.3436748206997789e-06f, 4.418257366089931e-06f,   -1.4595963188483018e-06f,
      4.1479290948958015e-05f,  -7.318330215630851e-05f,  2.011684536821598f,       9.216451966698699f,
      -9.570728167848507f,      -28.87562345401416f,      -252.9695484313157f,      63.72020714160561f,
      8.361569756681201e-06f,   0.00040202449376094946f,  -0.0019554694022485626f,  -0.006300415920362937f,
      -0.009310649609633638f,   0.010690493279911312f,    -9.205685182809783e-08f,  -1.3110205435411045e-06f,
      4.235217607793918e-06f,   -1.3615507676389638e-06f, 4.0230455998931526e-05f,  -7.06486953772513e-05f,
      1.890823906371196f,       10.196126928875126f,      -10.140152019474726f,     -31.302307791256403f,
      -260.8247084515475f,      71.62371069221945f,       -8.285366065104762e-06f,  0.0005416812096643241f,
      -0.0017797228004772553f,  -0.0057864123077828525f,  -0.009707000416552758f,   0.009884588111799111f,
      -5.6030112418665994e-08f, -1.152488762279404e-06f,  3.198720055070513e-06f,   -6.802952792339729e-07f,
      3.304396432070035e-05f,   -5.614728230743824e-05f,  1.8751884455480388f,      10.33176612651087f,
      -10.20243801326319f,      -31.658853567449988f,     -261.9212410111918f,      72.53148427671823f,
      -1.0179566935871457e-05f, 0.0005583978934098456f,   -0.0017548705138806563f,  -0.0057267033139851015f,
      -0.009757560012686892f,   0.009761350678314885f,    -5.177100332877564e-08f,  -1.1347687233547254e-06f,
      3.0726138177730553e-06f,  -5.87100227215951e-07f,   3.214911162836671e-05f,   -5.4357606647698515e-05f,
      1.8600804667446018f,      10.464367130006536f,      -10.260947515545546f,     -32.009582359196294f,
      -262.99791932219574f,     73.38954068077197f,       -1.1951949022478286e-05f, 0.0005740752413087831f,
      -0.0017304571067590247f,  -0.005669093328838734f,   -0.009804594655988028f,   0.00963855329109023f,
      -4.776020180056464e-08f,  -1.1178219798302718e-06f, 2.9524806941765866e-06f,  -4.974345906926891e-07f,
      3.129021524603281e-05f,   -5.2644866415865965e-05f, 1.8454847180677074f,      10.593811540940969f,
      -10.316097890465073f,     -32.35354095320006f,      -264.05389253463716f,     74.20197188948043f,
      -1.3609385204610991e-05f, 0.0005887263090984317f,   -0.0017065138289468623f,  -0.005613186149118024f,
      -0.009847804419237063f,   0.009516570631526139f,    -4.398746296434176e-08f,  -1.101513063243898e-06f,
      2.838027843453555e-06f,   -4.1156107971717894e-07f, 3.046547526241723e-05f,   -5.100512203279434e-05f};
  };
} // namespace LookingForward
