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

;; Helper functions
(define-private (calculate-sma (prices (list 30 uint)))
    (let ((sum (fold + prices u0)))
        (/ sum (len prices))
    )
)

(define-private (get-trend (current-price uint) (sma7 uint) (sma30 uint))
    (if (and (> current-price sma7) (> sma7 sma30))
        "bullish"
        (if (and (< current-price sma7) (< sma7 sma30))
            "bearish"
            "neutral"
        )
    )
)

;; Public functions
(define-public (update-analytics (base-contract <base-trait>) (coin (string-utf8 10)))
    (let ((coin-data (try! (contract-call? base-contract get-coin-data coin))))
        (let ((current-price (get current-price coin-data))
              (history (default-to {prices: (list)} (map-get? price-history {coin: coin}))))
            (let ((new-prices (unwrap! (as-max-len? (append (get prices history) current-price) u30) err-history-full)))
                (let ((sma7 (calculate-sma new-prices))
                      (sma30 (calculate-sma new-prices)))
                    (begin
                        (map-set price-history {coin: coin} {prices: new-prices})
                        (map-set moving-averages
                            {coin: coin}
                            {
                                sma-7: sma7,
                                sma-30: sma30,
                                volatility: (/ (* sma7 PERCENTAGE_MULTIPLIER) sma30)
                            }
                        )
                        (ok (map-set trading-signals
                            {coin: coin}
                            {
                                trend: (get-trend current-price sma7 sma30),
                                strength: (/ (* (- sma7 sma30) PERCENTAGE_MULTIPLIER) sma30),
                                support: (fold min new-prices current-price),
                                resistance: (fold max new-prices current-price)
                            }
                        ))
                    )
                )
            )
        )
    )
)

;; Read-only functions
(define-read-only (get-analytics (coin (string-utf8 10)))
    (ok {
        history: (map-get? price-history {coin: coin}),
        averages: (map-get? moving-averages {coin: coin}),
        signals: (map-get? trading-signals {coin: coin})
    })
)

(define-read-only (get-momentum (coin (string-utf8 10)))
    (let ((avgs (default-to 
            {sma-7: u0, sma-30: u0, volatility: u0} 
            (map-get? moving-averages {coin: coin}))))
        (ok {
            short-term: (get sma-7 avgs),
            long-term: (get sma-30 avgs),
            momentum: (- (get sma-7 avgs) (get sma-30 avgs))
        })
    )
)

(define-read-only (is-golden-cross (coin (string-utf8 10)))
    (let ((avgs (default-to 
            {sma-7: u0, sma-30: u0, volatility: u0}
            (map-get? moving-averages {coin: coin}))))
        (ok (and
            (> (get sma-7 avgs) (get sma-30 avgs))
            (> (get sma-7 avgs) u0)
            (> (get sma-30 avgs) u0)
        ))
    )
)
