;; Service Agreement Smart Contract
;; Enables creation and management of service agreements between service providers and clients

;; Error codes
(define-constant error-unauthorized-access (err u100))
(define-constant error-agreement-exists (err u101))
(define-constant error-agreement-not-found (err u102))
(define-constant error-invalid-agreement-status (err u103))
(define-constant error-insufficient-payment (err u104))

;; Contract data maps and variables
(define-data-var contract-administrator principal tx-sender)
(define-map ServiceAgreementDetails
    { service-agreement-id: uint }
    {
        service-provider-address: principal,
        client-address: principal,
        service-start-date: uint,
        service-end-date: uint,
        service-payment-amount: uint,
        agreement-status: (string-ascii 20),
        service-description: (string-ascii 256)
    }
)

(define-map ServiceProviderMetrics
    { service-provider-address: principal }
    {
        provider-rating: uint,
        total-service-agreements: uint,
        successfully-completed-agreements: uint
    }
)

(define-map ServiceDisputeRecords
    { service-agreement-id: uint }
    {
        dispute-initiator: principal,
        dispute-description: (string-ascii 256),
        dispute-status: (string-ascii 20),
        dispute-resolution: (optional (string-ascii 256))
    }
)

;; Initialize contract
(define-public (initialize-contract (administrator-address principal))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-administrator)) error-unauthorized-access)
        (ok (var-set contract-administrator administrator-address))
    )
)

;; Create new service agreement
(define-public (create-service-agreement 
    (service-agreement-id uint)
    (service-provider-address principal)
    (client-address principal)
    (service-start-date uint)
    (service-end-date uint)
    (service-payment-amount uint)
    (service-description (string-ascii 256)))
    
    (let
        ((existing-service-agreement (get-service-agreement-details service-agreement-id)))
        (asserts! (is-none existing-service-agreement) error-agreement-exists)
        (asserts! (>= service-end-date service-start-date) error-invalid-agreement-status)
        (asserts! (> service-payment-amount u0) error-invalid-agreement-status)
        
        (map-set ServiceAgreementDetails
            { service-agreement-id: service-agreement-id }
            {
                service-provider-address: service-provider-address,
                client-address: client-address,
                service-start-date: service-start-date,
                service-end-date: service-end-date,
                service-payment-amount: service-payment-amount,
                agreement-status: "PENDING",
                service-description: service-description
            }
        )
        
        ;; Initialize or update provider metrics
        (match (map-get? ServiceProviderMetrics { service-provider-address: service-provider-address })
            existing-metrics
            (map-set ServiceProviderMetrics
                { service-provider-address: service-provider-address }
                {
                    provider-rating: (get provider-rating existing-metrics),
                    total-service-agreements: (+ (get total-service-agreements existing-metrics) u1),
                    successfully-completed-agreements: (get successfully-completed-agreements existing-metrics)
                }
            )
            (map-set ServiceProviderMetrics
                { service-provider-address: service-provider-address }
                {
                    provider-rating: u0,
                    total-service-agreements: u1,
                    successfully-completed-agreements: u0
                }
            )
        )
        (ok true)
    )
)

;; Accept service agreement
(define-public (accept-service-agreement (service-agreement-id uint))
    (let
        ((agreement-details (unwrap! (get-service-agreement-details service-agreement-id) error-agreement-not-found)))
        (asserts! (is-eq (get agreement-status agreement-details) "PENDING") error-invalid-agreement-status)
        (asserts! (is-eq tx-sender (get service-provider-address agreement-details)) error-unauthorized-access)
        
        (map-set ServiceAgreementDetails
            { service-agreement-id: service-agreement-id }
            (merge agreement-details { agreement-status: "ACTIVE" })
        )
        (ok true)
    )
)

