<div align="center">
  <img width="100" alt="dark_mode" src="https://github.com/user-attachments/assets/c77e78a3-903c-47b9-8d98-80eb69445277" />
  <h1>Community Map</h1>
  <h1>Community Map</h1>

<p>
  A platform for connecting local communities and sharing important information, created by our goat, our very own Bitto Saha. I am thankful that he is allowing me to do something.
    
</p>

  <p>
    <a href="#features"><b>Features</b></a> • 
    <a href="#use-cases"><b>Use Cases</b></a> •
    <a href="#architecture"><b>Architecture</b></a>
  </p>

  
## Features
</div>




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

<div align="center">
  
## Use Cases
</div>

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


<div align="center">
  
## Architecture

</div>

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

### 2. Auth & Security

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
