;; crypto-analyzer
;; Contract for analyzing cryptocurrency prices and potential gains/losses

;; Constants
(define-constant contract-owner tx-sender)
(define-constant PERCENTAGE_MULTIPLIER u100)

;; Error codes
(define-constant err-owner-only (err u100))
(define-constant err-invalid-price (err u101))
(define-constant err-no-previous-price (err u102))
(define-constant err-invalid-coin (err u103))
(define-constant err-invalid-threshold (err u104))

;; Define data maps for storing coin information
(define-map CoinPrices
    { coin: (string-ascii 10) }
    {
        current-price: uint,
        previous-price: uint,
        timestamp: uint,
        percentage-change: int,
        is-profitable: bool
    }
)

(define-map ProfitabilitySettings
    { coin: (string-ascii 10) }
    { threshold: uint }
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

(define-private (check-profitability (coin (string-ascii 10)) (change int))
    (let ((threshold-data (get-profitability-threshold coin)))
        (>= change (to-int (get threshold threshold-data)))
    )
)

(define-private (update-coin-data (coin (string-ascii 10)) (price uint) (existing-data (optional {
        current-price: uint,
        previous-price: uint,
        timestamp: uint,
        percentage-change: int,
        is-profitable: bool
    })))
    (let ((current-data (default-to {
            current-price: u0,
            previous-price: u0,
            timestamp: u0,
            percentage-change: 0,
            is-profitable: false
        } existing-data)))
        (ok {
            current-price: price,
            previous-price: (get current-price current-data),
            timestamp: block-height,
            percentage-change: (calculate-percentage-change 
                (get current-price current-data) 
                price
            ),
            is-profitable: (check-profitability coin 
                (calculate-percentage-change 
                    (get current-price current-data) 
                    price
                )
            )
        })
    )
)
;; Public functions

(define-public (set-coin-price (coin (string-ascii 10)) (price uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (> price u0) err-invalid-price)
        (asserts! (validate-coin coin) err-invalid-coin)
        
        (let ((new-data (unwrap! (update-coin-data coin price (map-get? CoinPrices { coin: coin })) err-invalid-coin)))
            (ok (map-set CoinPrices
                { coin: coin }
                new-data
            ))
        )
    )
)

(define-public (set-profitability-threshold (coin (string-ascii 10)) (threshold uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (validate-coin coin) err-invalid-coin)
        (asserts! (> threshold u0) err-invalid-threshold)
        (ok (map-set ProfitabilitySettings
            { coin: coin }
            { threshold: threshold }
        ))
    )
)

;; Read-only functions

(define-read-only (get-coin-data (coin (string-ascii 10)))
    (match (map-get? CoinPrices { coin: coin })
        entry (ok entry)
        (ok {
            current-price: u0,
            previous-price: u0,
            timestamp: u0,
            percentage-change: 0,
            is-profitable: false
        })
    )
)

(define-read-only (get-profitability-threshold (coin (string-ascii 10)))
    (default-to
        { threshold: u200 } ;; Default 2% threshold (multiplied by 100)
        (map-get? ProfitabilitySettings { coin: coin })
    )
)
