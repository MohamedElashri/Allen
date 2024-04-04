.. _combiners:

Particle combiners in Allen
===========================
Particle combiners are algorithms that combine `BasicParticle`s,
`NeutralBasicParticle`, and `CompositeParticle`s to create `CompositeParticle`s.
Generally, the combiners perform a filtering step on the input particles, count
the combinations, and create `CompositeParticle` views containing the resulting
combinations. There are a few combiners currently implemented in Allen:

`Two-track combiner <https://gitlab.cern.ch/lhcb/Allen/-/blob/master/device/vertex_fit/vertex_fitter/src/VertexFitter.cu>`_
---------------------------------------------------------------------------------------------------------------------------
The two-track combiner combines pairs of long tracks to create secondary
vertices. The two-track combiner also performs a vertex fit, which determines a
position covariance matrix for the combination. The two-track combiner is
configured in `configuration/python/AllenConf/secondary_vertex_reconstruction.py
<https://gitlab.cern.ch/lhcb/Allen/-/blob/master/configuration/python/AllenConf/secondary_vertex_reconstruction.py>`_.
The properties and default values for the prefilter are:

.. code-block:: python

    track_min_pt_both=200. # Minimum track pT.
    track_min_pt_either=200. # Minimum pT that must be satisfied by at least one track.
    track_min_ipchi2_both=4. # Minimum track IP chi2.
    track_min_ipchi2_either=4. # Minimum IP chi2 that must be satisfied by at least one track.
    track_min_ip_both=0.06 # Minimum track IP.
    track_min_ip_either=0.06 # Minimum IP that must be satisfied by at least one track.
    track_max_chi2ndof=10.0 # Maximum track fit chi2/ndf from a fit of the VELO segment only.
    max_doca=1. # Maximum distance of closest approach of the two tracks.
    min_sum_pt=400. # Minimum sum(pT) of the constituent tracks.
    require_os_pair=False # Are the tracks required to have opposite charge?
    require_same_pv=True # Are the tracks required to be associated to the same PV?
    require_muon=False # Are the tracks required to satisfy IsMuon?
    require_electron=False # Are the tracks required to be identified as electrons?
    require_lepton=False # Are the tracks required to be identified as muons or electrons?
    max_assoc_ipchi2=16. # The maximum value of IP chi2 for which the same-PV requirement is enforced.

In the default allen sequence, the two-track combiner is used to create dihadron
and dilepton containers. The dihadron tracks must be displaced, while the
dilepton tracks have not displacement requirements but must be identified as
electrons or muons.

`Two-photon combiner <https://gitlab.cern.ch/lhcb/Allen/-/blob/master/device/calo/clustering/src/CaloFindTwoClusters.cu>_`
--------------------------------------------------------------------------------------------------------------------------
The two-photon combiner creates diphoton `CompositeParticle`s from pairs of
`NeutralBasicParticle`s. Unlike the two-track combiner, no vertex fit is
performed. The two-photon combiner is configured in
`configuration/python/AllenConf/calo_reconstruction.py
<https://gitlab.cern.ch/lhcb/Allen/-/blob/master/configuration/python/AllenConf/calo_reconstruction.py?ref_type=heads#L150>`_.
The arguments of `make_ecal_clusters` that are passed to the prefilter are:

.. code-block:: python

    min_et=400 # Minimum ET of calo clusters used in combinations.
    min_e19=0.6 # Minimum E19 of calo clusters used in combinations.

In the default Allen sequence, only one container of diphotons is created.

`Track+SV combiner <https://gitlab.cern.ch/lhcb/Allen/-/blob/master/device/vertex_fit/vertex_fitter/src/CombineSVTrack.cu>`_
----------------------------------------------------------------------------------------------------------------------------
The Track+SV combiner combines a `BasicParticle` with a `CompositeParticle` to
create a track+SV `CompositeParticle`. For now, the SV must be a two-track
secondary vertex, but this requirement will be relaxed in the future to allow
for more general combinations. No vertex fit is performed, so no covariance
matrix is available for these combinations. This combiner is configured in
`configuration/python/AllenConf/secondary_vertex_reconstruction.py L267
<https://gitlab.cern.ch/lhcb/Allen/-/blob/master/configuration/python/AllenConf/secondary_vertex_reconstruction.py?ref_type=heads#L267>`_.
The first argument of `make_sv_track_pairs` is the
`MultiEventCompositeParticles` view containing the input SVs, and the second
argument is the `MultiEventBasicParticles` view containing the tracks. The
configurable parameters of the prefilter are:

.. code-block:: python

    min_track_ipchi2=4. # Minimum track IP chi2.
    max_track_ipchi2=1e16 # Maximum track IP chi2.
    min_track_ip=0.6 # Minimum track IP.
    max_track_ip=1e16 # Maximum track IP.
    sv_bpvvdz_min=12. # Minimum distance between the SV and the PV along the z axis.
    sv_bpvvdrho_min=2. # Minimum transverse distance between the SV and the PV.
    sv_vz_min=-80. # Minimum z position of the SV.
    sv_vz_max=650. # Maximum z position of the SV.
    opening_angle_min=0.5e-3 # Minimum opening angle between the track and the SV child tracks.

In the default Allen sequence, the track+SV combiner is used to combine
displaced SVs with displaced tracks to form hyperon candidates. It is also used
to combine displaced SVs with prompt tracks to form D* candidates.

`SV+SV combiner <https://gitlab.cern.ch/lhcb/Allen/-/blob/master/device/combiners/src/SVCombiner.cu>`_
------------------------------------------------------------------------------------------------------
The SV+SV combiner is used to create pairs of displaced vertices. The combiner
is configured in
`configuration/python/AllenConf/secondary_vertex_reconstruction.py L215
<https://gitlab.cern.ch/lhcb/Allen/-/blob/master/configuration/python/AllenConf/secondary_vertex_reconstruction.py?ref_type=heads#L215>`_.
There are currently no configurable parameters for the prefilter, but this will
change in the future. This combiner is used in the default sequence to create
K0s pairs.
