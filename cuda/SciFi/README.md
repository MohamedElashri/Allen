** Introduction to Forward Tracking **

  A detailed introduction in Forward tracking (with real pictures!) can be found here:

  (2002) http:cds.cern.ch/record/684710/files/lhcb-2002-008.pdf

  (2007) http:cds.cern.ch/record/1033584/files/lhcb-2007-015.pdf

  (2014) http:cds.cern.ch/record/1641927/files/LHCb-PUB-2014-001.pdf


 ** Short Introduction in geometry **

 The SciFi Tracker Detector, or simple Fibre Tracker (FT) consits out of 3 stations.
 Each station consists out of 4 planes/layers. Thus there are in total 12 layers,
 in which a particle can leave a hit. The reasonable maximum number of hits a track
 can have is thus also 12 (sometimes 2 hits per layer are picked up).

 Each layer consists out of several Fibre mats. A fibre has a diameter of below a mm.(FIXME)
 Several fibres are glued alongside each other to form a mat.
 A Scintilating Fibre produces light, if a particle traverses. This light is then
 detected on the outside of the Fibre mat.

 Looking from the collision point, one (X-)layer looks like the following:

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
 Sketch (rotation exagerated!):

                                          _.*
     y ^   _.*                         _.*
       | .*._      Upper side       _.*._
       |     *._                 _.*     *._
       |--------*._           _.*           *._----------------> x
       |           *._     _.*                 *._     _.*
                      *._.*       Lower side      *._.*





**Zone ordering**

     y ^
       |    1  3  5  7     9 11 13 15    17 19 21 23
       |    |  |  |  |     |  |  |  |     |  |  |  |
       |    x  u  v  x     x  u  v  x     x  u  v  x   <-- type of layer
       |    |  |  |  |     |  |  |  |     |  |  |  |
       |------------------------------------------------> z
       |    |  |  |  |     |  |  |  |     |  |  |  |
       |    |  |  |  |     |  |  |  |     |  |  |  |
       |    0  2  4  6     8 10 12 14    16 18 20 22


**Short introduction in the Forward Tracking algorithm**

 The track reconstruction is seperated into several steps:

 1) Using only X-hits

    1.1) Preselection: collectAllXHits()

    1.2) Hough Transformation: xAtRef_SamePlaneHits()

    1.3) Cluster search: selectXCandidates()

    1.4) Linear and than Cubic Fit of X-Projection

 2) Introducing U/V hits or also called stereo hits

    2.1) Preselection: collectStereoHits

    2.2) Cluster search: selectStereoHits

    2.3) Fit Y-Projection

 3) Using all (U+V+X) hits

    3.1) Fitting X-Projection

    3.2) calculating track quality with a Neural Net

    3.3) final clone+ghost killing
    
 **This description has been copied from the x86 PrForward code whose history is**

 Based on code written by :

 2012-03-20 : Olivier Callot

 2013-03-15 : Thomas Nikodem

 2015-02-13 : Sevda Esen (additional search in the triangles by Marian Stahl)

 2016-03-09 : Thomas Nikodem (complete restructuring)

 2018-08    : Vava Gligorov (extract code from Rec, make compile within GPU framework)
 
 2018-09    : Dorothea vom Bruch (convert to CUDA, runs on GPU)
