;; Mental Health Support Network Smart Contract
;; Facilitates donations to mental health initiatives, manages recipient eligibility,
;; and provides transparent distribution of support funds to verified beneficiaries

;; Error Constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-RECIPIENT-ALREADY-REGISTERED (err u101))
(define-constant ERR-RECIPIENT-NOT-REGISTERED (err u102))
(define-constant ERR-FUNDS-UNAVAILABLE (err u103))
(define-constant ERR-CONTRIBUTION-TOO-SMALL (err u104))
(define-constant ERR-PROGRAM-PAUSED (err u105))
(define-constant ERR-CONTRIBUTION-INVALID (err u106))
(define-constant ERR-STATUS-CODE-INVALID (err u107))
(define-constant ERR-INVALID-SUPERVISOR-ADDRESS (err u108))

;; Core Program Variables
(define-data-var program-supervisor principal tx-sender)
(define-data-var treasury-balance uint u0)
(define-data-var program-is-operating bool true)
(define-data-var contribution-floor uint u1000000) ;; 1 STX
(define-data-var crisis-mode-active bool false)

;; Data Storage
(define-map recipient-directory 
    principal 
    {
        enrollment-active: bool,
        aid-received: uint,
        last-aid-block: uint,
        current-status: (string-ascii 20)
    }
)

(define-map supporter-directory
    principal
    {
        total-support-provided: uint,
        latest-support-block: uint
    }
)

;; Read-only Functions
(define-read-only (get-program-supervisor)
    (var-get program-supervisor)
)

(define-read-only (get-treasury-balance)
    (var-get treasury-balance)
)

(define-read-only (get-recipient-info (recipient-address principal))
    (map-get? recipient-directory recipient-address)
)

(define-read-only (get-supporter-info (supporter-address principal))
    (map-get? supporter-directory supporter-address)
)

(define-read-only (check-program-status)
    (and (var-get program-is-operating) (not (var-get crisis-mode-active)))
)

;; Helper Functions
(define-private (is-supervisor)
    (is-eq tx-sender (var-get program-supervisor))
)

(define-private (record-contribution (supporter-address principal) (contribution-amount uint))
    (let (
        (supporter-record (default-to 
            { total-support-provided: u0, latest-support-block: u0 } 
            (map-get? supporter-directory supporter-address)
        ))
    )
    (map-set supporter-directory
        supporter-address
        {
            total-support-provided: (+ (get total-support-provided supporter-record) contribution-amount),
            latest-support-block: block-height
        }
    ))
)

;; Validation Functions
(define-private (is-contribution-valid (amount uint))
    (and 
        (> amount u0)
        (<= amount u1000000000000) ;; Upper limit for sanity check
    )
)

(define-private (is-status-valid (status-code (string-ascii 20)))
    (or 
        (is-eq status-code "active")
        (is-eq status-code "pending")
        (is-eq status-code "suspended")
        (is-eq status-code "completed")
    )
)

(define-private (can-be-supervisor (candidate-address principal))
    (and 
        (not (is-eq candidate-address (var-get program-supervisor)))
        (not (is-eq candidate-address (as-contract tx-sender)))
    )
)

;; Public Functions
(define-public (provide-support)
    (let (
        (support-amount (stx-get-balance tx-sender))
    )
    (asserts! (>= support-amount (var-get contribution-floor)) ERR-CONTRIBUTION-TOO-SMALL)
    (asserts! (check-program-status) ERR-PROGRAM-PAUSED)
    
    (try! (stx-transfer? support-amount tx-sender (as-contract tx-sender)))
    (var-set treasury-balance (+ (var-get treasury-balance) support-amount))
    (record-contribution tx-sender support-amount)
    (ok support-amount))
)

;; Recipient Management
(define-public (enroll-recipient (recipient-address principal))
    (begin
        (asserts! (is-supervisor) ERR-NOT-AUTHORIZED)
        (asserts! (is-none (map-get? recipient-directory recipient-address)) ERR-RECIPIENT-ALREADY-REGISTERED)
        
        (map-set recipient-directory 
            recipient-address
            {
                enrollment-active: true,
                aid-received: u0,
                last-aid-block: u0,
                current-status: "active"
            }
        )
        (ok true)
    )
)

(define-public (distribute-aid (recipient-address principal) (aid-amount uint))
    (begin
        (asserts! (is-supervisor) ERR-NOT-AUTHORIZED)
        (asserts! (check-program-status) ERR-PROGRAM-PAUSED)
        (asserts! (>= (var-get treasury-balance) aid-amount) ERR-FUNDS-UNAVAILABLE)
        (asserts! 
            (is-some (map-get? recipient-directory recipient-address)) 
            ERR-RECIPIENT-NOT-REGISTERED
        )
        
        (try! (as-contract (stx-transfer? aid-amount tx-sender recipient-address)))
        (var-set treasury-balance (- (var-get treasury-balance) aid-amount))
        
        (let (
            (recipient-info (unwrap! (map-get? recipient-directory recipient-address) ERR-RECIPIENT-NOT-REGISTERED))
        )
        (map-set recipient-directory
            recipient-address
            {
                enrollment-active: (get enrollment-active recipient-info),
                aid-received: (+ (get aid-received recipient-info) aid-amount),
                last-aid-block: block-height,
                current-status: (get current-status recipient-info)
            }
        )
        (ok aid-amount))
    )
)

;; Administrative Functions
(define-public (set-contribution-floor (new-floor uint))
    (begin
        (asserts! (is-supervisor) ERR-NOT-AUTHORIZED)
        (asserts! (is-contribution-valid new-floor) ERR-CONTRIBUTION-INVALID)
        (var-set contribution-floor new-floor)
        (ok true)
    )
)

(define-public (toggle-program-status)
    (begin
        (asserts! (is-supervisor) ERR-NOT-AUTHORIZED)
        (var-set program-is-operating (not (var-get program-is-operating)))
        (ok true)
    )
)

(define-public (set-crisis-mode-on)
    (begin
        (asserts! (is-supervisor) ERR-NOT-AUTHORIZED)
        (var-set crisis-mode-active true)
        (ok true)
    )
)

(define-public (set-crisis-mode-off)
    (begin
        (asserts! (is-supervisor) ERR-NOT-AUTHORIZED)
        (var-set crisis-mode-active false)
        (ok true)
    )
)

(define-public (update-recipient-status (recipient-address principal) (new-status (string-ascii 20)))
    (begin
        (asserts! (is-supervisor) ERR-NOT-AUTHORIZED)
        (asserts! (is-status-valid new-status) ERR-STATUS-CODE-INVALID)
        (asserts! 
            (is-some (map-get? recipient-directory recipient-address)) 
            ERR-RECIPIENT-NOT-REGISTERED
        )
        
        (let (
            (current-info (unwrap! (map-get? recipient-directory recipient-address) ERR-RECIPIENT-NOT-REGISTERED))
        )
        (map-set recipient-directory
            recipient-address
            {
                enrollment-active: (get enrollment-active current-info),
                aid-received: (get aid-received current-info),
                last-aid-block: (get last-aid-block current-info),
                current-status: new-status
            }
        )
        (ok true))
    )
)

;; Governance Function
(define-public (change-supervisor (new-supervisor-address principal))
    (begin
        (asserts! (is-supervisor) ERR-NOT-AUTHORIZED)
        (asserts! (can-be-supervisor new-supervisor-address) ERR-INVALID-SUPERVISOR-ADDRESS)
        (var-set program-supervisor new-supervisor-address)
        (ok true)
    )
)