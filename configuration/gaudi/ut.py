from UTSequence import make_ut_tracks

ut_tracks = make_ut_tracks()
ut_tracks["dev_ut_track_hits"].producer().configuration().apply()
