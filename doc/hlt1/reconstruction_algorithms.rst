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

Muon ID
^^^^^^^^^^^

ECal information
^^^^^^^^^^^^^^^^^^

Electron ID
^^^^^^^^^^^^^

Secondary vertices
^^^^^^^^^^^^^^^^^^^^^

