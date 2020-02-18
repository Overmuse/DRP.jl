module DRP

export DynamicRiskParity, process_trades, run!

using
    CovarianceEstimation,
    Dates,
    LinearAlgebra,
    PortfolioOptimization,
    Statistics,
    TradingBase,
    Brokerages,
    Markets

using Simulator: AbstractStrategy, run!
import Simulator:
    initialize!,
    should_run,
    process_preopen!,
    process_open!,
    process!,
    process_close!,
    process_postclose!,
    finalize!,
    update_statistics!,
    sleep_til_preopen,
    sleep_til_opening,
    sleep_til_open,
    sleep_til_closing,
    sleep_til_close

include("market.jl")
include("strategy.jl")

end # module
