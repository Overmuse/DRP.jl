struct DynamicRiskParity{T} <: AbstractStrategy where T
    target::T
end
function _initialize()
    tickers = [
        "MMM", "AXP", "AAPL", "BA",  "CAT", "CVX", "CSCO",  "KO", "DIS",  #"DOW",
        "XOM",  "GS",  "HD", "IBM", "INTC", "JNJ",  "JPM", "MCD", "MRK", "MSFT",
        "NKE", "PFE",  "PG", "TRV",  "UTX", "UNH",   "VZ",   "V", "WMT",  "WBA"
    ]
    statistics = Dict(
        "equity" => Tuple{DateTime, Float64}[],
        "allocation" => Tuple{DateTime, Vector{Float64}}[],
        "IRR" => 0.0,
        "return" => 0.0,
        "num_trades" => 0,
        "num_orders" => 0
    )
    return (tickers = tickers, statistics = statistics)
end
function initialize!(::DynamicRiskParity, b::SingleAccountBrokerage, m::SimulatedMarketDataProvider)
    reset!(b)
    warmup!(m, 252)
    _initialize()
end
function initialize!(::DynamicRiskParity, b, m)
    _initialize()
end
function should_run(::DynamicRiskParity, b, ::LiveMarketDataProvider, params)
    true
end
function should_run(::DynamicRiskParity, b, m::SimulatedMarketDataProvider, params)
    m.tick_state[] != length(m.timestamps)
end

process_preopen!(x::DynamicRiskParity, b, m, params) = nothing
process_open!(::DynamicRiskParity, b, m, params) = nothing
function process!(x::DynamicRiskParity, b, m, params)
    process_trades(b, m, params.tickers; target = x.target)
end
process_close!(::DynamicRiskParity, b, m, params) = nothing
function process_postclose!(::DynamicRiskParity, b, m, params)
    @info get_clock(m)
end
function _calculate_irr(b, m)
    orders = vcat(b.account.inactive_orders, b.account.active_orders)
    first_date = mapreduce(x -> x.filled_at, min, orders)
    (get_equity(b) / b.account.starting_cash) ^ (365/convert(Day, get_clock(m) - first_date).value) - 1
end

function finalize!(::DynamicRiskParity, b, m, params)
    params.statistics["return"] = (get_equity(b) / b.account.starting_cash) - 1
    params.statistics["IRR"] = _calculate_irr(b, m)
    params.statistics["num_trades"] = count(x -> x.status == "filled", b.account.inactive_orders)
    params.statistics["num_orders"] = length(b.account.inactive_orders) + length(b.account.active_orders)
end
function update_statistics!(::DynamicRiskParity, b, m, params)
    if is_closed(m)
        push!(params.statistics["equity"], (get_clock(m), get_equity(b)))
        push!(params.statistics["allocation"], (get_clock(m), get_allocation(b, m, params.tickers)))
    end
end
