(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u401))
(define-constant ERR-NOT-FOUND (err u404))
(define-constant ERR-ALREADY-EXISTS (err u409))
(define-constant ERR-INVALID-INPUT (err u400))
(define-constant ERR-INSUFFICIENT-BALANCE (err u402))

(define-data-var next-meeting-id uint u1)
(define-data-var next-decision-id uint u1)
(define-data-var contract-admin principal CONTRACT-OWNER)

(define-data-var next-proposal-id uint u1)

(define-map authorized-officials principal bool)
(define-map meeting-records uint {
    title: (string-utf8 256),
    date: uint,
    location: (string-utf8 128),
    organizer: principal,
    participants: (list 50 principal),
    agenda: (string-utf8 1024),
    minutes: (string-utf8 2048),
    status: (string-ascii 16),
    block-height: uint
})

(define-map meeting-decisions uint {
    meeting-id: uint,
    title: (string-utf8 256),
    description: (string-utf8 1024),
    proposer: principal,
    votes-for: uint,
    votes-against: uint,
    votes-abstain: uint,
    status: (string-ascii 16),
    decision-date: uint,
    block-height: uint
})

(define-map decision-votes {decision-id: uint, voter: principal} {
    vote: (string-ascii 16),
    vote-date: uint
})

(define-map meeting-attendance {meeting-id: uint, participant: principal} {
    attended: bool,
    role: (string-ascii 32)
})

(define-read-only (get-meeting-record (meeting-id uint))
    (map-get? meeting-records meeting-id)
)

(define-read-only (get-decision-record (decision-id uint))
    (map-get? meeting-decisions decision-id)
)

(define-read-only (get-decision-vote (decision-id uint) (voter principal))
    (map-get? decision-votes {decision-id: decision-id, voter: voter})
)

(define-read-only (get-meeting-attendance (meeting-id uint) (participant principal))
    (map-get? meeting-attendance {meeting-id: meeting-id, participant: participant})
)

(define-read-only (is-authorized-official (user principal))
    (default-to false (map-get? authorized-officials user))
)

(define-read-only (get-next-meeting-id)
    (var-get next-meeting-id)
)

(define-read-only (get-next-decision-id)
    (var-get next-decision-id)
)

(define-read-only (get-contract-admin)
    (var-get contract-admin)
)

(define-public (authorize-official (official principal))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-UNAUTHORIZED)
        (ok (map-set authorized-officials official true))
    )
)

(define-public (revoke-official (official principal))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-UNAUTHORIZED)
        (ok (map-set authorized-officials official false))
    )
)

(define-public (transfer-admin (new-admin principal))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-UNAUTHORIZED)
        (var-set contract-admin new-admin)
        (ok true)
    )
)

(define-public (create-meeting-record 
    (title (string-utf8 256))
    (date uint)
    (location (string-utf8 128))
    (participants (list 50 principal))
    (agenda (string-utf8 1024))
    (minutes (string-utf8 2048))
)
    (let (
        (meeting-id (var-get next-meeting-id))
        (current-height stacks-block-height)
    )
        (asserts! (is-authorized-official tx-sender) ERR-UNAUTHORIZED)
        (asserts! (> (len title) u0) ERR-INVALID-INPUT)
        (asserts! (> (len location) u0) ERR-INVALID-INPUT)
        (asserts! (> date u0) ERR-INVALID-INPUT)
        (map-set meeting-records meeting-id {
            title: title,
            date: date,
            location: location,
            organizer: tx-sender,
            participants: participants,
            agenda: agenda,
            minutes: minutes,
            status: "active",
            block-height: current-height
        })
        (var-set next-meeting-id (+ meeting-id u1))
        (ok meeting-id)
    )
)

(define-public (update-meeting-minutes 
    (meeting-id uint)
    (minutes (string-utf8 2048))
)
    (let (
        (meeting-record (unwrap! (map-get? meeting-records meeting-id) ERR-NOT-FOUND))
    )
        (asserts! (is-authorized-official tx-sender) ERR-UNAUTHORIZED)
        (asserts! (> (len minutes) u0) ERR-INVALID-INPUT)
        (map-set meeting-records meeting-id
            (merge meeting-record {minutes: minutes})
        )
        (ok true)
    )
)

(define-public (close-meeting (meeting-id uint))
    (let (
        (meeting-record (unwrap! (map-get? meeting-records meeting-id) ERR-NOT-FOUND))
    )
        (asserts! (is-authorized-official tx-sender) ERR-UNAUTHORIZED)
        (asserts! (is-eq (get organizer meeting-record) tx-sender) ERR-UNAUTHORIZED)
        (map-set meeting-records meeting-id
            (merge meeting-record {status: "closed"})
        )
        (ok true)
    )
)

(define-public (record-meeting-attendance 
    (meeting-id uint)
    (participant principal)
    (attended bool)
    (role (string-ascii 32))
)
    (begin
        (asserts! (is-authorized-official tx-sender) ERR-UNAUTHORIZED)
        (asserts! (is-some (map-get? meeting-records meeting-id)) ERR-NOT-FOUND)
        (map-set meeting-attendance {meeting-id: meeting-id, participant: participant} {
            attended: attended,
            role: role
        })
        (ok true)
    )
)

