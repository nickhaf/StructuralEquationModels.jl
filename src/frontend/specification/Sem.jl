##############################################################
# constructor for Sem types
##############################################################

function Sem(;
        observed::O = SemObsCommon,
        imply::I = RAM,
        loss::L = (SemML,),
        diff::D = SemDiffOptim,
        kwargs...) where {O, I, L, D}

    kwargs = Dict{Symbol, Any}(kwargs...)

    set_field_type_kwargs!(kwargs, observed, imply, loss, diff)
    
    observed, imply, loss, diff = get_fields!(kwargs, observed, imply, loss, diff)

    sem = Sem(observed, imply, loss, diff)

    return sem
end

function SemFiniteDiff(;
        observed::O = SemObsCommon,
        imply::I = RAM,
        loss::L = (SemML,),
        diff::D = SemDiffOptim,
        has_gradient = false,
        kwargs...) where {O, I, L, D}

    kwargs = Dict{Symbol, Any}(kwargs...)

    set_field_type_kwargs!(kwargs, observed, imply, loss, diff)
    
    observed, imply, loss, diff = get_fields!(kwargs, observed, imply, loss, diff)

    sem = SemFiniteDiff(observed, imply, loss, diff, has_gradient)

    return sem
end

function SemForwardDiff(;
        observed::O = SemObsCommon,
        imply::I = RAM,
        loss::L = (SemML,),
        diff::D = SemDiffOptim,
        has_gradient = false,
        kwargs...) where {O, I, L, D}

    kwargs = Dict{Symbol, Any}(kwargs...)

    set_field_type_kwargs!(kwargs, observed, imply, loss, diff)
    
    observed, imply, loss, diff = get_fields!(kwargs, observed, imply, loss, diff)

    sem = SemForwardDiff(observed, imply, loss, diff, has_gradient)
    
    return sem
end

##############################################################
# functions
##############################################################

function set_field_type_kwargs!(kwargs, observed, imply, loss, diff)
    kwargs[:observed_type] = O <: Type ? observed : typeof(observed)
    kwargs[:imply_type] = I <: Type ? imply : typeof(imply)
    if loss isa SemLoss
        kwargs[:loss_types] = [lossfun isa SemLossFunction ? typeof(lossfun) : lossfun for lossfun in loss.functions]
    elseif applicable(iterate, loss)
        kwargs[:loss_types] = [lossfun isa SemLossFunction ? typeof(lossfun) : lossfun for lossfun in loss]
    else
        kwargs[:loss_types] = [loss isa SemLossFunction ? typeof(loss) : loss]
    end
    kwargs[:diff_type] = D <: Type ? diff : typeof(diff)
end

# construct Sem fields
function get_fields!(kwargs, observed, imply, loss, diff)
    # observed
    if O <: Type
        observed = observed(;kwargs...)
    end
    kwargs[:observed] = observed

    # imply
    if !isa(imply, SemImply)
        imply = imply(;kwargs...)
    end

    kwargs[:imply] = imply
    kwargs[:n_par] = imply.n_par

    # loss
    loss = get_SemLoss(loss)
    kwargs[:loss] = loss

    # diff
    if !isa(diff, SemDiff)
        diff = diff(;kwargs...)
    end

    return observed, imply, loss, diff
end

# construct loss field
function get_SemLoss(loss)
    if loss isa SemLoss
        nothing
    elseif applicable(iterate, loss)
        loss_out = []
        for lossfun in loss
            if isa(lossfun, SemLossFunction)
                push!(loss_out, lossfun)
            else
                lossfun = lossfun(;kwargs...)
                push!(loss_out, lossfun)
            end
        end
        loss = SemLoss(loss_out...)
    else
        if !isa(loss, SemLossFunction)
            loss = SemLoss(loss(;kwargs...))
        end
    end
    return loss
end


##############################################################
# pretty printing
##############################################################

#= function Base.show(io::IO, sem::Sem{O, I, L, D})  where {O, I, L, D}
    lossfuntypes = @. nameof(typeof(sem.loss.functions))
    print(io, "Sem{$(nameof(O)), $(nameof(I)), $lossfuntypes, $(nameof(D))}")
end =#

function Base.show(io::IO, sem::Sem{O, I, L, D})  where {O, I, L, D}
    lossfuntypes = @. string(nameof(typeof(sem.loss.functions)))
    lossfuntypes = "   ".*lossfuntypes.*("\n")
    print(io, "Structural Equation Model \n")
    print(io, "- Loss Functions \n")
    print(io, lossfuntypes...)
    print(io, "- Fields \n")
    print(io, "   observed:  $(nameof(O)) \n")
    print(io, "   imply:     $(nameof(I)) \n")
    print(io, "   diff:      $(nameof(D)) \n")
end

function Base.show(io::IO, sem::SemFiniteDiff{O, I, L, D})  where {O, I, L, D}
    lossfuntypes = @. string(nameof(typeof(sem.loss.functions)))
    lossfuntypes = "   ".*lossfuntypes.*("\n")
    print(io, "Structural Equation Model : Finite Diff Approximation\n")
    print(io, "- Loss Functions \n")
    print(io, lossfuntypes...)
    print(io, "- Fields \n")
    print(io, "   observed:  $(nameof(O)) \n")
    print(io, "   imply:     $(nameof(I)) \n")
    print(io, "   diff:      $(nameof(D)) \n") 
end

function Base.show(io::IO, sem::SemForwardDiff{O, I, L, D})  where {O, I, L, D}
    lossfuntypes = @. string(nameof(typeof(sem.loss.functions)))
    lossfuntypes = "   ".*lossfuntypes.*("\n")
    print(io, "Structural Equation Model : Forward Mode Autodiff\n")
    print(io, "- Loss Functions \n")
    print(io, lossfuntypes...)
    print(io, "- Fields \n")
    print(io, "   observed:  $(nameof(O)) \n")
    print(io, "   imply:     $(nameof(I)) \n")
    print(io, "   diff:      $(nameof(D)) \n") 
end

function Base.show(io::IO, loss::SemLoss)
    lossfuntypes = @. string(nameof(typeof(loss.functions)))
    lossfuntypes = "   ".*lossfuntypes.*("\n")
    print(io, "SemLoss \n")
    print(io, "- Loss Functions \n")
    print(io, lossfuntypes...)
    print(io, "- Fields \n")
    print(io, "   F:  $(typeof(loss.F))) \n")
    print(io, "   G:  $(typeof(loss.G))) \n")
    print(io, "   H:  $(typeof(loss.H))) \n") 
end

function Base.show(io::IO, models::SemEnsemble)

    print(io, "SemEnsemble \n")
    print(io, "- Number of Models: $(models.n) \n")
    print(io, "- Weights: $(round.(models.weights, digits = 3)) \n")

    print(io, "\n")
    print(io, "Fields \n")
    print(io, "   diff:  $(nameof(typeof(models.diff))) \n")
    print(io, "   start_val:  $(typeof(models.start_val)) \n")
    print(io, "   F:  $(typeof(models.F))) \n")
    print(io, "   G:  $(typeof(models.G))) \n")
    print(io, "   H:  $(typeof(models.H))) \n")

    print(io, "\n")
    print(io, "Models: \n")
    print(io, "=========================", "\n")
    for (model, i) in zip(models.sems, 1:models.n)
        print(io, "----------- ", i, " -----------", "\n")
        print(io, model)
    end
end