using ForwardDiffOverMeasurements
using Measurements
using ForwardDiff
using Test
using Measurements: value, uncertainty, measurement

fd_f1(x,y) = measurement(2x,3y)
fd_f2(x) = fd_f1(x,x)
fd_f3(x,y) = muladd(x,y,1)
fd_f4(x,y) = value(fd_f1(x,y))
fd_f5(x,y) = uncertainty(fd_f1(x,y))

@testset "ForwardDiffOverMeasurements" begin
    x1 = 1.0 ± 0.1
    y1 = 30.0 ± 0.7
    #some common operations, no special handling in the extension, just wrapping in a dual
    @test ForwardDiff.derivative(Base.Fix1(+,x1),y1) == 1.0 ± 0.0
    @test ForwardDiff.derivative(Base.Fix1(+,y1),x1) == 1.0 ± 0.0
    @test ForwardDiff.derivative(Base.Fix1(*,y1),x1) == y1
    @test ForwardDiff.derivative(Base.Fix1(*,x1),y1) == x1
    @test ForwardDiff.derivative(Base.Fix2(/,y1),x1) == 1/y1
    @test ForwardDiff.derivative(Base.Fix1(/,x1),y1) == -x1/(y1*y1)

    #test ternary op
    @test ForwardDiff.derivative(Base.Fix1(fd_f3,y1),x1) == y1
    @test ForwardDiff.derivative(Base.Fix1(fd_f3,x1),y1) == x1

    #derivatives of Measurements.measurement
    @test ForwardDiff.derivative(Base.Fix1(fd_f1,1.0),1.213) == 0.0 ± 3.0
    @test ForwardDiff.derivative(Base.Fix2(fd_f1,1.0),1.213) == 2.0 ± 0.0
    @test ForwardDiff.derivative(fd_f2,1.213) == 2.0 ± 3.0

    #test value/uncertainty getters
    @test ForwardDiff.derivative(Base.Fix2(fd_f4,1.0),1.213) == 2.0
    @test ForwardDiff.derivative(Base.Fix1(fd_f5,1.0),1.213) == 3.0
end
