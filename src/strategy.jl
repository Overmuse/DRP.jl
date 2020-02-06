struct DynamicRiskParity <: AbstractStrategy end
function initialize!(::DynamicRiskParity, args...)
    tickers = [
        "MMM", "AXP", "AAPL", "BA",  "CAT", "CVX", "CSCO",  "KO", "DIS",  #"DOW",
        "XOM",  "GS",  "HD", "IBM", "INTC", "JNJ",  "JPM", "MCD", "MRK", "MSFT",
        "NKE", "PFE",  "PG", "TRV",  "UTX", "UNH",   "VZ",   "V", "WMT",  "WBA"
    ]
    return (tickers = tickers,)
end
function should_run(::DynamicRiskParity, b, m, params)
    m.tick_state[] != length(m.timestamps)
end
process_preopen!(::DynamicRiskParity, b, m, params) = tick!(b)
process_open!(::DynamicRiskParity, b, m, params) = tick!(b)
function process!(::DynamicRiskParity, b, m, params)
    process_trades(b, params.tickers)
    tick!(b)
end
process_close!(::DynamicRiskParity, b, m, params) = tick!(b)
function process_postclose!(::DynamicRiskParity, b, m, params)
    @info m.tick_state[]
    tick!(b)
end
update_statistics!(::DynamicRiskParity, b, m, params) = nothing
