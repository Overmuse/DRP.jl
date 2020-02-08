struct DynamicRiskParity <: AbstractStrategy end
function initialize!(::DynamicRiskParity, b, m)
    warmup!(m, 252)
    tickers = [
        "MMM", "AXP", "AAPL", "BA",  "CAT", "CVX", "CSCO",  "KO", "DIS",  #"DOW",
        "XOM",  "GS",  "HD", "IBM", "INTC", "JNJ",  "JPM", "MCD", "MRK", "MSFT",
        "NKE", "PFE",  "PG", "TRV",  "UTX", "UNH",   "VZ",   "V", "WMT",  "WBA"
    ]
    statistics = Dict(
        "equity" => Tuple{DateTime, Float64}[]
    )
    return (tickers = tickers, statistics = statistics)
end
function should_run(::DynamicRiskParity, b, m, params)
    m.tick_state[] != length(m.timestamps)
end
function process_preopen!(::DynamicRiskParity, b, m, params)
    process_trades(b, params.tickers)
    tick!(b)
end
function process_open!(::DynamicRiskParity, b, m, params)
    tick!(b)
end
process!(::DynamicRiskParity, b, m, params) = tick!(b)
function process_close!(::DynamicRiskParity, b, m, params)
    Brokerages.close_positions(b)
    tick!(b)
end
function process_postclose!(::DynamicRiskParity, b, m, params)
    @info get_clock(m)
    push!(params.statistics["equity"], (get_clock(m), get_equity(b)))
    tick!(b)
end
function update_statistics!(::DynamicRiskParity, b, m, params)
    nothing
end
