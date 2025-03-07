HLT1 Reconstruction algorithms
======================================

Velo clusters
^^^^^^^^^^^^^^^^^^^

Format needed by one RawEvent for masked clustering code::

 -----------------------------------------------------------------------------
 name                |  type    |  size                 | array_size
 =============================================================================
 number_of_rawbanks  | uint32_t | 1
 -----------------------------------------------------------------------------
 raw_bank_offset     | uint32_t | number_of_rawbanks
 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 sensor_index        | uint32_t | 1                     |
 ------------------------------------------------------------------------------
 count               | uint32_t | 1                     | number_of_rawbanks
 ------------------------------------------------------------------------------
 word                | uint32_t | count                 |
 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++x

raw_bank_offset: array containing the offsets to each raw bank, this array is 
currently filled when running Brunel to create this output; it is needed to process
several raw banks in parallel

sp = super pixel

word: contains super pixel address and 8 bit hit pattern


Velo tracks
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


Primary vertices
^^^^^^^^^^^^^^^^^^^

Velo-UT tracks
^^^^^^^^^^^^^^^^^^^^^

To configure the number of candidates to search for go to `CompassUTDefinitions.cuh` and change: 

.. code-block:: cpp

  constexpr unsigned max_considered_before_found = 4;

A higher number considers more candidates but takes more time. It saves the best found candidate.

Standalone UT tracks
^^^^^^^^^^^^^^^^^^^^^^

Standalone SciFi tracks (seeding)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Short Introduction in geometry
----------------------------------
The SciFi Tracker Detector, or simple Fibre Tracker (FT) consits out of 3 stations.
Each station consists out of 4 planes/layers. Thus there are in total 12 layers,
in which a particle can leave a hit. The reasonable maximum number of hits a track
can have is thus also 12 (sometimes 2 hits per layer are picked up).

Each layer consists out of several Fibre mats. A fibre has a diameter of below a mm.(FIXME)
Several fibres are glued alongside each other to form a mat.
A Scintilating Fibre produces light, if a particle traverses. This light is then
detected on the outside of the Fibre mat.

Looking from the collision point, one (X-)layer looks like the following::

   y       6m
   ^  ||||||||||||| Upper side
   |  ||||||||||||| 2.5m
   |  |||||||||||||
  -|--||||||o||||||----> -x
      |||||||||||||
      ||||||||||||| Lower side
      ||||||||||||| 2.5m

All fibres are aranged parallel to the y-axis. There are three different
kinds of layers, denoted by X,U,V. The U/V layers are rotated with respect to
the X-layers by +/- 5 degrees, to also get a handle of the y position of the
particle. As due to the magnetic field particles are only deflected in
x-direction, this configuration offers the best resolution.
The layer structure in the FT is XUVX-XUVX-XUVX.

The detector is divided into an upeer and a lower side (>/< y=0). As particles
are only deflected in x direction there are only very(!) few particles that go
from the lower to the upper side, or vice versa. The reconstruction algorithm
can therefore be split into two independent steps: First track reconstruction
for tracks in the upper side, and afterwards for tracks in the lower side.

Due to construction issues this is NOT true for U/V layers. In these layers the
complete(!) fibre modules are rotated, producing a zic-zac pattern at y=0, also
called  "the triangles". Therefore for U/V layers it must be explicetly also
searched for these hit on the "other side", if the track is close to y=0.
Sketch (rotation exagerated!)::

                                            _.*
       y ^   _.*                         _.*
         | .*._      Upper side       _.*._
         |     *._                 _.*     *._
         |--------*._           _.*           *._----------------> x
         |           *._     _.*                 *._     _.*
                        *._.*       Lower side      *._.*

Zone ordering::

     y ^
       |    1  3  5  7     9 11 13 15    17 19 21 23
       |    |  |  |  |     |  |  |  |     |  |  |  |
       |    x  u  v  x     x  u  v  x     x  u  v  x   <-- type of layer
       |    |  |  |  |     |  |  |  |     |  |  |  |
       |------------------------------------------------> z
       |    |  |  |  |     |  |  |  |     |  |  |  |
       |    |  |  |  |     |  |  |  |     |  |  |  |
       |    0  2  4  6     8 10 12 14    16 18 20 22



