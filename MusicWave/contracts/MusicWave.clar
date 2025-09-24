;; MusicWave - Decentralized Music Discovery Platform
;; A blockchain-based platform for music sharing, playlists,
;; and artist discovery with community rewards

;; Contract constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-input (err u104))

;; Token constants
(define-constant token-name "MusicWave Discovery Token")
(define-constant token-symbol "MWT")
(define-constant token-decimals u6)
(define-constant token-max-supply u75000000000) ;; 75k tokens with 6 decimals

;; Reward amounts (in micro-tokens)
(define-constant reward-track u2000000) ;; 2 MWT
(define-constant reward-playlist u4000000) ;; 4 MWT
(define-constant reward-listen u1000000) ;; 1 MWT
(define-constant reward-milestone u10000000) ;; 10 MWT

;; Data variables
(define-data-var total-supply uint u0)
(define-data-var next-track-id uint u1)
(define-data-var next-playlist-id uint u1)

;; Token balances
(define-map token-balances principal uint)

;; User profiles
(define-map user-profiles
  principal
  {
    username: (string-ascii 32),
    music-genre: (string-ascii 16), ;; "rock", "pop", "jazz", "electronic", "classical"
    tracks-shared: uint,
    playlists-created: uint,
    total-listens: uint,
    user-level: uint, ;; 1-8
    join-date: uint
  }
)

;; Music tracks
(define-map music-tracks
  uint
  {
    artist: (string-ascii 32),
    title: (string-ascii 64),
    genre: (string-ascii 16),
    duration-seconds: uint,
    uploader: principal,
    play-count: uint,
    upload-date: uint
  }
)

;; User listening history
(define-map listen-history
  { track-id: uint, listener: principal }
  {
    listen-date: uint,
    listen-count: uint,
    liked: bool
  }
)

;; Music playlists
(define-map music-playlists
  uint
  {
    creator: principal,
    playlist-name: (string-ascii 48),
    description: (string-ascii 128),
    track-count: uint,
    followers: uint,
    creation-date: uint,
    public: bool
  }
)

;; Playlist tracks
(define-map playlist-tracks
  { playlist-id: uint, track-id: uint }
  {
    added-date: uint,
    position: uint
  }
)

;; User milestones
(define-map user-milestones
  { user: principal, milestone: (string-ascii 16) }
  {
    achievement-date: uint,
    milestone-count: uint
  }
)

;; Helper function to get or create profile
(define-private (get-or-create-profile (user principal))
  (match (map-get? user-profiles user)
    profile profile
    {
      username: "",
      music-genre: "pop",
      tracks-shared: u0,
      playlists-created: u0,
      total-listens: u0,
      user-level: u1,
      join-date: stacks-block-height
    }
  )
)

;; Token functions
(define-read-only (get-name)
  (ok token-name)
)

(define-read-only (get-symbol)
  (ok token-symbol)
)

(define-read-only (get-decimals)
  (ok token-decimals)
)

(define-read-only (get-balance (user principal))
  (ok (default-to u0 (map-get? token-balances user)))
)

(define-private (mint-tokens (recipient principal) (amount uint))
  (let (
    (current-balance (default-to u0 (map-get? token-balances recipient)))
    (new-balance (+ current-balance amount))
    (new-total-supply (+ (var-get total-supply) amount))
  )
    (asserts! (<= new-total-supply token-max-supply) err-invalid-input)
    (map-set token-balances recipient new-balance)
    (var-set total-supply new-total-supply)
    (ok amount)
  )
)

;; Upload music track
(define-public (upload-track (artist (string-ascii 32)) (title (string-ascii 64)) (genre (string-ascii 16)) (duration-seconds uint))
  (let (
    (track-id (var-get next-track-id))
    (profile (get-or-create-profile tx-sender))
  )
    (asserts! (> (len artist) u0) err-invalid-input)
    (asserts! (> (len title) u0) err-invalid-input)
    (asserts! (> duration-seconds u0) err-invalid-input)
    
    (map-set music-tracks track-id {
      artist: artist,
      title: title,
      genre: genre,
      duration-seconds: duration-seconds,
      uploader: tx-sender,
      play-count: u0,
      upload-date: stacks-block-height
    })
    
    ;; Update profile
    (map-set user-profiles tx-sender
      (merge profile {
        tracks-shared: (+ (get tracks-shared profile) u1),
        user-level: (+ (get user-level profile) u1)
      })
    )
    
    ;; Award track upload tokens
    (try! (mint-tokens tx-sender reward-track))
    
    (var-set next-track-id (+ track-id u1))
    (print {action: "track-uploaded", track-id: track-id, uploader: tx-sender})
    (ok track-id)
  )
)

