Contracts
=========

* Be sure to check out [this presentation](https://indico.cern.ch/event/978570/contributions/4136202/attachments/2157046/3638389/main.pdf) which covers what is in this readme and more.

How to add contracts
--------------------

In order to define a contract, you should give it a name and decide whether it is a Precondition or Postcondition (executed before / after an operator() of an algorithm). The syntax is as follows:

```c++
// Define a precondition
struct contract_name : public Allen::contract::[Precondition|Postcondition] {
  void operator()(
    // Note: Relevant inputs for Allen algorithms:
    const ArgumentReferences<Parameters>&,
    const RuntimeOptions&,
    const Constants&,
    const Allen::Context&) const
  {
    bool condition1 = true;
    bool condition2 = true;
    // Your code that checks something and overwrites condition1 and condition2
    ...
    require(condition1, "Description of condition1");
    require(condition2, "Description of condition2");
  }
};
```

You can add contracts to an algorithm by defining a using contracts statement in it:

```c++
struct velo_search_by_triplet_t : public DeviceAlgorithm, Parameters {
  // Register contracts for this algorithm
  using contracts = std::tuple<contract_name>;
  ...
};
```

Contracts can be made generic by templating on the type Parameters. You can find generic contracts that can be reused under `test/contracts`.

In order to enable contracts, just build with the flag -DENABLE_CONTRACTS=ON and run the software. Algorithms that are run in the sequence will run with their contracts enabled.

An example
----------

Here is an example of a postcondition that checks there are no repeated hits in VELO tracks:

```c++
struct track_container_checks : public Allen::contract::Postcondition {
  void operator()(
    const ArgumentReferences<Parameters>& arguments,
    const RuntimeOptions&,
    const Constants&,
    const Allen::Context&) const
  {
    const auto velo_tracks_container = make_vector<Parameters::dev_tracks_t>(arguments);

    auto maximum_number_of_hits = true;
    auto no_repeated_hits = true;

    for (const auto track : velo_tracks_container) {
      maximum_number_of_hits &= track.hitsNum < Velo::Constants::max_track_size;

      // Check repeated hits in the hits of the track
      std::vector<uint16_t> hits(track.hitsNum);
      for (unsigned i = 0; i < track.hitsNum; ++i) {
        hits[i] = track.hits[i];
      }
      std::sort(hits.begin(), hits.end());
      auto it = std::adjacent_find(hits.begin(), hits.end());
      no_repeated_hits &= it == hits.end();
    }

    require(maximum_number_of_hits, "Require that all VELO tracks have a maximum number of hits");
    require(no_repeated_hits, "Require that all VELO tracks have no repeated hits");
  }
};
```

And it is enabled by adding it to the list of contracts of Search by triplet:

```c++
struct velo_search_by_triplet_t : public DeviceAlgorithm, Parameters {
  // Register contracts for this algorithm
  using contracts = std::tuple<track_container_checks>;
  ...
};
```
