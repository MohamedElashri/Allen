from ForwardSequence import make_forward_tracks

forward_tracks = make_forward_tracks()
forward_tracks["dev_scifi_track_hits"].producer().configuration().apply()
