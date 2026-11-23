# .NET Profile

How the core conventions are realised in an ASP.NET Core app, and the rules only .NET needs.
Normative for every app the **Stacks** table in `AGENTS.md` assigns to .NET. It realises
[`architecture.md`](architecture.md), [`coding.md`](coding.md), [`security.md`](security.md) and
[`testing.md`](testing.md); it never relaxes them. The .NET version, the validation library, the
background-work host and the database provider are fixed by the stack ADR.

## Scope

Applies to:

- every `*.cs`, `*.csproj`, `*.sln`/`*.slnx`, `Directory.Build.props`, `Directory.Packages.props`
- `appsettings*.json`, EF Core migrations

## Concepts

| Concept | .NET |
| --- | --- |
| Entry point | Minimal API endpoint (preferred) or controller action; a hosted worker's loop; a message consumer |
| Input validation | The ADR's validator — built-in minimal-API validation with data annotations, or FluentValidation — run before the handler |
| Command | `sealed record <Verb><Noun>Command`, immutable, `required` members |
| Action | `internal sealed class <Verb><Noun>Handler` with one `HandleAsync(command, CancellationToken)` |
| Query | `internal sealed class <Name>Query` with one `ExecuteAsync`, `AsNoTracking()` and a `Select` projection |
| Repository | None by default — `DbContext` is the unit of work. Never a generic repository over it |
| Model | EF Core entity, mapped by one `IEntityTypeConfiguration<T>` per entity |
| Response | `sealed record <Name>Response` |
| List response | The project's one `PagedResponse<T>` |
| Job / Listener | `BackgroundService`, or the ADR's job host or broker consumer, calling a handler |
| Event | `sealed record` integration event, published through an outbox |
| Module | One project per module plus its `.Contracts` project |
| Surface declaration | One `MapGroup` per surface, in the host's endpoint registration |
| Arch tests | NetArchTest or ArchUnitNET, plus project references |
| Formatter | `dotnet format` with the committed `.editorconfig` |

## Solution layout and modules

```
src/
├── Host/                               composition root: Program.cs, surfaces, middleware
├── Modules/
│   └── Catalog/
│       ├── Catalog.csproj              everything internal
│       └── Catalog.Contracts.csproj    the public surface: interfaces, integration events, response records
└── Shared/Kernel.csproj                the shared kernel; references no module
tests/
└── Modules/Catalog.Tests/
```

- **Visibility is the seam.** Everything in a module project is `internal`; only its `.Contracts`
  project is `public`. A module project references other modules' `.Contracts` projects, never
  their implementation projects. `InternalsVisibleTo` names the module's own test project and
  nothing else.
- Each module registers itself through two extension methods the host calls —
  `AddCatalogModule(this IServiceCollection, IConfiguration)` and
  `MapCatalogEndpoints(this IEndpointRouteBuilder)`.
- Each module owns its `DbContext` and its migrations. At Level 2 it sets `HasDefaultSchema("catalog")`
  and no entity maps another module's table. Separate contexts cannot map relations across modules,
  so cross-module reads always go through the owner's contracts, at every level.
- The project-reference graph is the declared module graph; an arch test asserts no type in one
  module depends on another module's non-contract namespace.

## Surfaces

```csharp
var admin = app.MapGroup("/api/admin")
    .RequireAuthorization(Policies.Admin);

admin.MapCatalogAdminEndpoints();
```

- Surface policies are applied to the group, once. An endpoint never calls
  `RequireAuthorization` with a surface policy, and `AllowAnonymous` appears only on the sign-in
  group.
- **Deny by default:** `AddAuthorizationBuilder().SetFallbackPolicy(...)` requires an authenticated
  user for every endpoint with no authorization metadata.
- Record authorization is resource-based: `IAuthorizationService.AuthorizeAsync(user, record, policy)`
  inside the handler.

## The core rules, in C#

```csharp
var command = request.ToCommand(userId);

var product = await handler.HandleAsync(command, cancellationToken);

var response = ProductResponse.From(product);

return TypedResults.Ok(response);
```

- Endpoints return `TypedResults` / `Results<…>` unions, so the OpenAPI document knows every shape.
  Status codes come from `StatusCodes`, never literals.
- Errors leave as RFC 9457 ProblemDetails: `AddProblemDetails()` plus an `IExceptionHandler`; no
  stack trace outside Development.
- Client types are generated from the OpenAPI document the app publishes, in the same change that
  alters a Command or Response.

## Language rules

