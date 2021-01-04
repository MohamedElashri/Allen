Contracts
=========

* Be sure to check out [this presentation](https://indico.cern.ch/event/978570/contributions/4136202/attachments/2157046/3638389/main.pdf) which covers what is in this readme and more.

Some examples
-------------

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
      using contracts = std::tuple<cluster_container_checks, track_container_checks,
        Allen::contract::limit_high<Velo::Constants::max_tracks, dev_number_of_velo_tracks_t, Parameters, Allen::contract::Postcondition>>;
      ...
    };
    ```

Be sure to check out `test/contracts` for generic contracts.

In order to enable contracts, just build with the flag -DENABLE_CONTRACTS=ON and run the software. Algorithms that are run in the sequence will run with their contracts enabled.
