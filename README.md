🎶 MusicWave – Decentralized Music Discovery Platform

MusicWave is a blockchain-based platform for music sharing, playlist curation, and artist discovery, powered by community-driven rewards.
It introduces MusicWave Discovery Token (MWT) as the native reward currency, incentivizing contributions like sharing tracks, creating playlists, listening to songs, and achieving milestones.

📖 Table of Contents

Overview

Token Information

Core Features

Data Structures

Functions

Token Functions

Music Track Functions

Playlist Functions

Listening & Likes

Milestones

User Profile Management

Read-Only Functions

Reward System

Error Codes

Events

Future Extensions

📌 Overview

MusicWave enables users to:

Upload tracks with metadata (artist, title, genre, duration).

Curate public or private playlists.

Listen to and like tracks.

Earn MWT rewards for engagement.

Progress through user levels and claim milestones.

The platform runs entirely on-chain, ensuring transparency, immutability, and community-driven music discovery.

💰 Token Information

Name: MusicWave Discovery Token

Symbol: MWT

Decimals: 6

Max Supply: 75,000 MWT (75,000,000,000 micro-tokens)

✨ Core Features

Track Sharing: Artists and users upload music tracks with on-chain metadata.

Playlists: Users create, curate, and share playlists.

Engagement: Listening, liking, and following playlists.

Gamified Rewards: Earn tokens for actions like uploading, listening, and curating.

Milestones: Claim achievements (e.g., “Sharer 5”, “Listener 50”, “Curator 3”).

On-chain Identity: Profiles include username, genre preference, activity stats, and level.

📂 Data Structures
1. User Profiles (user-profiles)

Stores information about each user:

username

music-genre (preferred genre)

tracks-shared, playlists-created, total-listens

user-level

join-date

2. Music Tracks (music-tracks)

artist, title, genre

duration-seconds

uploader

play-count

upload-date

3. Listening History (listen-history)

Tracks user interaction with songs:

listen-date

listen-count

liked (bool)

4. Playlists (music-playlists)

creator

playlist-name, description

track-count, followers

creation-date

public

5. Playlist Tracks (playlist-tracks)

Links tracks to playlists:

added-date

position

6. User Milestones (user-milestones)

Tracks achievements:

achievement-date

milestone-count

⚙️ Functions
🔹 Token Functions

get-name → Returns token name.

get-symbol → Returns token symbol.

get-decimals → Returns decimals.

get-balance (user) → Returns user’s balance.

mint-tokens (recipient, amount) (private) → Mints new tokens.

🔹 Music Track Functions

upload-track (artist, title, genre, duration)

Uploads a new track.

Updates user profile.

Rewards uploader with 2 MWT.

Increments next-track-id.

get-track (track-id) → Returns track metadata.

🔹 Playlist Functions

create-playlist (name, description, public)

Creates new playlist.

Updates profile.

Rewards creator with 4 MWT.

Increments next-playlist-id.

add-to-playlist (playlist-id, track-id)

Adds track to a playlist.

Only playlist creator can add.

Updates track-count.

get-playlist (playlist-id) → Returns playlist info.

get-playlist-track (playlist-id, track-id) → Returns track’s position and details in a playlist.

🔹 Listening & Likes

listen-to-track (track-id)

Updates listening history.

Updates track play count.

Rewards listener with 1 MWT (only on first listen).

like-track (track-id)

Marks a track as liked in listening history.

get-listen-history (track-id, listener) → Returns listen details.

🔹 Milestones

claim-milestone (milestone)
Available milestones:

"sharer-5" → Shared ≥ 5 tracks.

"listener-50" → Listened to ≥ 50 tracks.

"curator-3" → Created ≥ 3 playlists.

Rewards: 10 MWT each.

get-milestone (user, milestone) → Returns milestone details.

🔹 User Profile Management

update-username (new-username) → Updates profile username.

get-user-profile (user) → Returns full profile.

🎁 Reward System
Action	Reward (MWT)
Upload Track	2 MWT
Create Playlist	4 MWT
First Listen	1 MWT
Claim Milestone	10 MWT
❗ Error Codes
Code	Meaning
u100	Owner-only action
u101	Not found
u102	Already exists
u103	Unauthorized
u104	Invalid input
📢 Events

The contract emits structured print events:

track-uploaded

track-listened

playlist-created

track-added-to-playlist

track-liked

milestone-claimed

username-updated

These can be indexed off-chain for analytics and UI updates.

🚀 Future Extensions

NFT-based ownership of tracks/playlists.

Marketplace for track monetization.

DAO governance for community-driven curation.

Cross-platform music discovery integrations.

✅ With MusicWave, the community rewards itself by making music discovery fair, transparent, and decentralized.
