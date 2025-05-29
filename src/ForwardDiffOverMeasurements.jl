module ForwardDiffOverMeasurements

using ForwardDiff: Dual, DiffRules, NaNMath, LogExpFunctions, SpecialFunctions,≺
using Measurements: Measurement, Measurements
import Base: +,-,/,*,promote_rule
using ForwardDiff: AMBIGUOUS_TYPES, partials, values, Partials, value
using ForwardDiff: ForwardDiff

if isdefined(Base,:get_extension)
    @eval begin
        if Base.get_extension(Measurements,:MeasurementsForwardDiffExt) === nothing
            include("main.jl")
        end
    end
end

end #module
