module ForwardDiffOverMeasurements

using ForwardDiff: Dual, DiffRules, NaNMath, LogExpFunctions, SpecialFunctions,≺
using Measurements: Measurement
import Base: +,-,/,*,promote_rule
using ForwardDiff: AMBIGUOUS_TYPES, partials, values, Partials, value
using ForwardDiff: ForwardDiff

#patch this until is fixed in ForwardDiff

#TIL you can actually dispatch on @generated functions
@generated function ForwardDiff.construct_seeds(::Type{Partials{N,V}}) where {N,V<:Measurement}
    return Expr(:tuple, [:(single_seed(Partials{N,V}, Val{$i}())) for i in 1:N]...)
end

#needs redefinition here, because generated functions don't allow extra definitions
@generated function single_seed(::Type{Partials{N,V}}, ::Val{i}) where {N,V,i}
    ex = Expr(:tuple, [ifelse(i === j, :(oneunit(V)), :(zero(V))) for j in 1:N]...)
    return :(Partials($(ex)))
end

function promote_rule(::Type{Measurement{V}}, ::Type{Dual{T, V, N}}) where {T,V,N}
    Dual{Measurement{T}, V, N}
end

function promote_rule(::Type{Measurement{V1}}, ::Type{Dual{T, V2, N}}) where {V1<:AbstractFloat, T, V2, N}
    Vx = promote_rule(Measurement{V1},V2)
    return Dual{T , Vx, N}
end

function overload_ambiguous_binary(M,f)
    Mf = :($M.$f)
    return quote
        @inline function $Mf(x::Dual{Tx}, y::Measurement) where {Tx}
            ∂y = Dual{Tx}(y)
            $Mf(x,∂y)
        end

        @inline function $Mf(x::Measurement,y::Dual{Ty}) where {Ty}
            ∂x = Dual{Ty}(x)
            $Mf(∂x,y)
        end
    end
end

macro define_ternary_dual_op2(f, xyz_body, xy_body, xz_body, yz_body, x_body, y_body, z_body)
    FD = ForwardDiff
    R = Measurement
    defs = quote
        @inline $(f)(x::$FD.Dual{Txy}, y::$FD.Dual{Txy}, z::$R) where {Txy} = $xy_body
        @inline $(f)(x::$FD.Dual{Tx}, y::$FD.Dual{Ty}, z::$R)  where {Tx, Ty} = Ty ≺ Tx ? $x_body : $y_body
        @inline $(f)(x::$FD.Dual{Txz}, y::$R, z::$FD.Dual{Txz}) where {Txz} = $xz_body
        @inline $(f)(x::$FD.Dual{Tx}, y::$R, z::$FD.Dual{Tz}) where {Tx,Tz} = Tz ≺ Tx ? $x_body : $z_body
        @inline $(f)(x::$R, y::$FD.Dual{Tyz}, z::$FD.Dual{Tyz}) where {Tyz} = $yz_body
        @inline $(f)(x::$R, y::$FD.Dual{Ty}, z::$FD.Dual{Tz}) where {Ty,Tz} = Tz ≺ Ty ? $y_body : $z_body
    end
    for Q in AMBIGUOUS_TYPES
        expr = quote
            @inline $(f)(x::$FD.Dual{Tx}, y::$R, z::$Q) where {Tx} = $x_body
            @inline $(f)(x::$R, y::$FD.Dual{Ty}, z::$Q) where {Ty} = $y_body
            @inline $(f)(x::$R, y::$Q, z::$FD.Dual{Tz}) where {Tz} = $z_body
        end
        append!(defs.args, expr.args)
    end
    expr = quote
        @inline $(f)(x::$FD.Dual{Tx}, y::$R, z::$R) where {Tx} = $x_body
        @inline $(f)(x::$R, y::$FD.Dual{Ty}, z::$R) where {Ty} = $y_body
        @inline $(f)(x::$R, y::$R, z::$FD.Dual{Tz}) where {Tz} = $z_body
    end
    append!(defs.args, expr.args)
    return esc(defs)
end

#use DiffRules.jl rules

for (M, f, arity) in DiffRules.diffrules(filter_modules = nothing)
    if (M, f) in ((:Base, :^), (:NaNMath, :pow))
        continue  # Skip methods which we define elsewhere.
    elseif !(isdefined(@__MODULE__, M) && isdefined(getfield(@__MODULE__, M), f))
        continue  # Skip rules for methods not defined in the current scope
    end
    if arity == 2
        eval(overload_ambiguous_binary(M,f))
    else
        # error("ForwardDiff currently only knows how to autogenerate Dual definitions for unary and binary functions.")
        # However, the presence of N-ary rules need not cause any problems here, they can simply be ignored.
    end
end

#ternary overloads
@define_ternary_dual_op2(
    Base.hypot,
    ForwardDiff.calc_hypot(x, y, z, Txyz),
    ForwardDiff.calc_hypot(x, y, z, Txy),
    ForwardDiff.calc_hypot(x, y, z, Txz),
    ForwardDiff.calc_hypot(x, y, z, Tyz),
    ForwardDiff.calc_hypot(x, y, z, Tx),
    ForwardDiff.calc_hypot(x, y, z, Ty),
    ForwardDiff.calc_hypot(x, y, z, Tz),
)

@define_ternary_dual_op2(
    Base.fma,
    ForwardDiff.calc_fma_xyz(x, y, z),                         # xyz_body
    ForwardDiff.calc_fma_xy(x, y, z),                          # xy_body
    ForwardDiff.calc_fma_xz(x, y, z),                          # xz_body
    Base.fma(y, x, z),                                         # yz_body
    Dual{Tx}(Base.fma(value(x), y, z), partials(x) * y),       # x_body
    Base.fma(y, x, z),                                         # y_body
    Dual{Tz}(Base.fma(x, y, value(z)), partials(z))            # z_body
)

@define_ternary_dual_op2(
    Base.muladd,
    ForwardDiff.calc_muladd_xyz(x, y, z),                         # xyz_body
    ForwardDiff.calc_muladd_xy(x, y, z),                          # xy_body
    ForwardDiff.calc_muladd_xz(x, y, z),                          # xz_body
    Base.muladd(y, x, z),                             # yz_body
    Dual{Tx}(Base.muladd(value(x), y, z), partials(x) * y), # x_body
    Base.muladd(y, x, z),                             # y_body
    Dual{Tz}(Base.muladd(x, y, value(z)), partials(z))      # z_body
)

end #module