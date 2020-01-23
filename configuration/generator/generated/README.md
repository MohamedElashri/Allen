Generated files brief README
----------------------------

This folder will contain the files generated with the Allen configuration manager.

In order to generate a configuration, from the "generator/" folder follow the next steps:

* Invoke `./parse_algorithms.py`. The generated file `algorithms.py` contains information of the algorithms in the C++ code.

* Write your own configuration. You may `import algorithms` from a python shell and check with auto-complete the algorithms available and their options. Printing any one algorithm will tell you its parameters and properties. You have also some examples in the "generator/" folder, such as `VeloSequence.py`, `UTSequence.py` and so on.

* Invoke the `generate` method of a sequence. This will generate three files: A `ConfiguredSequence.h` containing the C++ generated code to successfully compile the code. A `Configuration.json` file, which can be used to configure the application when invoking it. Finally, a `ConfigurationGuide.json`, with all available options and their default values, for reference.

* Copy the generated `ConfiguredSequence.h` onto `configuration/sequences/`, and the `Configuration.json` onto `configuration/constants/`. Now you should be able to compile your sequence by issuing `cmake -DSEQUENCE=ConfiguredSequence .. && make`. You can invoke the program with your options with `./Allen --configuration=../configuration/constants/Configuration.json`.

Enjoy!