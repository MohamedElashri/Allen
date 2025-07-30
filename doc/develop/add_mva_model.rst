
MVA Models Manager
======================

Existing MVA models in MVA Models Manager
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
- Single Layer Fully Connected Neural Network
- Multi Layer Fully Connected Neural Network
- CatBoost

Adding another MVA Model
^^^^^^^^^^^^^^^^^^^^^^^^^^

Create header file in `Allen/device/utils/mva_models/include/` to keep all models in same place. 

In a header file create a new device class to define a model:

.. code-block:: c++

    namespace Allen::MVAModels {
      struct DeviceAbsolutelyNewModel 
      {
        float* parameters;
        __device__ inline float evaluate(float* input) const;
      };
    } // namespace Allen::MVAModels

Define evaluation function for your MVA Model:

.. code-block:: c++

    __device__ inline float 
    Allen::MVAModels::DeviceAbsolutelyNewModel::evaluate(float* input) const
    {
        // insert your code to evaluate model output here
    }


Create a new host class to load the model.

.. code-block:: c++

    struct AbsolutelyNewModel : public MVAModelBase {
        using DeviceType = DeviceAbsolutelyNewModel;

        AbsolutelyNewModel(std::string name, std::string path) : 
            MVAModelBase(name, path) { m_device_pointer = nullptr; }

        const DeviceType* getDevicePointer() const { return m_device_pointer; }

        void readData(std::string parameters_path) override;

        private:
            DeviceType* m_device_pointer;
    };


Define readData function for model loading from the file and saving data in device memory.

.. code-block:: c++

    void Allen::MVAModels::AbsolutelyNewModel::readData(std::string parameters_path)
    {
        // insert your code to read from file here
        nlohmann::json j;
        {
            std::ifstream i(parameters_path + m_path);
            j = nlohmann::json::parse(i);
        }

        std::vector<float> weights = j.at("weights").get<std::vector<float>>();
        unsigned total_size = weights.size() * sizeof(float);

        Allen::malloc((void**) &(m_device_view.parameters), total_size);
        Allen::memcpy(m_device_view.parameters, weights.data(), 
            total_size, Allen::memcpyHostToDevice);
    }

This example show, how data can be read from JSON file, but any type of file can be used for configuring MVA model.

Register your model in the definition of Allen algorithm:

.. code-block:: c++

    #include "AbsolutelyNewModel.cuh"
    namespace algorithm_with_new_model {
        using MVAModelType = Allen::MVAModels::AbsolutelyNewModel;

        ...
        
        struct algorithm_with_new_model_t : public DeviceAlgorithm, Parameters {
        
        ...

        private:
            Property<block_dim_t> m_block_dim {this, {{16, 1, 1}}};
            MVAModelType new_mva_model {"new_mva_model", "parameter_values.json"};
        };
    } // namespace algorithm_with_new_model
    
Pass device view to global function.

code in `.cuh` file:

.. code-block:: c++

    __global__ void algorithm_with_new_model(  
        Parameters,
        const MVAModelType::DeviceType*);
        
code in `.cu` file:

.. code-block:: c++

    void algorithm_with_new_model::algorithm_with_new_model_t::operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const
    {
      global_function(algorithm_with_new_model)(
        dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(
        arguments,
        new_mva_model.getDevicePointer()); 
    }    
    
Call the evaluation function in global function:

.. code-block:: c++
    
    __global__ void algorithm_with_new_model::algorithm_with_new_model(
      algorithm_with_new_model::Parameters parameters,
      const MVAModelType::DeviceType* new_mva_model_device_view)
    {
        float* some_inputs;
        float mva_output = new_mva_model_device_view->evaluate(some_inputs);
    }