- `Directory.Build.props` sets `<Nullable>enable</Nullable>`, `<TreatWarningsAsErrors>true</TreatWarningsAsErrors>`,
  `<AnalysisLevel>latest-recommended</AnalysisLevel>`, `<EnforceCodeStyleInBuild>true</EnforceCodeStyleInBuild>`.
  Package versions are central in `Directory.Packages.props`.
- Classes are `sealed` unless designed for inheritance; Commands, Responses and events are records.
- Async all the way: every async method takes and forwards a `CancellationToken`; no `.Result`,
  `.Wait()` or `async void` outside event handlers; no `Task.Run` on the request path.
- Enum predicates are extension methods in a `<Enum>Extensions` class beside the enum.
- Dependency lifetimes are validated at build (`ValidateOnBuild`, `ValidateScopes`): no singleton
  captures a scoped service.
- Logging uses message templates, never interpolated strings, so properties stay structured.

## Configuration

- Options classes bound with `AddOptions<T>().BindConfiguration("Section").ValidateDataAnnotations().ValidateOnStart()`.
  No `Environment.GetEnvironmentVariable` outside `Program.cs`.
- No secret in `appsettings*.json`: user-secrets locally, the deployment's secret store elsewhere.
- Data Protection keys are persisted to shared storage when more than one instance runs.

## Data access

- Reads: `AsNoTracking()`, a `Select` projection straight to the Response, and `ToListAsync` last.
  Lazy-loading proxies are off. More than one collection `Include` uses `AsSplitQuery()`.
- Writes on money and state use a concurrency token on the entity, or an atomic
  `ExecuteUpdateAsync` whose `Where` carries the expected state and whose affected-row count is
  checked.
- Raw SQL only through `FromSql` / `ExecuteSql` with interpolated (parameterised) strings;
  `FromSqlRaw` never receives concatenated input.
- Delete behaviour is set explicitly in configuration (`OnDelete(DeleteBehavior.Restrict)` for
  history). Money is `decimal` with `HasPrecision`, or a `long` of minor units.
- Migrations: one per change, generated with `dotnet ef migrations add`, never edited after they ran
  anywhere but your machine. Production applies a generated idempotent script or bundle, not
  `Database.Migrate()` at startup.
- Lists project inside `IQueryable` and return the project's `PagedResponse<T>`; keyset paging for
  tables expected to grow past a few hundred thousand rows.

## Security mechanisms

| Rule | .NET mechanism |
| --- | --- |
| Deny by default | Fallback authorization policy; surface policies on groups |
| Record authorization | Resource-based `IAuthorizationService` in the handler |
| Raw-HTML sinks | `@Html.Raw` in Razor, `MarkupString` in Blazor |
| Over-posting | Bind requests to Commands, never to entities |
| CSRF | Antiforgery on cookie-authenticated form posts (`UseAntiforgery`) |
| Outbound credentials | `IHttpClientFactory` typed clients with a configured `BaseAddress`; no absolute URLs from input |
| Throttling | `AddRateLimiter` policies on the auth and webhook groups |

## Naming

- PascalCase for types, methods, properties and constants; camelCase for locals and parameters;
  `_camelCase` for private fields.
- Interfaces take the `I` prefix — the .NET idiom overrides the core's no-prefix rule.
- Methods returning `Task` end in `Async`.
- Handlers are `<Verb><Noun>Handler`, Queries `<Name>Query`, Commands `<Verb><Noun>Command`,
  Responses `<Name>Response`, background workers `<Work>Worker`.
- One type per file, file-scoped namespaces, namespaces matching folders.
- Member order: constants, fields, constructors, properties, public methods, private methods.

## Testing

- xUnit. Feature tests through `WebApplicationFactory<Program>` against a real database in
  Testcontainers — never the EF in-memory provider, which does not enforce constraints or speak SQL.
- Trace with traits: `[Trait("Requirement", "0012.R3")]`, filtered by trait to run one requirement.
- Fakes for outbound HTTP assert the request URI's host as well as the payload. Time comes from an
  injected `TimeProvider`, replaced by `FakeTimeProvider` in tests.
- Arch tests (NetArchTest or ArchUnitNET) assert module visibility, handler naming, and that
  endpoints do not reference `DbContext` where the flow forbids it.

## Tooling

- Formatting and style: `dotnet format --verify-no-changes` in CI.
- Complexity: analyzer CA1502 with a `CodeMetricsConfig.txt` setting `CA1502: 10`, or `lizard`,
  run outside the tree.
- Dead code: IDE0051, IDE0052, CA1812 and IDE0005 as warnings.
- Dependencies: `dotnet list package --vulnerable --include-transitive`, `--outdated`, `--deprecated`.

---

Related: [`architecture.md`](architecture.md) · [`coding.md`](coding.md) · [`security.md`](security.md)
