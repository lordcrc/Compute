Compute
=======

Delphi.Compute library, inspired by Boost.Compute.

Under development!

The goal is to provide a high-level interface to GPGPU programming,
so one can easily utilize the powers of modern GPU/APUs in Delphi.


Example
-------
```Pascal
  // Add one to each element in input data and take the square root
  output_data := Compute.Transform(input_data, sqrt(_1 + 1));
```


Uses ported OpenCL headers from delphi-opencl project
https://code.google.com/p/delphi-opencl/

Licensed under the Apache 2.0 license, see LICENSE.txt for details
