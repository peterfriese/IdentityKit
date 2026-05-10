# IdentityKit: Agent Guidelines

You are an AI engineering agent helping build **IdentityKit**, a Swift package for Firebase Authentication.

## Core Directives

1. **Follow Existing Patterns**: Study existing code in `Sources/IdentityKit/` before implementing new features.
2. **No Breaking Changes**: Maintain API stability — IdentityKit is used by external projects.
3. **Documentation**: Keep README.md current with any API changes.
4. **Testing**: Use Swift Testing framework in `Tests/IdentityKitTests/`.

## Technical Stack

- **Package Manager**: Swift Package Manager
- **Dependency**: Firebase Auth (firebase-ios-sdk)
- **Deployment Target**: iOS 17+
- **Testing**: Swift Testing

## Project Conventions

### Identity

- **Name**: IdentityKit (exact spelling)
- **Bundle ID**: N/A (package, not app)
- **Module name**: `IdentityKit`

### Architecture

- **Single package**: All code in `Sources/IdentityKit/`
- **Service pattern**: Core services (AuthenticationService, AccountService) with protocol-based extension for providers
- **Error handling**: Use `AuthenticationError` enum for all error types

### New Feature Structure

When adding a new auth provider:

1. **Protocol extension**: Add to existing service file (e.g., `AuthenticationService+<Provider>.swift`)
2. **Provider view**: Create in `Views/<Provider>/`
3. **Tests**: Add to `Tests/IdentityKitTests/`
4. **Export**: Update main `IdentityKit.swift` if needed
5. **README**: Document the new provider

## Luca & Lucafile

Luca (`luca`) is the project's skill manager. The `Lucafile` at the project root defines skill definitions and agent configurations.

### Skill Management Rules

- **Only install explicitly requested skills** — never install "all" skills from a repo
- **Skills go in `.agents/skills/`** — if Luca creates a `skills/` folder at the project root with agent subfolders, that's wrong. Remove it.
- **Never create per-agent skill folders** — Luca creates subfolders for claude-code, github-copilot, gemini, opencode, antigravity, etc. Only the skills explicitly listed in the Lucafile should be installed.

### Local Development Toggle

IdentityKit can be consumed as:
- **Remote SPM package** (default) — standard SPM consumption
- **Local Tuist project** — for downstream projects (like Sofia) that want to develop locally

When IdentityKit is used as a local Tuist project, a `Project.swift` file must exist at the repository root.

**Toggle mechanism:**
- Remote: IdentityKit referenced via SPM in `Tuist/Package.swift`
- Local: IdentityKit referenced as `.project()` in downstream project's `Workspace.swift`

**Impact on consumers:**
- SPM consumers: Unaffected — `Package.swift` remains unchanged
- Tuist consumers: Can switch between local/remote via configuration files

### Running Luca

- Run `luca install` at session start to verify skills are loaded
- Run `luca install` after any Lucafile changes to sync

## Session & Process Rules

### Build & Compilation

- **Always use FlowDeck**: `flowdeck build` and `flowdeck test`
- IdentityKit is an SPM-only package — if FlowDeck fails, fallback to `swift build` and `swift test`
- For downstream projects with Xcode workspaces (e.g., `Examples/IdentityKitFirebaseSample/`), always use FlowDeck
- NEVER claim the code compiles without actually running the build command

### Escalation Protocol

- If the same fix fails 2 times, STOP. Do not attempt a 3rd time without asking the user
- Document what you tried and why it failed before asking for direction

### Documentation Sync

- After completing any task, update README.md if needed
- If adding new public APIs, document them

### Prohibited Technologies

- **No Combine**: Use async/await instead
- **No external UI frameworks**: Only use SwiftUI (built into iOS 17+)

### Git Workflow

- All changes go through feature branches and PRs
- Squash and merge unless history is important
- Never push directly to main
- **Use Conventional Commits**: Format commit messages as `type(scope): description`
  - Types: `feat`, `fix`, `refactor`, `docs`, `chore`, `test`, `build`, `perf`, `ci`
  - Examples: `feat(account): add AccountView`, `fix(platform): resolve iOS/macOS compatibility`
  - PR titles should also follow this format

### Planning & Branch Strategy

**Before coding:**
1. Map out dependencies and branch/PR structure
2. Identify logical units that can be separated into independent PRs
3. Plan infrastructure changes first, then features that depend on them

**Commit strategy:**
- Each commit = one logical change
- Keep commits small and focused
- Example good history:
  ```
  feat(platform): add PlatformProxy abstraction layer
  fix(google): restore bundle: .module for image loading
  refactor(account): centralize provider mapping logic
  feat(account): add AccountView with guest/authenticated states
  ```

**Merging order:**
- Merge infrastructure PRs first
- Feature PRs should be rebased (not merged) onto main after infrastructure is merged to maintain linear history
- Avoid merging main into feature branches - this causes divergence and conflicts

#### PR Structure
- Keep PRs atomic - one feature/fix per PR
- PRs should have clear, focused scope
- Infrastructure (fixes, refactors) should be merged before features that depend on them