(define-public (create-decision-record 
    (meeting-id uint)
    (title (string-utf8 256))
    (description (string-utf8 1024))
    (decision-date uint)
)
    (let (
        (decision-id (var-get next-decision-id))
        (current-height stacks-block-height)
    )
        (asserts! (is-authorized-official tx-sender) ERR-UNAUTHORIZED)
        (asserts! (is-some (map-get? meeting-records meeting-id)) ERR-NOT-FOUND)
        (asserts! (> (len title) u0) ERR-INVALID-INPUT)
        (asserts! (> (len description) u0) ERR-INVALID-INPUT)
        (map-set meeting-decisions decision-id {
            meeting-id: meeting-id,
            title: title,
            description: description,
            proposer: tx-sender,
            votes-for: u0,
            votes-against: u0,
            votes-abstain: u0,
            status: "pending",
            decision-date: decision-date,
            block-height: current-height
        })
        (var-set next-decision-id (+ decision-id u1))
        (ok decision-id)
    )
)

(define-public (cast-vote 
    (decision-id uint)
    (vote (string-ascii 16))
)
    (let (
        (decision-record (unwrap! (map-get? meeting-decisions decision-id) ERR-NOT-FOUND))
        (existing-vote (map-get? decision-votes {decision-id: decision-id, voter: tx-sender}))
        (current-height stacks-block-height)
    )
        (asserts! (is-authorized-official tx-sender) ERR-UNAUTHORIZED)
        (asserts! (is-eq (get status decision-record) "pending") ERR-INVALID-INPUT)
        (asserts! (is-none existing-vote) ERR-ALREADY-EXISTS)
        (asserts! (or (is-eq vote "for") (or (is-eq vote "against") (is-eq vote "abstain"))) ERR-INVALID-INPUT)
        (map-set decision-votes {decision-id: decision-id, voter: tx-sender} {
            vote: vote,
            vote-date: current-height
        })
        (let (
            (updated-record (if (is-eq vote "for")
                (merge decision-record {votes-for: (+ (get votes-for decision-record) u1)})
                (if (is-eq vote "against")
                    (merge decision-record {votes-against: (+ (get votes-against decision-record) u1)})
                    (merge decision-record {votes-abstain: (+ (get votes-abstain decision-record) u1)})
                )
            ))
        )
            (map-set meeting-decisions decision-id updated-record)
            (ok true)
        )
    )
)
 
(define-public (finalize-decision 
    (decision-id uint)
    (final-status (string-ascii 16))
)
    (let (
        (decision-record (unwrap! (map-get? meeting-decisions decision-id) ERR-NOT-FOUND))
    )
        (asserts! (is-authorized-official tx-sender) ERR-UNAUTHORIZED)
        (asserts! (is-eq (get proposer decision-record) tx-sender) ERR-UNAUTHORIZED)
        (asserts! (is-eq (get status decision-record) "pending") ERR-INVALID-INPUT)
        (asserts! (or (is-eq final-status "approved") (is-eq final-status "rejected")) ERR-INVALID-INPUT)
        (map-set meeting-decisions decision-id
            (merge decision-record {status: final-status})
        )
        (ok true)
    )
)

(define-read-only (get-meeting-decisions (target-meeting-id uint))
    (ok (list target-meeting-id))
)

(define-read-only (get-vote-summary (decision-id uint))
    (let (
        (decision-record (map-get? meeting-decisions decision-id))
    )
        (if (is-some decision-record)
            (let (
                (record (unwrap-panic decision-record))
            )
                (some {
                    votes-for: (get votes-for record),
                    votes-against: (get votes-against record),
                    votes-abstain: (get votes-abstain record),
                    total-votes: (+ (+ (get votes-for record) (get votes-against record)) (get votes-abstain record))
                })
            )
            none
        )
    )
)

(map-set authorized-officials CONTRACT-OWNER true)



(define-map citizen-proposals uint {
    title: (string-utf8 256),
    description: (string-utf8 1024),
    proposed-date: uint,
    proposed-location: (string-utf8 128),
    proposer: principal,
    status: (string-ascii 16),
    submission-date: uint,
    block-height: uint,
    supporting-citizens: (list 20 principal)
})

(define-map proposal-supporters {proposal-id: uint, supporter: principal} bool)

(define-read-only (get-citizen-proposal (proposal-id uint))
    (map-get? citizen-proposals proposal-id)
)

(define-read-only (get-next-proposal-id)
    (var-get next-proposal-id)
)

(define-read-only (has-supported-proposal (proposal-id uint) (citizen principal))
    (default-to false (map-get? proposal-supporters {proposal-id: proposal-id, supporter: citizen}))
)

