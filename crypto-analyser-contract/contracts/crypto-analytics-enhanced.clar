;; Import the trait from the base contract
(use-trait base-trait .crypto-analyzer.crypto-analyzer-trait)

;; Contract constants
(define-constant contract-owner tx-sender)
(define-constant PERCENTAGE_MULTIPLIER u100)
(define-constant MAX_HISTORY_LENGTH u30)
(define-constant err-owner-only (err u200))
(define-constant err-invalid-window (err u201))
(define-constant err-history-full (err u202))