Velo-UT-SciFi tracks
^^^^^^^^^^^^^^^^^^^^^^^^^

With Looking forward algorithm
--------------------------------------

A detailed introduction in Forward tracking (with real pictures!) can be found here:

* 2002: `<http://cds.cern.ch/record/684710/files/lhcb-2002-008.pdf>`_
* 2007: `<http://cds.cern.ch/record/1033584/files/lhcb-2007-015.pdf>`_
* 2014: `<http://cds.cern.ch/record/1641927/files/LHCb-PUB-2014-001.pdf>`_

With Seeding algorithms
------------------------

Kalman filter
^^^^^^^^^^^^^^^
There are two main points in the reconstruction, where a Kalman filter is used to
estimate particle states. Particle states are defined by the vector (x,y,tx,ty,qop),
where tx and ty are the slope in that direction, and qop is the charge over momentum. This is a
convenient definition for calculating trajectories of charged particles in a magnetic field.

1. After the reconstruction of the Velo tracks a simplified Kalman filter is used.
The fit starts by getting a first estimate for the state from a linear fit between 
first and last hit.
The Kalman filter is executed twice, to get a state at the beamline (closest to the beamline) and one at the
end of the Velo(z=770mm). The scattering noise model is linear in tr**2. The x and y components
are treated independently.
For code see device/velo/simplified_kalman_filter
2. After the long track reconstruction, another Kalman filter is used to produce
the state that will be used in the secondary vertex reconstruction, this can include 
improved momentum resolution.

There are two implementations, the Velo-only and the parameterised Kalman filter version:
a. Simplified velo-only is the version used for all data taking up to EoY 2024 (at least). 
(device/kalman/ParKalman/src/ParKalmanVeloOnly.cu), here the 'simplified_fit' function
is used. This function uses similar simplifications as the filter above, but 
includes a more involved noise function, that includes the momentum and charge information
from long tracking, the RF foil and more parameters (see Rec/Tr/TrackFitEvent/include/Event/ParametrisedScatters.h).
In addition to the state, a chi2 is also produced that can be used to cut on in the SV creation.
b. Parameterised Kalman filter (parKF). This is based on (`<https://cds.cern.ch/record/2759269/files/2101.12040.pdf>`_).
Here the full track is fitted, based on several parameterisations. This includes a rather involved treatment of the propagation
of charged particles in the magnetic field. This KF is more computationally expensive but yields
improvement in momentum resolution, ghost rejection, mass resolution and SV reconstruction.
In its current implementation, the following steps are performed:
- An initial state is created from the first and last Velo hit at the position of the first hit.
- The parKF runs over the remaining Velo hits in the forward direction. A state is saved at the position of the last hit.
- Extrapolation V -> UT, start at this point we create a transport matrix F by multiplying up the Jacobians of each extrapolation.
- Extrapolation in UT, updates at every state, if there is a hit. In a no_ut configuration, the algorithm still stops at every
  UT layer and adds noise.
- UT -> T extrapolation through the magnetic field using a large parametrisation.
- Extrapolation in T, updates at every state, if there is a hit.
- At the last hit we invert the transport matrix F and use F^-1 to transport the covariance matrix C back to the state at the end of VELO.
- We revert to the state saved at this point in the forward pass but substitute the improved qop estimate.
- We let the filter run backward over all velo hits. The state produced at the lowest z will be used as the state closest
  to the beamline for calculating the impact parameter and creating secondary vertices.
TODO: add links to repo with parametrisation creation

Muon ID
^^^^^^^^^^^

ECal information
^^^^^^^^^^^^^^^^^^

Electron ID
^^^^^^^^^^^^^

Secondary vertices
^^^^^^^^^^^^^^^^^^^^^