(define-public (submit-meeting-proposal 
    (title (string-utf8 256))
    (description (string-utf8 1024))
    (proposed-date uint)
    (proposed-location (string-utf8 128))
)
    (let (
        (proposal-id (var-get next-proposal-id))
        (current-height stacks-block-height)
    )
        (asserts! (> (len title) u0) ERR-INVALID-INPUT)
        (asserts! (> (len description) u0) ERR-INVALID-INPUT)
        (asserts! (> proposed-date u0) ERR-INVALID-INPUT)
        (asserts! (> (len proposed-location) u0) ERR-INVALID-INPUT)
        (map-set citizen-proposals proposal-id {
            title: title,
            description: description,
            proposed-date: proposed-date,
            proposed-location: proposed-location,
            proposer: tx-sender,
            status: "pending",
            submission-date: current-height,
            block-height: current-height,
            supporting-citizens: (list tx-sender)
        })
        (map-set proposal-supporters {proposal-id: proposal-id, supporter: tx-sender} true)
        (var-set next-proposal-id (+ proposal-id u1))
        (ok proposal-id)
    )
)

(define-public (support-proposal (proposal-id uint))
    (let (
        (proposal (unwrap! (map-get? citizen-proposals proposal-id) ERR-NOT-FOUND))
        (current-supporters (get supporting-citizens proposal))
    )
        (asserts! (is-eq (get status proposal) "pending") ERR-INVALID-INPUT)
        (asserts! (not (has-supported-proposal proposal-id tx-sender)) ERR-ALREADY-EXISTS)
        (asserts! (< (len current-supporters) u20) ERR-INVALID-INPUT)
        (map-set proposal-supporters {proposal-id: proposal-id, supporter: tx-sender} true)
        (map-set citizen-proposals proposal-id
            (merge proposal {supporting-citizens: (unwrap! (as-max-len? (append current-supporters tx-sender) u20) ERR-INVALID-INPUT)})
        )
        (ok true)
    )
)

(define-public (review-proposal (proposal-id uint) (new-status (string-ascii 16)))
    (let (
        (proposal (unwrap! (map-get? citizen-proposals proposal-id) ERR-NOT-FOUND))
    )
        (asserts! (is-authorized-official tx-sender) ERR-UNAUTHORIZED)
        (asserts! (is-eq (get status proposal) "pending") ERR-INVALID-INPUT)
        (asserts! (or (is-eq new-status "approved") (or (is-eq new-status "rejected") (is-eq new-status "under-review"))) ERR-INVALID-INPUT)
        (map-set citizen-proposals proposal-id
            (merge proposal {status: new-status})
        )
        (ok true)
    )
)

(define-map meeting-analytics uint {
    total-invited: uint,
    total-attended: uint,
    decisions-made: uint,
    avg-decision-time: uint,
    participation-score: uint,
    efficiency-rating: uint
})

(define-data-var analytics-enabled bool true)

(define-read-only (get-meeting-analytics (meeting-id uint))
    (map-get? meeting-analytics meeting-id)
)

(define-read-only (calculate-attendance-rate (meeting-id uint))
    (let (
        (analytics (map-get? meeting-analytics meeting-id))
    )
        (if (is-some analytics)
            (let (
                (data (unwrap-panic analytics))
                (invited (get total-invited data))
                (attended (get total-attended data))
            )
                (if (> invited u0)
                    (some (/ (* attended u100) invited))
                    none
                )
            )
            none
        )
    )
)

(define-read-only (get-efficiency-metrics (meeting-id uint))
    (let (
        (analytics (map-get? meeting-analytics meeting-id))
    )
        (if (is-some analytics)
            (let (
                (data (unwrap-panic analytics))
            )
                (some {
                    attendance-rate: (default-to u0 (calculate-attendance-rate meeting-id)),
                    decisions-made: (get decisions-made data),
                    avg-decision-time: (get avg-decision-time data),
                    participation-score: (get participation-score data),
                    efficiency-rating: (get efficiency-rating data)
                })
            )
            none
        )
    )
)

(define-public (generate-meeting-analytics (meeting-id uint))
    (let (
        (meeting (unwrap! (map-get? meeting-records meeting-id) ERR-NOT-FOUND))
        (participants (get participants meeting))
        (total-invited (len participants))
        (decisions-for-meeting (get-decisions-count meeting-id)))
        (asserts! (is-authorized-official tx-sender) ERR-UNAUTHORIZED)
        (asserts! (is-eq (get status meeting) "closed") ERR-INVALID-INPUT)
        (let (
            (attended-count (count-attendees meeting-id))
            (participation (calculate-participation-score meeting-id))
            (efficiency (calculate-efficiency-rating decisions-for-meeting attended-count))
        )
            (map-set meeting-analytics meeting-id {
                total-invited: total-invited,
                total-attended: attended-count,
                decisions-made: decisions-for-meeting,
                avg-decision-time: u24,
                participation-score: participation,
                efficiency-rating: efficiency
            })
            (ok true)
        )
    )
)

(define-private (count-attendees (meeting-id uint))
    u0
)

(define-private (get-decisions-count (meeting-id uint))
    u0
)

(define-private (calculate-participation-score (meeting-id uint))
    u75
)

(define-private (calculate-efficiency-rating (decisions uint) (attendees uint))
    (if (> attendees u0)
        (let ((score (* decisions u20)))
            (if (> score u100) u100 score)
        )
        u0
    )
)