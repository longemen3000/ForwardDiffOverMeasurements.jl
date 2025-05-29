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

@testset "ForwardDiff" begin
    x1 = 1.0 ± 0.1
    y1 = 30.0 ± 0.7
    #test promotion rules
    type_d1 = ForwardDiff.Dual{Nothing,Float64,1}
    type_d1_big = ForwardDiff.Dual{Nothing,BigFloat,1}
    type_m1 = Measurement{Float64}
    type_m1_big = Measurement{BigFloat}
    type_p1 = ForwardDiff.Dual{Nothing,Measurement{Float64},1}
    type_p1_big = ForwardDiff.Dual{Nothing,Measurement{BigFloat},1}

    for (t1,t2,r) in [(type_d1,type_m1,type_p1),
                (type_d1_big,type_m1,type_p1_big),
                (type_m1_big,type_p1,type_p1_big),
                (type_p1_big,type_m1,type_p1_big),
                (type_m1_big,type_p1_big,type_p1_big),
        ]

        @test promote_rule(t1,t2) == r
        @test promote_rule(t2,t1) == r
        @test (oneunit(t1) + oneunit(t2)) isa r
        @test (oneunit(t2) + oneunit(t1)) isa r 
    end
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
    @test ForwardDiff.derivative(measurement,y1) == 1.0 ± 0.0

    #test value/uncertainty getters
    @test ForwardDiff.derivative(Base.Fix2(fd_f4,1.0),1.213) == 2.0
    @test ForwardDiff.derivative(Base.Fix1(fd_f5,1.0),1.213) == 3.0

    #test ForwardDiff.single_seed/ForwardDiff.construct_seeds overload
    partials1 = ForwardDiff.single_seed(ForwardDiff.Partials{3,Measurement{Float64}},Val(2))
    @test partials1[1] == 0.0 ± 0.0
    @test partials1[2] == 1.0 ± 0.0
    @test partials1[3] == 0.0 ± 0.0

    tuple_of_partials = ForwardDiff.construct_seeds(ForwardDiff.Partials{3,Measurement{Float64}})
    
    for i in 1:3
        partial_i = tuple_of_partials[i]
        for j in 1:3
            if j == i
                @test partial_i[j] == 1.0 ± 0.0
            else
                @test partial_i[j] == 0.0 ± 0.0
            end
        end
    end
end
