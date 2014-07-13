# Compute

Delphi.Compute library, inspired by Boost.Compute.

Under development!

The goal is to provide a high-level interface to GPGPU programming
through OpenCL, so one can easily utilize the powers of modern 
GPU/APUs in Delphi.


## Example

```Pascal
  // Add one to each element in input data and take the square root
  output_data := Compute.Transform(input_data, sqrt(_1 + 1));
```


## Running the code
Since this project relies on OpenCL, please make sure you have
OpenCL platform drivers installed.

AMD GPU: http://support.amd.com/en-us/download
NVIDIA GPU: http://www.nvidia.com/Download/index.aspx
Intel CPU: https://software.intel.com/en-us/articles/opencl-drivers


## Additional

Uses ported OpenCL headers from delphi-opencl project
https://code.google.com/p/delphi-opencl/

Licensed under the Apache 2.0 license, see LICENSE.txt for details
