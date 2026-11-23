---
paths:
  - '**/*.cs'
  - '**/*.csproj'
  - '**/*.sln'
  - '**/*.slnx'
  - Directory.Build.props
  - Directory.Packages.props
---

# .NET

## Bound conventions
`docs/conventions/stack-dotnet.md` realises the core conventions for every .NET app. Read it beside
the core section it realises; where the two seem to disagree, the core wins and the profile is a
defect to report.

## Traps agents fall into here
- Everything in a module project is `internal`; only its `.Contracts` project is `public`. Another
  module references `.Contracts`, never the implementation project. `InternalsVisibleTo` names the
  module's own test project and nothing else.
- An endpoint never calls `RequireAuthorization` with a surface policy; its `MapGroup` does, and the
  fallback policy denies anything outside a group.
- Endpoints return `TypedResults`, never `Results.Ok(new { … })`.
- Async all the way: every async method takes and forwards a `CancellationToken`; never `.Result`,
  `.Wait()` or `async void`.
- Reads use `AsNoTracking()` and project with `Select` to the Response; a request body never binds
  to an entity.
- Options validate on start (`ValidateOnStart`); a missing setting stops the host.

## Framework mechanics
- Package versions live in `Directory.Packages.props`; check the installed version before relying on
  an API. Adding, removing or upgrading a package needs the owner's approval.
- Formatting: `dotnet format`, run with lint when asked; CI runs `--verify-no-changes`.
- Tests are xUnit, tagged `[Trait("Requirement", "NNNN.Rn")]`, against a real database through
  Testcontainers — never the EF in-memory provider. Time comes from `TimeProvider`.
- When asked to run tests, run the minimum: `dotnet test --filter "Requirement=NNNN.Rn"` or a
  `FullyQualifiedName~<Name>` filter.
