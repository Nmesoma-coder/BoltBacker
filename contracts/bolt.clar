;; BoltBacker Platform Smart Contract
;; Decentralized crowdfunding platform for innovative projects with milestone-based funding

;; Error Constants
(define-constant PLATFORM-GUARDIAN tx-sender)
(define-constant ERR-UNAUTHORIZED-ACCESS (err u100))
(define-constant ERR-INSUFFICIENT-TREASURY (err u101))
(define-constant ERR-PROJECT-NOT-FOUND (err u102))
(define-constant ERR-CAMPAIGN-INACTIVE (err u103))
(define-constant ERR-MILESTONE-ALREADY-ACHIEVED (err u104))
(define-constant ERR-INVALID-MILESTONE-ID (err u105))
(define-constant ERR-NO-REFUND-AVAILABLE (err u106))
(define-constant ERR-REFUND-ALREADY-CLAIMED (err u107))
(define-constant ERR-PROJECT-SUCCESSFULLY-FUNDED (err u108))
(define-constant ERR-INVALID-PARAMETERS (err u109))
(define-constant ERR-MILESTONES-INCOMPLETE (err u110))

;; Project structure
(define-map innovation-projects
  { project-id: uint }
  {
    visionary: principal,
    title: (string-utf8 100),
    description: (string-utf8 500),
    target-treasury: uint,
    raised-treasury: uint,
    deadline-block: uint,
    is-active: bool,
    is-completed: bool,
    milestones: (list 5 { description: (string-utf8 200), treasury-allocation: uint, achieved: bool })
  }
)

;; Investor tracking with refund status
(define-map project-investors 
  { project-id: uint, investor: principal } 
  { 
    investment-amount: uint,
    refund-claimed: bool 
  }
)

;; Unique project ID counter
(define-data-var next-project-id uint u0)

;; Helper function to check if all milestones are achieved
(define-read-only (all-milestones-achieved? (milestones (list 5 { description: (string-utf8 200), treasury-allocation: uint, achieved: bool })))
  (is-eq (len (filter is-milestone-achieved milestones)) (len milestones))
)

;; Helper function to check if a milestone is achieved
(define-read-only (is-milestone-achieved (milestone { description: (string-utf8 200), treasury-allocation: uint, achieved: bool }))
  (get achieved milestone)
)

;; Launch a new innovation project
(define-public (launch-project 
  (title (string-utf8 100))
  (description (string-utf8 500))
  (target-treasury uint)
  (deadline-block uint)
  (milestones (list 5 { description: (string-utf8 200), treasury-allocation: uint }))
)
  (let 
    (
      (project-id (var-get next-project-id))
      (total-milestone-treasury (fold + (map get-milestone-treasury milestones) u0))
    )
    ;; Validate inputs
    (asserts! (> (len title) u0) ERR-INVALID-PARAMETERS)
    (asserts! (> (len description) u0) ERR-INVALID-PARAMETERS)
    (asserts! (> target-treasury u0) ERR-INVALID-PARAMETERS)
    (asserts! (> deadline-block block-height) ERR-INVALID-PARAMETERS)
    (asserts! (>= target-treasury total-milestone-treasury) ERR-INSUFFICIENT-TREASURY)
    
    ;; Create project map entry
    (map-set innovation-projects 
      { project-id: project-id }
      {
        visionary: tx-sender,
        title: title,
        description: description,
        target-treasury: target-treasury,
        raised-treasury: u0,
        deadline-block: deadline-block,
        is-active: true,
        is-completed: false,
        milestones: (map prepare-milestone milestones)
      }
    )
    
    ;; Increment project ID
    (var-set next-project-id (+ project-id u1))
    
    ;; Return project ID
    (ok project-id)
  )
)

;; Helper function to get milestone treasury allocation
(define-read-only (get-milestone-treasury (milestone { description: (string-utf8 200), treasury-allocation: uint }))
  (get treasury-allocation milestone)
)

;; Helper function to prepare milestone
(define-read-only (prepare-milestone (milestone { description: (string-utf8 200), treasury-allocation: uint }))
  { description: (get description milestone), treasury-allocation: (get treasury-allocation milestone), achieved: false }
)

;; Get milestone by index
(define-private (get-milestone-by-index 
  (project-milestones (list 5 { description: (string-utf8 200), treasury-allocation: uint, achieved: bool })) 
  (milestone-index uint)
)
  (element-at project-milestones milestone-index)
)

;; Update milestone in list
(define-private (update-milestone-list 
  (milestones (list 5 { description: (string-utf8 200), treasury-allocation: uint, achieved: bool })) 
  (milestone-index uint)
  (updated-milestone { description: (string-utf8 200), treasury-allocation: uint, achieved: bool })
)
  (let
    (
      (prefix (unwrap! (slice? milestones u0 milestone-index) milestones))
      (suffix (unwrap! (slice? milestones (+ milestone-index u1) (len milestones)) milestones))
    )
    (unwrap-panic 
      (as-max-len? 
        (concat
          prefix
          (unwrap-panic 
            (as-max-len? 
              (concat 
                (list updated-milestone)
                suffix
              )
              u5
            )
          )
        )
        u5
      )
    )
  )
)

;; Check if project is eligible for refunds
(define-read-only (is-refund-eligible (project-id uint))
  (match (map-get? innovation-projects { project-id: project-id })
    project (and 
      (>= block-height (get deadline-block project))
      (< (get raised-treasury project) (get target-treasury project))
      (get is-active project)
    )
    false
  )
)

