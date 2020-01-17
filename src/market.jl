
const TICKERS = [
    "MMM", "AXP", "AAPL", "BA",  "CAT", "CVX", "CSCO",  "KO", "DIS",  #"DOW",
    "XOM",  "GS",  "HD", "IBM", "INTC", "JNJ",  "JPM", "MCD", "MRK", "MSFT",
    "NKE", "PFE",  "PG", "TRV",  "UTX", "UNH",   "VZ",   "V", "WMT",  "WBA"
]

function get_allocation_dict(api)
    positions = get_positions(api)
    if isempty(positions)
        return Dict{String, Float64}()
    else
        account_value = get_equity(get_account(api))
        Dict(x.symbol => x.quantity * get_last(api, x.symbol) / account_value for x in positions)
    end
end

function get_allocation(api, tickers)
    allocation_dict = get_allocation_dict(api)
    map(tickers) do ticker
        if ticker in keys(allocation_dict)
            allocation_dict[ticker]
        else
            0.0
        end
    end
end

function get_historical_returns(api, tickers, timeframe = Year(1))
    price_quotes = map(ticker -> ticker => Brokerages.get_historical(api, ticker, 252), tickers)
    prices = Dict(k => map(x -> x, v) for (k, v) in price_quotes)
    returns = Dict(k => v[1:end-1] ./ v[2:end] .- 1 for (k, v) in prices)
end

function get_return_matrix(tickers, return_dict)
    reduce(hcat, map(x -> return_dict[x], tickers))
end

function calculate_covariance(tickers, return_matrix)
    cov(AnalyticalNonlinearShrinkage(), return_matrix)
end

function determine_allocation_change(api, tickers, return_matrix, optimization_target)
    allocation = get_allocation(api, tickers)
    Σ = calculate_covariance(tickers, return_matrix)
    target = optimize(optimization_target, Σ)
    target .- allocation
end

function calculate_cross_sectional_volatility(return_matrix)
    vec(std(return_matrix, dims = 2))
end

function ses(data, α)
    out = zeros(length(data))
    out[1] = data[1]
    for i in 2:length(data)
        out[i] = α*data[i] + (1-α)*out[i-1]
    end
    out
end

function calculate_λ(return_matrix, ϕ = 1)
    csv = calculate_cross_sectional_volatility(return_matrix)
    smoothed_csv = reverse(ses(reverse(csv), 0.02))
    σ⁺, σ⁻ = maximum(csv), minimum(csv)
    λ = 1 - ϕ * (csv[1] - σ⁻)/(σ⁺ - σ⁻)
end

function process_trades(api, tickers)
    return_dict = get_historical_returns(api, tickers)
    return_matrix = get_return_matrix(tickers, return_dict)
    λ = calculate_λ(return_matrix)
    allocation_change = determine_allocation_change(api, tickers, return_matrix, RichardRancolli(1-λ, 0, 0, λ))
    equity = get_equity(get_account(api))
    trade_amounts = equity .* allocation_change
    for (ticker, trade_amount) in zip(tickers, trade_amounts)
        current_price = Brokerages.get_last(api, ticker)
        qty = Int(round(trade_amount / current_price, digits = 0))
        if !iszero(qty)
            direction = qty > 0 ? "Buying" : "Selling"
            @info "$direction $ticker: $qty shares"
            oi = OrderIntent(ticker, MarketOrder(), GTC(), qty)
            submit_order(api, oi)
        end
    end
end
