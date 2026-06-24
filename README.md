# Ezeal MVP Flutter Foundation (Phase 0)

Ezeal is a professional responsive platform built using Flutter Web, responsive for Android/iOS, integrating Riverpod for state management, GoRouter for navigation routing, and Supabase backend.

## Tech Stack

- **Framework:** Flutter (Web-first, responsive)
- **State Management:** Riverpod (via `flutter_riverpod`)
- **Routing:** GoRouter (via `go_router`)
- **Backend Service:** Supabase (via `supabase_flutter`)
- **Typography:** Poppins (via `google_fonts`)
- **UI Design System:** Material 3 with Ezeal Brand colors (#0202B0 Primary, #FFC91A Accent)

---

## Directory Structure

This project follows **Clean Architecture** patterns:
```
lib/
├── core/
│   ├── config/          # Configurations and environment properties
│   ├── constants/       # App-wide constants (strings, icons, etc.)
│   ├── theme/           # App colors, spacing, typography, and light/dark theme definitions
│   ├── router/          # GoRouter routes registration and provider
│   ├── errors/          # Custom exceptions and failures definitions
│   ├── utils/           # Helper utilities
│   ├── validators/      # Form input validator functions
│   ├── widgets/         # Shared responsive widgets (scaffolds, buttons, cards, textfields, etc.)
│   ├── services/        # Platform services (Supabase initialization, local storage, etc.)
│   ├── enums/           # Standard enums
│   └── extensions/      # Useful extension helpers
│
└── features/            # Feature modules (each containing Clean Architecture subdirectories)
    ├── auth/            # Authentication feature (login, signup, reset password)
    ├── dashboard/       # General routing dashboard and landing page
    ├── student/         # Student portal and workspace
    ├── assessments/     # Exam schedules and basic score cards
    ├── cart/            # Subscription cart and billing logs
    ├── verification/    # KYC and Aadhaar placeholder logic
    ├── payments/        # Fee payment logs and checkout screens
    ├── reports/         # Academic performance dashboards
    ├── admin/           # General administrator control panel
    ├── institution/     # School/college/university manager portals
    ├── counsellor/      # Student-counsellor consulting session manager
    ├── shared/          # Shared features widgets/models
    ├── assessment_engine/ # Dynamic test runners
    └── ezeal_identity/  # Verification pipelines
        ├── data/        # Data layer (repositories, data sources, DTOs)
        ├── domain/      # Domain layer (entities, usecases, repository interfaces)
        └── presentation/# Presentation layer (pages, widgets, providers)
```

---

## Environment Setup & Running

This project uses Dart compiler definitions to configure Supabase credentials securely. Do not hardcode secrets into any repository files.

Run the project locally using:

```bash
flutter run -d chrome --dart-define=SUPABASE_URL=https://otxnfklrtuiyukvfhlmt.supabase.co --dart-define=SUPABASE_ANON_KEY=your_supabase_anon_key --dart-define=AUTH_EMAIL_CONFIRMATION_ENABLED=false
```

### Build for Production
To compile the web release with the environment configurations embedded:

```bash
flutter build web --dart-define=SUPABASE_URL=https://otxnfklrtuiyukvfhlmt.supabase.co --dart-define=SUPABASE_ANON_KEY=your_supabase_anon_key
```

---

## Foundation Features (Phase 0)

1. **Responsive AppScaffold:** Detects layout size dynamically. Renders a persistent sidebar for **Desktop/Tablet** layouts and a hamburger **Drawer** for **Mobile** screens.
2. **Ezeal Design System:** Uses custom primary color (`#0202B0`), accent color (`#FFC91A`), and professional font `Poppins` with standard Material 3 layouts.
3. **Robust Routing:** Employs GoRouter. Navigates smoothly between `/`, `/auth`, `/dashboard`, and role dashboards (`/student/dashboard`, `/admin/dashboard`, `/institution/dashboard`, `/counsellor/dashboard`).
4. **Supabase Bootstrap:** Service init parses `--dart-define` parameters cleanly with warning prompts if credentials are not passed.

---

## Development Notes & Local Supabase Testing

### Email Rate Limits (429) & Signup Verification
If you encounter email rate limit errors (`over_email_send_rate_limit`) during development:
1. **Disable email confirmation** for your local Supabase instance:
   - Go to your **Supabase Dashboard** -> **Authentication** -> **Providers** -> **Email**.
   - Turn off **Confirm email** (Confirm email OFF) and click **Save**.
   - This bypasses verification requirements and activates signed-up profiles immediately, which is ideal for local development and QA testing.
2. **Run your project with the confirmation disabled flag** to hide confirmation resend buttons in the UI:
   - Add `--dart-define=AUTH_EMAIL_CONFIRMATION_ENABLED=false` to your run command.
#   e z e a l _ a p p  