;; Invest in a project
(define-public (invest-in-project (project-id uint) (stx-investment uint))
  (let 
    (
      (project (unwrap! (map-get? innovation-projects { project-id: project-id }) ERR-PROJECT-NOT-FOUND))
      (current-investment (default-to { investment-amount: u0, refund-claimed: false } 
        (map-get? project-investors { project-id: project-id, investor: tx-sender })))
    )
    ;; Validate inputs
    (asserts! (> project-id u0) ERR-INVALID-PARAMETERS)
    (asserts! (> stx-investment u0) ERR-INVALID-PARAMETERS)
    
    ;; Validate project is active and not past deadline
    (asserts! (get is-active project) ERR-CAMPAIGN-INACTIVE)
    (asserts! (< block-height (get deadline-block project)) ERR-CAMPAIGN-INACTIVE)
    
    ;; Update investors
    (map-set project-investors 
      { project-id: project-id, investor: tx-sender }
      { investment-amount: (+ (get investment-amount current-investment) stx-investment), refund-claimed: false }
    )
    
    ;; Update project raised treasury
    (map-set innovation-projects 
      { project-id: project-id }
      (merge project { raised-treasury: (+ (get raised-treasury project) stx-investment) })
    )
    
    (ok true)
  )
)

;; Claim refund for a failed project
(define-public (claim-refund (project-id uint))
  (let
    (
      (project (unwrap! (map-get? innovation-projects { project-id: project-id }) ERR-PROJECT-NOT-FOUND))
      (investment (unwrap! (map-get? project-investors { project-id: project-id, investor: tx-sender }) 
        ERR-NO-REFUND-AVAILABLE))
    )
    ;; Validate input
    (asserts! (> project-id u0) ERR-INVALID-PARAMETERS)
    
    ;; Check refund eligibility
    (asserts! (is-refund-eligible project-id) ERR-PROJECT-SUCCESSFULLY-FUNDED)
    (asserts! (not (get refund-claimed investment)) ERR-REFUND-ALREADY-CLAIMED)
    
    ;; Process refund
    (try! (stx-transfer? (get investment-amount investment) tx-sender PLATFORM-GUARDIAN))
    
    ;; Mark investment as refund claimed
    (map-set project-investors
      { project-id: project-id, investor: tx-sender }
      (merge investment { refund-claimed: true })
    )
    
    (ok true)
  )
)

;; Close failed project and enable refunds
(define-public (close-failed-project (project-id uint))
  (let
    (
      (project (unwrap! (map-get? innovation-projects { project-id: project-id }) ERR-PROJECT-NOT-FOUND))
    )
    ;; Validate input
    (asserts! (> project-id u0) ERR-INVALID-PARAMETERS)
    
    ;; Verify project has failed
    (asserts! (>= block-height (get deadline-block project)) ERR-CAMPAIGN-INACTIVE)
    (asserts! (< (get raised-treasury project) (get target-treasury project)) ERR-PROJECT-SUCCESSFULLY-FUNDED)
    (asserts! (get is-active project) ERR-CAMPAIGN-INACTIVE)
    
    ;; Update project status
    (map-set innovation-projects
      { project-id: project-id }
      (merge project { is-active: false })
    )
    
    (ok true)
  )
)

;; Achieve milestone
(define-public (achieve-milestone (project-id uint) (milestone-index uint))
  (let 
    (
      (project (unwrap! (map-get? innovation-projects { project-id: project-id }) ERR-PROJECT-NOT-FOUND))
      (milestones (get milestones project))
      (milestone-opt (get-milestone-by-index milestones milestone-index))
      (milestone (unwrap! milestone-opt ERR-INVALID-MILESTONE-ID))
    )
    ;; Validate inputs
    (asserts! (> project-id u0) ERR-INVALID-PARAMETERS)
    (asserts! (< milestone-index (len milestones)) ERR-INVALID-PARAMETERS)
    
    ;; Only project visionary can achieve milestones
    (asserts! (is-eq tx-sender (get visionary project)) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (not (get achieved milestone)) ERR-MILESTONE-ALREADY-ACHIEVED)
    
    ;; Update milestone achievement
    (map-set innovation-projects 
      { project-id: project-id }
      (merge project { milestones: (update-milestone-list milestones milestone-index (merge milestone { achieved: true })) })
    )
    
    (ok true)
  )
)

;; Complete project function
(define-public (complete-project (project-id uint))
  (let
    (
      (project (unwrap! (map-get? innovation-projects { project-id: project-id }) ERR-PROJECT-NOT-FOUND))
    )
    ;; Validate inputs
    (asserts! (> project-id u0) ERR-INVALID-PARAMETERS)
    
    ;; Only project visionary can complete the project
    (asserts! (is-eq tx-sender (get visionary project)) ERR-UNAUTHORIZED-ACCESS)
    
    ;; Check if project is active
    (asserts! (get is-active project) ERR-CAMPAIGN-INACTIVE)
    
    ;; Check if all milestones are achieved
    (asserts! (all-milestones-achieved? (get milestones project)) ERR-MILESTONES-INCOMPLETE)
    
    ;; Update project status
    (map-set innovation-projects
      { project-id: project-id }
      (merge project 
        { 
          is-active: false,
          is-completed: true
        }
      )
    )
    
    (ok true)
  )
)