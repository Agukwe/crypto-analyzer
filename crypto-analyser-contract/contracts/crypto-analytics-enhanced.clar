;; Import the trait from the base contract
(use-trait base-trait .crypto-analyzer.crypto-analyzer-trait)

;; Contract constants
(define-constant contract-owner tx-sender)
(define-constant PERCENTAGE_MULTIPLIER u100)
(define-constant MAX_HISTORY_LENGTH u30)
(define-constant err-owner-only (err u200))
(define-constant err-invalid-window (err u201))
(define-constant err-history-full (err u202))

;; Data storage
(define-map price-history 
    {coin: (string-utf8 10)} 
    {prices: (list 30 uint)}
)

(define-map moving-averages
    {coin: (string-utf8 10)}
    {
        sma-7: uint,
        sma-30: uint,
        volatility: uint
    }
)

(define-map trading-signals
    {coin: (string-utf8 10)}
    {
        trend: (string-utf8 10),
        strength: uint,
        support: uint,
        resistance: uint
    }
)
