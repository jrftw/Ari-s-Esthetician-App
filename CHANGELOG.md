# Changelog

All notable changes to Ari's Esthetician App will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-22

### Build 3 - 2026-01-30

#### Added
- Version display now shows commit hash when deployed (next to version, e.g. `1.0.0 (Build 3) abc1234`).
- Commit hash is injected at build time via `--dart-define=COMMIT_HASH=<short-hash>` (e.g. from `git rev-parse --short HEAD`).
- Settings screen shows "Commit" line in version info when hash is present.

#### Changed
- Build number updated from 2 to 3 everywhere (pubspec, app_version, fallbacks).
- Changelog and in-app changelog updated to reflect Build 1, Build 2, and Build 3.
- Deploy script (`deploy_hosting.ps1`) now passes current git short commit hash into the Flutter build so deployed versions display it.

#### Technical Details
- **Version**: 1.0.0
- **Build Number**: 3
- **Environment**: Development

---

### Build 2 - 2026-01-22

#### Changed
- Updated build number to 2.
- Version management system updated.

#### Technical Details
- **Version**: 1.0.0
- **Build Number**: 2
- **Environment**: Development

---

### Build 1 - 2026-01-22

#### Added
- Initial release of Ari's Esthetician App.
- Core Flutter project structure with sunflower-themed design system.
- Firebase integration (Authentication, Firestore, Functions, Storage, Messaging).
- Data models for Services, Appointments, Clients, and Business Settings.
- Authentication service with role-based access control (admin/client).
- Firestore service with complete CRUD operations.
- Role-based routing with Go Router.
- Admin dashboard screens (structure):
  - Admin Dashboard
  - Services Management
  - Appointments Calendar
  - Clients Directory
  - Business Settings
- Client booking screens (structure):
  - Booking Screen
  - Confirmation Screen
- Centralized logging system (AppLogger).
- Firestore security rules with helper functions.
- Stripe payment integration setup.
- Google Calendar API integration setup.
- Global version and build number management system.
- Environment-based version display (dev/beta/production).
- Comprehensive README documentation.
- Project documentation files (SETUP.md, QUICK_START.md, PROJECT_STATUS.md).

#### Technical Details
- **Version**: 1.0.0
- **Build Number**: 1
- **Environment**: Development
- **Flutter SDK**: 3.2.0+
- **Dart SDK**: 3.2.0+

#### Known Issues
- Client booking flow UI needs completion.
- Admin dashboard UI needs completion.
- Cloud Functions for booking validation not yet implemented.
- Email notification service not yet set up.
- Calendar synchronization not yet implemented.
- Stripe webhook handlers not yet implemented.

#### Next Steps
- Complete client booking flow UI.
- Complete admin dashboard UI.
- Implement Cloud Functions for booking validation.
- Set up email notification service.
- Add calendar synchronization.
- Implement Stripe webhook handlers.
- Add unit and integration tests.
- Performance optimization.
- Security audit.

---

## Version History (Summary)

| Build | Date       | Notes |
|-------|------------|--------|
| **3** | 2026-01-30 | Commit hash shown next to version when deployed; Build 3 everywhere. |
| **2** | 2026-01-22 | Build number 2; version management updates. |
| **1** | 2026-01-22 | Initial release; core infrastructure and foundation. |

---

## Release Notes

### How to Read This Changelog

- **Added**: New features
- **Changed**: Changes in existing functionality
- **Deprecated**: Soon-to-be removed features
- **Removed**: Removed features
- **Fixed**: Bug fixes
- **Security**: Security improvements

### Version Format

Versions follow Semantic Versioning (SemVer):
- **MAJOR**: Incompatible API changes
- **MINOR**: New functionality in a backwards-compatible manner
- **PATCH**: Backwards-compatible bug fixes

### Build Numbers

Build numbers increment with each build/release, independent of version numbers.

### Commit Hash (Build 3+)

When the app is built for deployment with a commit hash (e.g. `flutter build web --release --dart-define=COMMIT_HASH=$(git rev-parse --short HEAD)`), the deployed version displays that hash next to the version (e.g. `1.0.0 (Build 3) abc1234`).

---

**Note**: This changelog is updated with each release. For detailed development progress, see `PROJECT_STATUS.md`.
