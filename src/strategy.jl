struct DynamicRiskParity <: AbstractStrategy end
function initialize!(::DynamicRiskParity, b, m)
    #warmup!(m, 252)
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
function should_run(::DynamicRiskParity, b, ::LiveMarketDataProvider, params)
    true
end
function should_run(::DynamicRiskParity, b, m::SimulatedMarketDataProvider, params)
    m.tick_state[] != length(m.timestamps)
end
sleep_til_opening(b, m::SimulatedMarketDataProvider) = tick!(b)
function sleep_til_opening(b, m::LiveMarketDataProvider)
    t = get_clock(m)
    sleep_til = Time(9, 30)
    @info "Sleeping until $sleep_til"
    sleep(sleep_til - Time(now()))
end
sleep_til_open(b, m::SimulatedMarketDataProvider) = tick!(b)
function sleep_til_open(b, m::LiveMarketDataProvider)
    t = get_clock(m)
    sleep_til = Time(9, 35)
    @info "Sleeping until $sleep_til"
    sleep(sleep_til - Time(now()))
end
sleep_til_closing(b, m::SimulatedMarketDataProvider) = tick!(b)
function sleep_til_closing(b, m::LiveMarketDataProvider)
    t = get_clock(m)
    sleep_til = Time(15, 55)
    @info "Sleeping until $sleep_til"
    sleep(sleep_til - Time(now()))
end
sleep_til_close(b, m::SimulatedMarketDataProvider) = tick!(b)
function sleep_til_close(b, m::LiveMarketDataProvider)
    t = get_clock(m)
    sleep_til = Time(16)
    @info "Sleeping until $sleep_til"
    sleep(sleep_til - Time(now()))
end
sleep_til_preopen(b, m::SimulatedMarketDataProvider) = tick!(b)
function sleep_til_preopen(b, m::LiveMarketDataProvider)
    t = get_clock(m)
    sleep_time = Date(today() + Day(1)) + Time(9)
    sleep_til = Date(today() + Day(1)) + Time(9)
    @info "Sleeping until $sleep_til"
    sleep(sleep_til - now())
end
function process_preopen!(::DynamicRiskParity, b, m, params)
    process_trades(b, m, params.tickers)
    sleep_til_opening(b, m)
end
function process_open!(::DynamicRiskParity, b, m, params)
    sleep_til_open(b, m)
end
function process!(::DynamicRiskParity, b, m, params)
    sleep_til_closing(b, m)
end
function process_close!(::DynamicRiskParity, b, m, params)
    #Brokerages.close_positions(b)
    sleep_til_close(b, m)
end
function process_postclose!(::DynamicRiskParity, b, m, params)
    @info get_clock(m)
    push!(params.statistics["equity"], (get_clock(m), get_equity(b)))
    sleep_til_preopen(b, m)
end
function update_statistics!(::DynamicRiskParity, b, m, params)
    nothing
end
