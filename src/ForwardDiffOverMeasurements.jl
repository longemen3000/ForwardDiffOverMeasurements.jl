module ForwardDiffOverMeasurements

using ForwardDiff: Dual
using Measurements: Measurement
import Base: +,-,/,*,promote_rule 

function promote_rule(::Type{Measurement{V}}, ::Type{Dual{T, V, N}}) where {T,V,N}
    Dual{Measurement{T}, V, N}
end

function promote_rule(::Type{Measurement{V1}}, ::Type{Dual{T, V2, N}}) where {V1<:AbstractFloat, T, V2, N}
    Vx = promote_rule(Measurement{V1},V2)
    return Dual{T , Vx, N}
end

macro overload_ambiguous(op)
    return quote
        @inline function $op(x::Dual{Tx,V}, y::Measurement{V}) where {Tx,V}
            y = Dual{Tx}(y)
            $op(x,y)
        end
        
        @inline function $op(x::Measurement{V},y::Dual{Ty,V}) where {V,Ty}
            x = Dual{Ty}(x)
            $op(x,y)
        end
        
        @inline function $op(x::Dual{Tx}, y::Measurement) where {Tx}
            y = Dual{Tx}(y)
            $op(x,y)
        end
        
        @inline function $op(x::Measurement,y::Dual{Ty}) where {Ty}
            x = Dual{Ty}(x)
            $op(x,y)
        end
    end |> esc
end

@overload_ambiguous Base.:+
@overload_ambiguous Base.:-
@overload_ambiguous Base.:*
@overload_ambiguous Base.:/

end #module