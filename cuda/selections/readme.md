
Adding selection lines
======================

This will cover how to add trigger lines to Allen that select events
based on reconstructed trigger candidates. Special lines (e.g. NoBias
or pass-through lines) should be handled on a case-by-case basis.

Writing the selection
---------------------

Trigger selections should be `__device__` functions that take either a
`const ParKalmanFilter::FittedTrack&` or a `const
VertexFit::TrackMVAVertex&` as an argument and return a `bool`. For
example, a line selecting high-pT tracks might look like:

```
__device__ bool HighPtTrack(const ParKalmanFilter::FittedTrack& track)
{
  return track.pt() > 10.0 / Gaudi::Units::GeV
}
```

The header file for the selection should be placed in
`cuda/selections/Hlt1/include` and the implementation should be placed
in `cuda/selections/Hlt1/src`.

Adding the line to the Allen sequence
-------------------------------------

Bookkeeping information for the Hlt1 lines is found in
`cuda/selections/Hlt1/include/LineInfo.cuh`. In order for a line
to run, it must be added to `Hlt1::Hlt1Lines` and a name must be added
to `Hlt1::Hlt1LineNames`. This will ensure that space is allocated to
store the selection decision for each candidate.

Special lines are listed first, followed by 1-track lines, then 2-,
3-, and finally 4-track lines. The new line should be added to the
appropriate place in the list. In addition, the number of lines of
that type should be incremented by 1. For example, the above
`HighPtTrack` line should be added after `// Begin 1-track lines.` and
before `Begin 2-track lines.` The line name should be added at the
same position in `Hlt1::Hlt1LineNames`.

Finally, add the selection function to the relevant array of pointers
to selections (e.g. `Hlt1::OneTrackSelections` or
`Hlt1::TwoTrackSelections`). These must be in the same order as in
`Hlt1::Hlt1LineNames` and `Hlt1::Hlt1Lines`.