;; Complete service agreement
(define-public (complete-service-agreement (service-agreement-id uint))
    (let
        ((agreement-details (unwrap! (get-service-agreement-details service-agreement-id) error-agreement-not-found)))
        (asserts! (is-eq (get agreement-status agreement-details) "ACTIVE") error-invalid-agreement-status)
        (asserts! (is-eq tx-sender (get client-address agreement-details)) error-unauthorized-access)
        
        ;; Update agreement status
        (map-set ServiceAgreementDetails
            { service-agreement-id: service-agreement-id }
            (merge agreement-details { agreement-status: "COMPLETED" })
        )
        
        ;; Update provider metrics
        (let ((provider-metrics (unwrap! (map-get? ServiceProviderMetrics 
                { service-provider-address: (get service-provider-address agreement-details) }) 
                error-agreement-not-found)))
            (map-set ServiceProviderMetrics
                { service-provider-address: (get service-provider-address agreement-details) }
                (merge provider-metrics {
                    successfully-completed-agreements: (+ (get successfully-completed-agreements provider-metrics) u1)
                })
            )
            (ok true)
        )
    )
)

;; File service dispute
(define-public (file-service-dispute 
    (service-agreement-id uint)
    (dispute-description (string-ascii 256)))
    
    (let
        ((agreement-details (unwrap! (get-service-agreement-details service-agreement-id) error-agreement-not-found)))
        (asserts! (or
            (is-eq tx-sender (get service-provider-address agreement-details))
            (is-eq tx-sender (get client-address agreement-details))
        ) error-unauthorized-access)
        
        (map-set ServiceDisputeRecords
            { service-agreement-id: service-agreement-id }
            {
                dispute-initiator: tx-sender,
                dispute-description: dispute-description,
                dispute-status: "PENDING",
                dispute-resolution: none
            }
        )
        
        (map-set ServiceAgreementDetails
            { service-agreement-id: service-agreement-id }
            (merge agreement-details { agreement-status: "DISPUTED" })
        )
        (ok true)
    )
)

;; Resolve service dispute
(define-public (resolve-service-dispute
    (service-agreement-id uint)
    (resolution-description (string-ascii 256))
    (new-agreement-status (string-ascii 20)))
    
    (let
        ((agreement-details (unwrap! (get-service-agreement-details service-agreement-id) error-agreement-not-found))
         (dispute-details (unwrap! (get-dispute-details service-agreement-id) error-agreement-not-found)))
        
        (asserts! (is-eq tx-sender (var-get contract-administrator)) error-unauthorized-access)
        (asserts! (is-eq (get agreement-status agreement-details) "DISPUTED") error-invalid-agreement-status)
        
        ;; Update dispute record
        (map-set ServiceDisputeRecords
            { service-agreement-id: service-agreement-id }
            (merge dispute-details {
                dispute-status: "RESOLVED",
                dispute-resolution: (some resolution-description)
            })
        )
        
        ;; Update agreement status
        (map-set ServiceAgreementDetails
            { service-agreement-id: service-agreement-id }
            (merge agreement-details { agreement-status: new-agreement-status })
        )
        (ok true)
    )
)

;; Rate service provider
(define-public (submit-provider-rating 
    (service-provider-address principal)
    (rating-score uint))
    
    (let
        ((provider-metrics (unwrap! (map-get? ServiceProviderMetrics { service-provider-address: service-provider-address }) error-agreement-not-found)))
        (asserts! (<= rating-score u5) error-invalid-agreement-status)
        (asserts! (> rating-score u0) error-invalid-agreement-status)
        
        (map-set ServiceProviderMetrics
            { service-provider-address: service-provider-address }
            (merge provider-metrics {
                provider-rating: (/ (+ (* (get provider-rating provider-metrics) 
                               (get total-service-agreements provider-metrics)) 
                            rating-score)
                         (+ (get total-service-agreements provider-metrics) u1))
            })
        )
        (ok true)
    )
)

;; Getter functions
(define-read-only (get-service-agreement-details (service-agreement-id uint))
    (map-get? ServiceAgreementDetails { service-agreement-id: service-agreement-id })
)

(define-read-only (get-provider-metrics (service-provider-address principal))
    (map-get? ServiceProviderMetrics { service-provider-address: service-provider-address })
)

(define-read-only (get-dispute-details (service-agreement-id uint))
    (map-get? ServiceDisputeRecords { service-agreement-id: service-agreement-id })
)

;; Helper functions
(define-private (is-valid-agreement-status (agreement-status (string-ascii 20)))
    (or
        (is-eq agreement-status "PENDING")
        (is-eq agreement-status "ACTIVE")
        (is-eq agreement-status "COMPLETED")
        (is-eq agreement-status "DISPUTED")
        (is-eq agreement-status "CANCELLED")
    )
)