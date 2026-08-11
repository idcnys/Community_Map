<div align="center">
  <img width="100" alt="dark_mode" src="https://github.com/user-attachments/assets/c77e78a3-903c-47b9-8d98-80eb69445277" />
  <h1>Community Map</h1>

  <p>
    <a href="#features"><b>Features</b></a> • 
    <a href="#use-cases"><b>Use Cases</b></a> • 
    <a href="#ui"><b>UI</b></a> •
    <a href="#legal"><b>Legal</b></a>
  </p>
</div>

## Features

### Authentication & Access
- Email/password sign up and sign in
- Google sign-in support
- Guest access mode for read-focused exploration
- Email verification gate before full account access
- Password reset flow

### Feed & Community Content
- Infinite-scrolling community feed
- Post creation with title, description, and optional image
- Public posts and group-only posts
- Poll creation (single-choice and multiple-choice)
- Poll voting with live vote counts and progress indicators
- Reposts, likes, comments, and live view counts
- Per-user post management
- Feed filtering by public scope or joined groups

### Notifications
- Feed notification panel with unread count badge
- In-app foreground push banners
- Notification tap routing into relevant content

### Map & Reporting
- Interactive map with constrained service area and custom markers
- Report markers with urgency/age visual states
- One-tap urgent report submission
- Full report submission form with:
  - report type
  - contact number
  - description
  - optional photo attachment
  - optional voice recording
  - auto-detected location
- Nearby essential services discovery with category filters
- Report preview/detail sheets and archive access
- Personal report history with edit/delete/mark-solved actions

### Groups, Collaboration & Safety Network
- Group discovery with search
- Join request and cancel request flows
- Group creation and editing
- Group-level admin moderation:
  - approve/reject member requests
  - remove members
- Group member directory with activity visibility
- Group chat with unread counters
- Group location sharing for live member map presence
- Profile editing for personal identity and contact context

### Guest Experience Controls
- Guest-aware restricted access for management features
- Dedicated locked-state UI for unavailable actions
- Seamless guest sign-out path back to authentication

---

## Use Cases

### 1) Local Community Updates
A resident shares a neighborhood update as a public post, other members react/comment, and the discussion remains discoverable in the main feed.

### 2) Group-Scoped Coordination
A user posts updates only to a specific group (e.g., apartment block, volunteer team), keeping communication private to members.

### 3) Community Polling
A group admin or member creates a poll to make local decisions (event timing, priorities, actions), and members vote with transparent results.

### 4) Emergency Signaling
A user submits an urgent location-based report immediately from the map, enabling fast visibility for nearby community members.

### 5) Structured Incident Reporting
A user submits a detailed report with context, media, and location, then tracks progress and marks resolution when solved.

### 6) Nearby Assistance Discovery
During an incident, a user opens nearby service categories (hospital, police, fire, pharmacy) to quickly identify relevant help points.

### 7) Group Safety Coordination
Group members share their live location in group context, helping teams coordinate meetups, check-ins, or support response.

### 8) Member Onboarding & Trust
New users onboard with guided screens, verify email identity, and then join groups through moderated request workflows.

### 9) Lightweight Read-Only Exploration
A first-time visitor enters as a guest to explore feed/map content before creating an account.

### 10) Ongoing Group Administration
Group owners manage membership requests, monitor participation, and keep group communication organized through chat and moderation tools.

---

## UI

### Navigation Structure
- **Pre-auth flow:** Splash → Onboarding → Login/Signup → Verify Email
- **Post-auth root:** Dashboard with bottom navigation
  - **Feed**
  - **Map**
  - **Manage**

### Feed UI
- App bar with post management and notification access
- Horizontal filter chips (All/Public/Group scopes)
- Floating “Post” action with modal options (normal post or poll)
- Card-based post presentation with:
  - author identity
  - scope badge (public/group)
  - text/media content
  - interaction row (like/comment/repost/views)
- Comment route per post

### Post & Poll Creation UI
- Form-driven screens with validation
- Public vs group origin selectors
- Group picker when group origin is selected
- Image capture/gallery chooser for post media
- Poll builder with dynamic option list and vote type selector

### Map UI
- Full-screen interactive map canvas
- Top control bar:
  - global/group context dropdown
  - archive access
  - latest report notifications
- Nearby service filter chips under top bar
- Marker layers:
  - self-location
  - reports
  - group members
  - nearby services
- Bottom-left controls: reset view, jump to current location
- Bottom-right actions: my reports, urgent report, new report
- Bottom sheets for report preview/detail, member details, and nearby service details

### Report Submission UI
- Multi-section form with strong input affordances
- Media capture controls (photo + voice recording)
- Live location state card with refresh action
- Group visibility context chips for contact sharing

### Manage UI
- Tabbed interface:
  - **My Groups**
  - **Discover**
  - **Requests**
- Group list cards with unread/pending badges
- Group creation dialog
- Discover search bar with join/request state actions
- Pending requests list with cancel action

