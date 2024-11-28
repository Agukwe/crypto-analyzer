;; crypto-analyzer.clar
;; Enhanced contract with additional analysis features

;; Constants
(define-constant contract-owner tx-sender)
(define-constant PERCENTAGE_MULTIPLIER u100)
(define-constant MAX_PRICE_HISTORY u10)
(define-constant MOVING_AVERAGE_PERIOD u5)

;; Error codes
(define-constant err-owner-only (err u100))
(define-constant err-invalid-price (err u101))
(define-constant err-no-previous-price (err u102))
(define-constant err-invalid-coin (err u103))
(define-constant err-invalid-threshold (err u104))
(define-constant err-invalid-timeframe (err u105))

;; Define data structures
(define-map CoinPrices
    { coin: (string-ascii 10) }
    {
        current-price: uint,
        previous-price: uint,
        timestamp: uint,
        percentage-change: int,
        is-profitable: bool,
        highest-price: uint,
        lowest-price: uint,
        volume: uint,
        moving-average: uint
    }
)

;; Price history for moving averages
(define-map PriceHistory
    { coin: (string-ascii 10) }
    { prices: (list 10 uint) }
)

;; Trading signals
(define-map TradingSignals
    { coin: (string-ascii 10) }
    {
        signal: (string-ascii 4), ;; "BUY" or "SELL"
        strength: uint,           ;; 1-100
        timestamp: uint
    }
)

(define-map ProfitabilitySettings
    { coin: (string-ascii 10) }
    { 
        threshold: uint,
        stop-loss: uint,
        take-profit: uint
    }
)

;; Volume tracking
(define-map VolumeData
    { coin: (string-ascii 10) }
    { 
        daily-volume: uint,
        volume-ma: uint
    }
)

;; Private functions

(define-private (validate-coin (coin (string-ascii 10)))
    (let ((length (len coin)))
        (and (> length u0) (<= length u10))
    )
)

(define-private (calculate-percentage-change (old-price uint) (new-price uint))
    (if (is-eq old-price u0)
        0
        (to-int (/ (* (- new-price old-price) PERCENTAGE_MULTIPLIER) old-price))
    )
)

(define-private (update-price-history (coin (string-ascii 10)) (price uint))
    (let ((current-history (default-to { prices: (list ) } (map-get? PriceHistory { coin: coin }))))
        (map-set PriceHistory
            { coin: coin }
            { prices: (unwrap-panic (as-max-len? (append (get prices current-history) price) u10)) }
        )
    )
)

(define-private (calculate-moving-average (prices (list 10 uint)))
    (let ((sum (fold + prices u0))
          (count (len prices)))
        (if (> count u0)
            (/ sum count)
            u0
        )
    )
)

(define-private (generate-trading-signal (coin (string-ascii 10)) (current-data {
    current-price: uint,
    previous-price: uint,
    timestamp: uint,
    percentage-change: int,
    is-profitable: bool,
    highest-price: uint,
    lowest-price: uint,
    volume: uint,
    moving-average: uint
}))
    (let ((ma (get moving-average current-data))
          (price (get current-price current-data))
          (volume (get volume current-data)))
        (if (and (> price ma) (> volume u1000000))
            (map-set TradingSignals
                { coin: coin }
                {
                    signal: "BUY",
                    strength: u75,
                    timestamp: block-height
                }
            )
            (map-set TradingSignals
                { coin: coin }
                {
                    signal: "SELL",
                    strength: u25,
                    timestamp: block-height
                }
            )
        )
    )
)

;; Public functions

(define-public (set-coin-data (coin (string-ascii 10)) (price uint) (volume uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (> price u0) err-invalid-price)
        (asserts! (validate-coin coin) err-invalid-coin)
        
        (let ((existing-data (unwrap-panic (get-coin-data coin)))
              (history (update-price-history coin price)))
            
        (let ((new-data {
                current-price: price,
                previous-price: (get current-price existing-data),
                timestamp: block-height,
                percentage-change: (calculate-percentage-change (get current-price existing-data) price),
                is-profitable: (> price (get current-price existing-data)),
                highest-price: (if (> price (get highest-price existing-data))
                                price
                                (get highest-price existing-data)),
                lowest-price: (if (< price (get lowest-price existing-data))
                                price
                                (get lowest-price existing-data)),
                volume: volume,
                moving-average: (calculate-moving-average (get prices (default-to { prices: (list ) } (map-get? PriceHistory { coin: coin }))))
            }))
            
            (map-set CoinPrices { coin: coin } new-data)
            (generate-trading-signal coin new-data)
            (ok true)
        ))
    )
)

(define-public (set-risk-parameters (coin (string-ascii 10)) (stop-loss uint) (take-profit uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (validate-coin coin) err-invalid-coin)
        (ok (map-set ProfitabilitySettings
            { coin: coin }
            { 
                threshold: (default-to u200 (get threshold (get-profitability-threshold coin))),
                stop-loss: stop-loss,
                take-profit: take-profit
            }
        ))
    )
)

;; Read-only functions

(define-read-only (get-coin-data (coin (string-ascii 10)))
    (ok (default-to {
        current-price: u0,
        previous-price: u0,
        timestamp: u0,
        percentage-change: 0,
        is-profitable: false,
        highest-price: u0,
        lowest-price: u0,
        volume: u0,
        moving-average: u0
    } (map-get? CoinPrices { coin: coin })))
)

(define-read-only (get-trading-signal (coin (string-ascii 10)))
    (ok (default-to {
        signal: "NONE",
        strength: u0,
        timestamp: u0
    } (map-get? TradingSignals { coin: coin })))
)

(define-read-only (get-profitability-threshold (coin (string-ascii 10)))
    (default-to
        { threshold: u200, stop-loss: u0, take-profit: u0 }
        (map-get? ProfitabilitySettings { coin: coin })
    )
)

(define-read-only (get-price-history (coin (string-ascii 10)))
    (ok (default-to
        { prices: (list ) }
        (map-get? PriceHistory { coin: coin })
    ))
)