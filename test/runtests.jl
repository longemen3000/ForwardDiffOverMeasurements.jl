using ForwardDiffOverMeasurements
using Measurements
using ForwardDiff
using Test

f1(x,y) = x+y
f2(x,y) = x-y
f3(x,y) = x*y
f4(x,y) = x/y
f5(x,y) = muladd(x,y,1)
@testset "ForwardDiffOverMeasurements.jl" begin  
    x1 = 1.0 ± 0.1
    y1 = 2.0 ± 0.001
    for op in (:f1,:f2,:f3,:f4,:f5)
        @eval begin
            @test ForwardDiff.derivative(x->$(op)(x,$y1),$x1) isa Measurement
            @test ForwardDiff.derivative(y->$(op)($x1,y),$y1) isa Measurement
        end
    end
end
