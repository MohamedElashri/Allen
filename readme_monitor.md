Allen: monitoring algorithms with ROOT
======================================

This tutorial will help you use the [`ROOTService`](main/include/ROOTService.h) utility to monitor  algorithms in general and, in particular, `Lines`.

### Monitoring Lines with ROOT
In order to monitor your lines **three** functions have to be added. The first one is devoted to initialize the arrays that will be fille by the `monitor` function. The second one is used to retrieve the necessary information from the inputs of the `Line` (both `Tracks` and `Vertices`). A third one has to be added in order to transport the information into a `ROOTFile`

In this example we want to monitor the `Mass` and `pT` of the Secondary Vertices selected by a line meant for the decay Ks-> pi+ pi- .

First wee need to add the additional `Parameters` that will carry our arrays to our `Line` header:

```c++
namespace kstopipi_line {
  struct Parameters {
    (...)

    DEVICE_OUTPUT(dev_sv_masses_t, float) dev_sv_masses;
    HOST_OUTPUT(host_sv_masses_t, float) host_sv_masses;

    DEVICE_OUTPUT(dev_pt_t, float) dev_pt;
    HOST_OUTPUT(host_pt_t, float) host_pt;
  };
  
```
Now we can put a `init_monitor` function in order to initialize the values for our arrays:
```c++
void kstopipi_line::kstopipi_line_t::init_monitor(const ArgumentReferences<Parameters>& arguments,
  const Allen::Context& context){
    initialize<dev_sv_masses_t>(arguments, -1, context);
    initialize<dev_pt_t>(arguments, -1, context);
}
```

Then we set up the `monitor` function that will be handled by the `Kernel` in order to retrieve the information that we want to monitor:

```c++
__device__ void kstopipi_line::kstopipi_line_t::monitor(
  const Parameters& parameters,
  std::tuple<const VertexFit::TrackMVAVertex&> input,
  unsigned index,
  bool sel)
{
  const auto& vertex = std::get<0>(input);
  if (sel) {
    parameters.dev_sv_masses[index] = vertex.m(139.57, 139.57);
    parameters.dev_pt[index] = vertex.pt();
  }
  else {
    parameters.dev_sv_masses[index] = -1.f;
  }
}
```

Then we want to set up an `ouput_monitor` function in order to transport these values into a `TTree` inside a `TFile`.

```c++
void kstopipi_line::kstopipi_line_t::output_monitor(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Allen::Context& context) const
{

  auto name_str = name();
  std::string name_ttree = "monitor_tree" + name_str;
  copy<host_sv_masses_t, dev_sv_masses_t>(arguments, context);
  copy<host_pt_t, dev_pt_t>(arguments, context);
  Allen::synchronize(context);

  auto handler = runtime_options.root_service->handle();

  handler.file("monitor.root");

  auto tree = handler.ttree(name_ttree.c_str());

  float mass;
  float pt;
  int ev;

  handler.branch("mass", mass);
  handler.branch("pt", pt);
  handler.branch("ev", ev);

  unsigned n_svs = size<host_sv_masses_t>(arguments);
  float* sv_mass;
  float* sv_pt;
  int i0 = tree->GetEntries();
  for (unsigned i = 0; i < n_svs; i++) {
    sv_mass = data<host_sv_masses_t>(arguments) + i;
    sv_pt = data<host_pt_t>(arguments) + i;
    if (sv_mass[0] > 0) {
      mass = sv_mass[0];
      pt = sv_pt[0];
      ev = i0 + i;
      tree->Fill();
    }
  }
  tree->Write(0, TObject::kOverwrite);
}
```


In the latter example we make use of the `ROOTService`. This utility allows us to properly handle `TFile` objects with Allen: it prevents race conditions and properly closes/reopens files whenever it is needed. 

This example has four different parts:
1) Copy the arrays produced by the `monitor` function to the `Host`, where `ROOT` is ran. In order to prevent race conditions we add an add a synchronization call:
```c++
copy<host_sv_masses_t, dev_sv_masses_t>(arguments, context);
copy<host_pt_t, dev_pt_t>(arguments, context);
Allen::synchronize(context);
```


2) Invoke the `ROOTService` handler:
```c++
auto handler = runtime_options.root_service->handle();
```
This object will allow us to access/create a `TFile` and write a `TTree` inside it with as many branches as one needs.

```c++
handler.file("monitor.root");
auto tree = handler.ttree(name_ttree.c_str());
```
3) Set up the branches:
```c++
float mass;
float pt;
int ev;

handler.branch("mass", mass);
handler.branch("pt", pt);
handler.branch("ev", ev);
```
4) Event loop and writing of the branches. This works as regular `ROOT`. We simply do a loop over the number of `Inputs ` that we set in the `monitor` function. Finally we write the `TTree`. The closing of the file and prevention of race conditions is taken care by the `ROOTService`




The source files that implement these examples correspond to the `KsToPiPiLine`  and are the following:
- [Line Header](device/selections/lines/inclusive_hadron/include/KsToPiPiLine.cuh)
- [Line Implementation](device/selections/lines/inclusive_hadron/src/KsToPiPiLine.cu)
- [Line output monitor implementation](device/selections/lines/inclusive_hadron/src/KsToPiPiLine_monitor.cpp)