### Group Detail & Chat UI
- Group summary card with admin edit action
- Group chat entry point
- Admin review cards for pending join approvals/rejections
- Member list with role and activity cues
- Moderation menu for member removal
- Chat screen with message stream, timestamps, and send composer
- Quick action to share current location to group

### Profile & Identity UI
- Profile editor access from Manage
- Avatar/image pick actions
- Structured personal fields (name, contact, bio, etc.)

### Notification UI
- Feed notification panel and map notification panel as modal bottom sheets
- Badge counters in top app actions
- Snackbar-based in-app push feedback

---

## Legal

- [Terms and Conditions](/TERMS_AND_CONDITIONS.md)
- [Privacy Policy](/PRIVACY_POLICY.md)
- [License](/LICENSE)


---

## Architecture Flowcharts

### 1. App Lifecycle & Navigation

```mermaid
flowchart TD
    A["main()"] --> B["FlutterNativeSplash.preserve"]
    B --> C["initializeFirebaseServices"]
    C --> C1["Firebase.initializeApp"]
    C1 --> C2["Firestore persistence (100MB cache)"]
    C1 --> C3["FCM background handler"]
    C --> D["AppConfig.load (.env)"]
    D --> E["Supabase.initialize"]
    E --> F["FlutterNativeSplash.remove"]
    F --> G["ProviderScope → MyApp"]
    G --> H["GoRouter /splash"]

    H --> I{Auth State?}
    I -- "Not logged in" --> J["OnboardingPage (first launch only)"]
    J --> K["LoginPage"]
    I -- "Logged in, unverified" --> L["VerifyEmailPage"]
    I -- "Logged in, verified" --> M["DashboardPage"]
    I -- "Guest session active" --> M

    K --> N{Auth Method}
    N -- "Email/Password" --> O["SignUpPage"]
    N -- "Google Sign-In" --> M
    N -- "Guest Mode" --> M
    O --> L
    L -- "Verified" --> M

    M --> P["Tab: Feed"]
    M --> Q["Tab: Map"]
    M --> R["Tab: Manage"]
```

### 2. Feed Tab

```mermaid
flowchart TD
    F["FeedPage"] --> F1["Filter Chips: All / Public / Group"]
    F --> F2["Infinite Scroll (20/page, 2-day cutoff)"]
    F --> F3["Notification Bell + Unread Badge"]
    F --> F4["Manage My Posts"]
    F --> F5["Create Post FAB"]

    F5 --> F5a["CommunityPostForm"]
    F5 --> F5b["PollForm (single/multi vote)"]
    F5a --> RL{"Rate Limit: max 2 posts/hr"}
    F5b --> RL
    RL -- "Under limit" --> FS["PostService / PollService"]
    RL -- "Over limit" --> ERR["Snackbar error"]
    FS --> FIRE["Firestore: community_posts"]
    FS --> NOTIF["Notify group members (if group post)"]

    F2 --> CARD["CommunityPostCard"]
    CARD --> C1["Like / Unlike + notification"]
    CARD --> C2["Comments → CommentsPage"]
    CARD --> C3["Repost (rate limited)"]
    CARD --> C4["Poll Vote (live progress bars)"]
    CARD --> C5["View Count Batcher (10s flush)"]
    CARD --> C6["CachedNetworkImage media"]

    F2 --> RT["Real-time: new posts prepend instantly"]
    F3 --> NP["NotificationPanel (bottom sheet)"]
    NP --> NR["Mark read / Navigate to post"]
```

### 3. Map Tab

```mermaid
flowchart TD
    MAP["MapPage (flutter_map, constrained area)"] --> M1["Report Markers (urgency/age color)"]
    MAP --> M2["Group Member Location Markers"]
    MAP --> M3["Nearby Service Markers"]
    MAP --> M4["Self Location Marker"]

    MAP --> M5["Top Bar: Global / Group Context"]
    MAP --> M6["Nearby Filter Chips"]
    M6 --> M6a["Hospital / Police / Fire / Pharmacy"]
    M6a --> NS["NearbyService → Enrichment Server (15s timeout)"]

    MAP --> M7["Actions"]
    M7 --> M7a["Urgent Report (one-tap GPS)"]
    M7 --> M7b["Full Report Form"]
    M7 --> M7c["My Reports (edit/delete/solve)"]
    M7 --> M7d["Map Notification Panel"]
    M7 --> M7e["Archived Reports"]

    M7b --> RF["ReportPostForm"]
    RF --> RF1["15 Bengali Report Types"]
    RF --> RF2["Contact Number (auto-fill from profile)"]
    RF --> RF3["Photo → Cloudinary (cmap/reports)"]
    RF --> RF4["Voice Recording → Supabase (voice-notes bucket)"]
    RF --> RF5["Auto GPS + Group Visibility Chips"]
    RF --> FIRE2["Firestore: report_posts"]
    FIRE2 --> NOTIF2["notifyAllUsers (new_report)"]

    M7a --> URG["createUrgentReport (no form)"]
    URG --> FIRE2
```

### 4. Manage Tab

