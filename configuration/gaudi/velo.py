from VeloSequence import make_velo_tracks

velo_tracks = make_velo_tracks()
velo_tracks["dev_velo_track_hits"].producer.configuration().apply()