;; Listen to track
(define-public (listen-to-track (track-id uint))
  (let (
    (track (unwrap! (map-get? music-tracks track-id) err-not-found))
    (profile (get-or-create-profile tx-sender))
    (existing-listen (map-get? listen-history {track-id: track-id, listener: tx-sender}))
  )
    ;; Update or create listen record
    (map-set listen-history {track-id: track-id, listener: tx-sender}
      (match existing-listen
        listen-record {
          listen-date: stacks-block-height,
          listen-count: (+ (get listen-count listen-record) u1),
          liked: (get liked listen-record)
        }
        {
          listen-date: stacks-block-height,
          listen-count: u1,
          liked: false
        }
      )
    )
    
    ;; Update track play count
    (map-set music-tracks track-id
      (merge track {play-count: (+ (get play-count track) u1)})
    )
    
    ;; Update user profile if first listen
    (if (is-none existing-listen)
      (begin
        (map-set user-profiles tx-sender
          (merge profile {total-listens: (+ (get total-listens profile) u1)})
        )
        (try! (mint-tokens tx-sender reward-listen))
        true
      )
      true
    )
    
    (print {action: "track-listened", track-id: track-id, listener: tx-sender})
    (ok true)
  )
)

;; Create playlist
(define-public (create-playlist (playlist-name (string-ascii 48)) (description (string-ascii 128)) (public bool))
  (let (
    (playlist-id (var-get next-playlist-id))
    (profile (get-or-create-profile tx-sender))
  )
    (asserts! (> (len playlist-name) u0) err-invalid-input)
    
    (map-set music-playlists playlist-id {
      creator: tx-sender,
      playlist-name: playlist-name,
      description: description,
      track-count: u0,
      followers: u0,
      creation-date: stacks-block-height,
      public: public
    })
    
    ;; Update profile
    (map-set user-profiles tx-sender
      (merge profile {playlists-created: (+ (get playlists-created profile) u1)})
    )
    
    ;; Award playlist creation tokens
    (try! (mint-tokens tx-sender reward-playlist))
    
    (var-set next-playlist-id (+ playlist-id u1))
    (print {action: "playlist-created", playlist-id: playlist-id, creator: tx-sender})
    (ok playlist-id)
  )
)

;; Add track to playlist
(define-public (add-to-playlist (playlist-id uint) (track-id uint))
  (let (
    (playlist (unwrap! (map-get? music-playlists playlist-id) err-not-found))
    (track (unwrap! (map-get? music-tracks track-id) err-not-found))
  )
    (asserts! (is-eq tx-sender (get creator playlist)) err-unauthorized)
    (asserts! (is-none (map-get? playlist-tracks {playlist-id: playlist-id, track-id: track-id})) err-already-exists)
    
    (map-set playlist-tracks {playlist-id: playlist-id, track-id: track-id} {
      added-date: stacks-block-height,
      position: (get track-count playlist)
    })
    
    ;; Update playlist track count
    (map-set music-playlists playlist-id
      (merge playlist {track-count: (+ (get track-count playlist) u1)})
    )
    
    (print {action: "track-added-to-playlist", playlist-id: playlist-id, track-id: track-id})
    (ok true)
  )
)

;; Like track
(define-public (like-track (track-id uint))
  (let (
    (track (unwrap! (map-get? music-tracks track-id) err-not-found))
    (listen-record (unwrap! (map-get? listen-history {track-id: track-id, listener: tx-sender}) err-not-found))
  )
    (asserts! (not (get liked listen-record)) err-already-exists)
    
    (map-set listen-history {track-id: track-id, listener: tx-sender}
      (merge listen-record {liked: true})
    )
    
    (print {action: "track-liked", track-id: track-id, listener: tx-sender})
    (ok true)
  )
)

;; Claim milestone
(define-public (claim-milestone (milestone (string-ascii 16)))
  (let (
    (profile (get-or-create-profile tx-sender))
  )
    (asserts! (is-none (map-get? user-milestones {user: tx-sender, milestone: milestone})) err-already-exists)
    
    ;; Check milestone requirements
    (let (
      (milestone-met
        (if (is-eq milestone "sharer-5") (>= (get tracks-shared profile) u5)
        (if (is-eq milestone "listener-50") (>= (get total-listens profile) u50)
        (if (is-eq milestone "curator-3") (>= (get playlists-created profile) u3)
        false))))
    )
      (asserts! milestone-met err-unauthorized)
      
      ;; Record milestone
      (map-set user-milestones {user: tx-sender, milestone: milestone} {
        achievement-date: stacks-block-height,
        milestone-count: (get total-listens profile)
      })
      
      ;; Award milestone tokens
      (try! (mint-tokens tx-sender reward-milestone))
      
      (print {action: "milestone-claimed", user: tx-sender, milestone: milestone})
      (ok true)
    )
  )
)

;; Update username
(define-public (update-username (new-username (string-ascii 32)))
  (let (
    (profile (get-or-create-profile tx-sender))
  )
    (asserts! (> (len new-username) u0) err-invalid-input)
    (map-set user-profiles tx-sender (merge profile {username: new-username}))
    (print {action: "username-updated", user: tx-sender})
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-user-profile (user principal))
  (map-get? user-profiles user)
)

(define-read-only (get-track (track-id uint))
  (map-get? music-tracks track-id)
)

(define-read-only (get-listen-history (track-id uint) (listener principal))
  (map-get? listen-history {track-id: track-id, listener: listener})
)

(define-read-only (get-playlist (playlist-id uint))
  (map-get? music-playlists playlist-id)
)

(define-read-only (get-playlist-track (playlist-id uint) (track-id uint))
  (map-get? playlist-tracks {playlist-id: playlist-id, track-id: track-id})
)

(define-read-only (get-milestone (user principal) (milestone (string-ascii 16)))
  (map-get? user-milestones {user: user, milestone: milestone})
)