# Custom optimizer types

The optimizer part of a model connects it to the optimization backend. 
The first part of the implementation is very similar to loss functions, so we just show the implementation of `SemOptimizerOptim` here:

```julia
############################################################################
### Types and Constructor
############################################################################

mutable struct SemOptimizerOptim{A, B} <: SemOptimizer
    algorithm::A
    options::B
end

function SemOptimizerOptim(;
        algorithm = LBFGS(), 
        options = Optim.Options(;f_tol = 1e-10, x_tol = 1.5e-8), 
        kwargs...)
    return SemOptimizerOptim(algorithm, options)
end

############################################################################
### Recommended methods
############################################################################

update_observed(optimizer::SemOptimizerOptim, observed::SemObserved; kwargs...) = optimizer

############################################################################
### additional methods
############################################################################

algorithm(optimizer::SemOptimizerOptim) = optimizer.algorithm
options(optimizer::SemOptimizerOptim) = optimizer.options
```

Now comes a part that is a little bit more complicated: We need to write methods for `sem_fit`:

```julia
function sem_fit(
        model::AbstractSemSingle{O, I, L, D}; 
        start_val = start_val, 
        kwargs...) where {O, I, L, D <: SemOptimizerOptim}
    
    if !isa(start_val, Vector)
        start_val = start_val(model; kwargs...)
    end

    optimization_result = ...

    ...

    return SemFit(minimum, minimizer, start_val, model, optimization_result)
end
```

The method has to return a `SemFit` object that consists of the minimum of the objective at the solution, the minimizer (aka parameter estimates), the starting values, the model and the optimization result (which may be anything you desire for your specific backend).

If we want our type to also work with `SemEnsemble` models, we also have to provide a method for that:

```julia
function sem_fit(
        model::SemEnsemble{N, T , V, D, S}; 
        start_val = start_val, 
        kwargs...) where {N, T, V, D <: SemOptimizerOptim, S}

    if !isa(start_val, Vector)
        start_val = start_val(model; kwargs...)
    end


    optimization_result = ...

    ...

    return SemFit(minimum, minimizer, start_val, model, optimization_result)

end
```

In addition, you might want to provide methods to access properties of your optimization result:

```julia
optimizer(res::MyOptimizationResult) = ...
n_iterations(res::MyOptimizationResult) = ...
convergence(res::MyOptimizationResult) = ...
```