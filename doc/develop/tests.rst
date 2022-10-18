Test Allen algorithms
========================

Within Gaudi, calling Allen from Moore
^^^^^^^^^^^^^^^^
When calling Allen from Moore, Allen algorithms are called as Gaudi algorithms and therefore run in the same way as other Gaudi algorithms. Any output produced by such a Gaudi-Allen algorithm is stored on the Transient Event Store (TES) can then be used as input for other Gaudi algorithms implementing tests. 

An example for the Velo clusters can be seen in
`hlt1_velo_clusters.py <https://gitlab.cern.ch/lhcb/Moore/-/blob/master/Hlt/RecoConf/options/hlt1_velo_clusters.py>`_,
where the clusters produced by the Allen velo decoding (translated to Gaudi-Allen algorithms) are passed on to the Gaudi algorithm `TestVeloClusters <https://gitlab.cern.ch/lhcb/Allen/-/blob/master/Rec/Allen/src/TestVeloClusters.cpp>`_. 

Within Allen: Contracts
^^^^^^^^^^^^^^^^^^^^^^^^^^

Be sure to check out this presentation |presentation_contracts| which covers what is in this readme and more.

.. |presentation_contracts| raw:: html

   <a href="<https://indico.cern.ch/event/978570/contributions/4136202/attachments/2157046/3638389/main.pdf" target="_blank">this presentation</a>

How to add contracts
--------------------

In order to define a contract, you should give it a name and decide whether it is a Precondition or Postcondition (executed before / after an operator() of an algorithm). The syntax is as follows:

.. code-block:: c++

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

You can add contracts to an algorithm by defining a `using contracts` statement in it:

.. code-block:: c++

  struct velo_search_by_triplet_t : public DeviceAlgorithm, Parameters {
    // Register contracts for this algorithm
    using contracts = std::tuple<contract_name>;
    ...
  };

Contracts can be made generic by templating on the type Parameters. You can find generic contracts that can be reused under `test/contracts`.

Build Allen with contracts
--------------------------

In order to enable contracts, just build with the flag `-DENABLE_CONTRACTS=ON` and run the software.
Algorithms that are run in the sequence will run with their contracts enabled.

If you are using the |stack_setup|, you can either set the flag in `utils/config.json` manually or with::

  utils/config.py -- cmakeFlags.Allen '-DENABLE_CONTRACTS=ON'

.. |stack_setup| raw:: html

   <a href="https://gitlab.cern.ch/rmatev/lb-stack-setup" target="_blank">stack setup</a>

You might need to remove the CMake cache from a previous build with `make Allen/purge`.

An example
----------

Here is an example of a postcondition that checks there are no repeated hits in VELO tracks:

.. code-block:: c++

  struct track_container_checks : public Allen::contract::Postcondition {
    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context&) const
    {
      const auto velo_tracks_container = make_host_buffer<Parameters::dev_tracks_t>(arguments, context);

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

And it is enabled by adding it to the list of contracts of Search by triplet:

.. code-block:: c++

  struct velo_search_by_triplet_t : public DeviceAlgorithm, Parameters {
    // Register contracts for this algorithm
    using contracts = std::tuple<track_container_checks>;
    ...
  };
