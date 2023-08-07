[![Build Status](https://github.com/longemen3000/ForwardDiffOverMeasurements.jl/workflows/CI/badge.svg)](https://github.com/longemen3000/ForwardDiffOverMeasurements.jl/actions)

# ForwardDiffOverMeasurements

## Motivation

starting with:
```julia
f(x,y) = x*y*exp(x+y) + 2x-2y + x/y
```
This is fine:
```julia
using Measurements
f(x,y) = x*y*exp(x+y) + 2x-2y + x/y
x1 = 1.0 ±0.1
y1 = 2.0 ±0.001
f(x1,y1) #fine
```
This is also fine:

```julia
using ForwardDiff
x1 = 1.0
y1 = 2.0
dfx(x,y) = ForwardDiff.derivative(_x -> f(_x,y),x)
dfx(x1,y1) #also fine
```

But,this combination is **not** fine:
```julia
using ForwardDiff,Measurements
x1 = 1.0 ±0.1
y1 = 2.0 ±0.001
dfx(x,y) = ForwardDiff.derivative(_x -> f(_x,y),x)
dfx(x1,y1) #NOT FINE
```
Solution:

```julia
using ForwardDiff,Measurements,ForwardDiffOverMeasurements
x1 = 1.0 ±0.1
y1 = 2.0 ±0.001
dfx(x,y) = ForwardDiff.derivative(_x -> f(_x,y),x)
dfx(x1,y1) #fine again
```

## Usage
on the REPL:
```
>julia ]
(@v1.7) pkg> add ForwardDiffOverMeasurements
>julia using ForwardDiffOverMeasurements
```

The package loads promote rules and some basic operations that favor a `ForwardDiff.Dual` over a `Measurements.Measurement`, so this holds:
```julia
f(x::Dual,y::Measurement)::Dual
```
The package does not export anything nor does define new functions.

At the moment, `+`, `-`, `*`, and `/` are defined. if any Base function is missing, please open an issue.

