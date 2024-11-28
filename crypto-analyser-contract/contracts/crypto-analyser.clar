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