```mermaid
flowchart TD
    MG["ManagePage"] --> T1["MyGroupsTab"]
    MG --> T2["DiscoverGroupsTab (search + join)"]

    T1 --> G1["Group List (unread chat badges)"]
    T2 --> G2["Prefix Search + Join/Cancel Request"]

    G1 --> GD["GroupDetailPage"]
    GD --> GD1["Group Chat"]
    GD --> GD2["Member List (role + activity)"]
    GD --> GD3["Admin: Approve / Reject / Remove"]
    GD --> GD4["Edit Group (owner only)"]

    GD1 --> CHAT["GroupChatPage"]
    CHAT --> CH1["Message Stream (limit 30)"]
    CHAT --> CH2["Send Text"]
    CHAT --> CH3["Share Live Location"]
    CHAT --> CH4["Reply / Edit (2min) / Delete"]
    CHAT --> CH5["Seen ✓✓ (batch arrayUnion)"]

    MG --> PE["ProfileEditorPage"]
    PE --> PE1["Name / Phone / Bio / Avatar (Cloudinary)"]

    T2 --> GL["GroupLimits: max 3 created, 5 joined, 8 total"]
```

### 5. Notification System

```mermaid
flowchart TD
    TRIG["Trigger Events"] --> T1["Like / Comment / New Post"]
    TRIG --> T2["New Report / Join Request"]
    TRIG --> T3["Member Approved"]

    T1 --> NS["NotificationService"]
    T2 --> NS
    T3 --> NS

    NS --> FW["Firestore: notifications (targetUserId)"]
    NS --> PUSH["PushNotificationService"]
    PUSH --> EDGE["Supabase Edge Function: send-push"]
    EDGE --> FCM["FCM HTTP v1 API"]
    FCM --> DEV["Device Push"]

    FW --> INAPP["In-App: Stream + Unread Badge"]
    DEV --> TAP["Notification Tap → Deep Link"]
    TAP --> ROUTE["GoRouter: /dashboard/comments/:postId"]

    INAPP --> FG["Foreground: Snackbar Banner"]
```

### 6. Service & Data Layer

```mermaid
flowchart TD
    UI["67 Dart Files / Pages / Widgets"] --> PROV["Riverpod Providers"]
    PROV --> SVC["Service Layer (12 services)"]

    SVC --> S1["PostService (CRUD, feed, likes, comments, reposts)"]
    SVC --> S2["PollService (create, vote, getMyVotes)"]
    SVC --> S3["GroupService (search, CRUD, limits, moderation)"]
    SVC --> S4["GroupChatService (messages, location sharing)"]
    SVC --> S5["ReportPostService (create, urgent, solve, archive)"]
    SVC --> S6["NotificationService (send, broadcast, markRead)"]
    SVC --> S7["ProfileService (CRUD user profile)"]
    SVC --> S8["NearbyService (enrichment server, categories)"]
    SVC --> S9["CloudinaryService (unsigned image upload)"]
    SVC --> S10["SupabaseStorageService (voice-notes bucket)"]
    SVC --> S11["PushNotificationService (FCM token + push)"]
    SVC --> S12["ViewCountBatcher (10s batch flush)"]
    SVC --> S13["UserGroupService (30s cached group IDs)"]

    S1 --> FB["Firebase Firestore (6 composite indexes)"]
    S2 --> FB
    S3 --> FB
    S4 --> FB
    S5 --> FB
    S6 --> FB
    S7 --> FB
    S8 --> EXT["Enrichment Server (HTTP, 15s timeout)"]
    S9 --> CLD["Cloudinary API (unsigned preset)"]
    S10 --> SUP["Supabase Storage (voice-notes)"]
    S11 --> EDGE2["Supabase Edge Function → FCM"]
```

### 7. Auth & Security

```mermaid
flowchart TD
    AUTH["Firebase Auth"] --> A1["Email/Password + Verify"]
    AUTH --> A2["Google Sign-In v7"]
    AUTH --> A3["Guest (Anonymous)"]

    AUTH --> GUARD["GoRouter Redirect Guard"]
    GUARD --> G1{isAnonymous?}
    G1 -- "Yes + inactive session" --> LOGIN["Force Login"]
    G1 -- "Yes + active session" --> DASH["Dashboard (restricted)"]
    G1 -- "No" --> G2{emailVerified?}
    G2 -- "No" --> VERIFY["VerifyEmailPage"]
    G2 -- "Yes" --> DASH

    AUTH --> APPCHK["Firebase App Check (Play Integrity)"]
    APPCHK --> FB["Firestore (protected)"]

    DASH --> GUEST["Guest Restrictions"]
    GUEST --> GR1["No post/poll creation"]
    GUEST --> GR2["No group join/request"]
    GUEST --> GR3["Read-only feed + map"]
    GUEST --> GR4["Sign-out path to Login"]

    AUTH --> TOKEN["FCM Token Registration (on login)"]
    TOKEN --> UDOC["users/{uid}.fcmToken"]
```
