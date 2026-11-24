# Laravel Profile

How the core conventions are realised in a Laravel app, and the rules only Laravel needs.
Normative for every app the **Stacks** table in `AGENTS.md` assigns to Laravel. It realises
[`architecture.md`](architecture.md), [`coding.md`](coding.md), [`security.md`](security.md) and
[`testing.md`](testing.md); it never relaxes them. A Vue or React frontend in the same app follows
[`stack-vue.md`](stack-vue.md) or [`stack-react.md`](stack-react.md), under its own row of the
**Stacks** table.

## Scope

Applies to:

- every `*.php` file, `composer.json`, Blade templates, `config/`, `routes/`, `database/`

## Concepts

| Concept | Laravel |
| --- | --- |
| Entry point | Controller method; Artisan command; queued Job's `handle()` |
| Input validation | `FormRequest` (`rules()`, `authorize()`) |
| Command | `final readonly` DTO (`<Verb><Noun>Data` or `<Verb><Noun>Command`), constructed from a `FormRequest` |
| Action | `final` class `<Verb><Noun>Action` with one public `execute()` |
| Query | `final` class under `Queries/`, called with request primitives |
| Repository | `final` class under `Repositories/`, only where complex or reused; no interface |
| Model | Eloquent model; reusable filters on a custom QueryBuilder (`newEloquentBuilder()`) |
| Response | `Illuminate\Http\Resources\Json\JsonResource` under `Http/Resources/` |
| List response | The project's one paginated list response (`ResourceCollection` or `Responsable` wrapper over `paginate()` / `cursorPaginate()`) |
| Job / Listener | Queued Job implementing `ShouldQueue` (extending a queue-tier base class or trait); Listener calling an Action |
| Module | `modules/<Module>/` via Composer PSR-4 autoloading and module `ServiceProvider`s |
| Surface declaration | One mount table in `bootstrap/app.php` (`withRouting()`) or a dedicated `RouteServiceProvider` |
| Arch tests | Pest `arch()` (and an optional dependency checker such as `deptrac`, if ADR-0001 adopts one) |
| Formatter | Pint (`declare_strict_types` on) |

## Modules

When ADR-0002 declares the app modular, `modules/<Module>/` is a bounded slice — PHP classes under
`app/` (or `src/`), plus `config/`, `database/`, `lang/`, `resources/`, `routes/`, and `tests/` —
with flat namespaces (`Modules\Product\Models\Product`). Standard Composer PSR-4 autoloading maps
each module namespace, and `bootstrap/providers.php` registers each module's `ServiceProvider`
(adopting a module package is an ADR-0001 choice, not a rule requirement). Package requires stay at
the app level.

- A module's public surface is its `Contracts/` namespace, its `Events/`, and its `Queries/`. Another
  module importing anything else under `Modules\<Other>\` — a Model, an Action, a Repository, a
  Resource — is reaching through the seam.
- Invisible edges are `<module>::` translation and view namespaces, `config('<module>.…')` reads,
  and container bindings by string. They count as dependencies.
- Pest `arch()` tests (and any dependency checker chosen in ADR-0001, run from CI) hold the graph
  to the one declared in ADR-0002.

## Routes and surfaces

A module's routes live at

```
modules/<Module>/routes/<surface>/<transport>/<resource>.php
```

and that path is the whole of where a route is mounted. The surface fixes the host, the guard and
the middleware group; the transport is `web` or `api`, fixes the URL namespace and names the
consumer — `api` for an SPA's XHR, `web` for what the browser navigates to. The transport says
nothing about state: an `api` mount may run the session-backed `web` group, as an admin SPA does,
and a `web` mount may drop the session and CSRF middleware, as a payment gateway's return surface
does. The app's single routing mount table (`bootstrap/app.php` or a dedicated `RouteServiceProvider`)
is the only place any of it is set.

- **A route file never sets what its directory means.** No `Route::domain()`, no `web` or `api`
  middleware, no URL starting with a mount prefix (`api/`, `web/`, `admin/`, `account/`), and no
  surface guard.
- **`auth.php` is the one reserved name.** It is mounted without its surface's guard, and assigns
  `guest` and `auth` route by route. It holds the sign-in, sign-up and recovery screens, and the
  pages those screens link to.
- Middleware about the route itself stays in the file: `can:`, `throttle:`, or `signed` on a route
  whose mount does not already apply it.
- One file per resource, kebab-case after the URL segment: `brands.php` holds `brands/*`.
- `api` answers JSON only. A session-backed JSON call whose URL is outside `/api` — a storefront
  cart — sits in `web`.
- `GET <resource>/{id}` uses `->whereNumber()` on each id. `edit` names only a server-rendered
  screen under `web`.
- When the app serves SPA catch-all routes, register them after every surface mount and exclude the
  API and server-rendered prefixes.

`tests/Arch/RouteFileTest.php` fails a route file outside a mount, and one that sets any part of its
mount itself.

## List endpoints

Every list returns the project's **one** paginated list envelope — Laravel's standard
`ResourceCollection` over `paginate()` or `cursorPaginate()`, or a single shared `Responsable` list
response declared in ADR-0001 — so it satisfies the controller return-type rule with no ad-hoc
wrapping. Filtering, sorting, and pagination execute in SQL (`select()`, `where()`, `orderBy()`,
`paginate()` / `cursorPaginate()`), never by loading the full table into memory.

```php
public function index(Request $request): AnonymousResourceCollection
{
    $tickets = Ticket::query()
        ->byCustomer($this->authenticatedCustomerId())
        ->byStatus($request->enum('status', TicketStatus::class))
        ->paginate(25);

    return TicketResource::collection($tickets);
}
```

- Resolve enum filters with `$request->enum()`, which yields `null` for anything unrecognised.
- A caching list caches the rendered payload keyed on every active list parameter (`page`,
  `per_page`, `sort`, `search`, filters) with a TTL and the module's version key.
- The route uses the resource's standard `index` route beside its other routes:
  `Route::get('tickets', [TicketController::class, 'index'])->name('admin.tickets.index');`.

## Models

Members are declared in this order of groups; within a group the existing order stands.

1. Trait `use` statements — one per statement, alphabetical, contiguous with no blank line between
2. Constants
3. Configuration properties: `$connection`, `$table`, `$primaryKey`, `$keyType`, `$incrementing`,
   `$timestamps`, `$dateFormat`, `$fillable` or `$guarded`, `$hidden`, `$visible`, `$appends`,
   `$with`, `$withCount`, `$dispatchesEvents`, then model-specific
4. `booted()` / `booting()` / `boot()`
5. `casts()`
6. `newEloquentBuilder()`, `newFactory()`
7. Relations
8. Accessors and mutators — the methods returning `Attribute`
9. Scopes
10. Any remaining method

Every member is separated from the next by one blank line, the trait block excepted.

- Casts are the `casts()` method, never a `$casts` property:

  ```php
  /** @return array<string, string> */
  protected function casts(): array
  {
      return [
          'status' => StoreStatus::class,
      ];
  }
  ```

- Reusable filters live on the module's QueryBuilder and follow the `by<Attribute>` naming. Never
  `where<Anything>`: Laravel owns that prefix for its own methods and for the `__call` dynamic-where
  fallback, which a custom `whereSlug()` silently shadows.
- Mass assignment goes through `$fillable` populated from a Command DTO, never `$request->all()`.

## The core rules, in PHP

Construction is its own step; the Action's result is its own step:

```php
$command = SaveStoreData::fromRequest($request);

$store = $action->execute($command);

$resource = new StoreCreatedResource($store);

return $resource->response();
```

`response()->json($action->execute($id))` builds nothing and stays inline; so does
`return new StoreCreatedResource($store);`. A plain accessor stays in the argument:
`CreateTicketData::fromRequest($request, $this->authenticatedCustomerId())`.

An Action receives variables:

```php
$addressId = (int) $request->input('address_id');

$action->execute($addressId);
```

A query is its own step, whether or not it ends in a fetch, and a query feeding a Resource is two
steps:

```php
$page = Page::query()
    ->forAdmin()
    ->withDetails()
    ->findOrFail($pageId);

$resource = new PageResource($page);

return $resource->response();
```

A construction on one branch stays there — hoisting it turns the `null` into a fatal:

```php
return $customer ? new CustomerAccountResource($customer) : null;
```

Status codes come from `Symfony\Component\HttpFoundation\Response` constants. The acknowledgement
envelope is `response()->json(['message' => trans('…')])`.

## Formatting

- A constructor that promotes a property is always broken, down to a single one — those parameters
  are the class's property declarations, and a property list reads down a column:

  ```php
  public function __construct(
      private IssueTwoFactorCodeAction $issueTwoFactorCode,
  ) {}
  ```

- A promoted property carrying a docblock or attribute is separated from its neighbours by one blank
  line on each side (omitted before the first and after the last):

  ```php
  public function __construct(
      public readonly string $status,

      /** @var list<OrderStatusOptionResource> */
      public readonly array $availableStatuses,

      public readonly ?string $note,
  ) {}
  ```

- A parameter list whose parameters carry attributes or docblocks stays broken however short. A
  docblock on the method itself (`@param`, `@throws`) does not count.
- An empty body stays on the signature line: `public function handle(): void {}`.
- Prefer PHPDoc with array shapes over inline comments.

## Naming

- Interfaces have no `Interface` or `Contract` suffix — `Modules\Subscription\Contracts\BillingPeriodResolver`.
  Where one file needs the interface and a same-named class, alias the import with `Contract`:
  `use Modules\Subscription\Contracts\BillingPeriodResolver as BillingPeriodResolverContract;`
- Jobs have no `Job` suffix — `Modules\Billing\Jobs\NotifyTransactionPaid`. Where one file needs a
  job and a same-named listener or action, alias the job import with `Job`. Abstract queue-tier base
  classes keep it — `HighPriorityEmailJob`, `CpuIntensiveJob` — because the word names the tier.
- Actions end in `Action`; enum cases are TitleCase; route names and Blade filenames are kebab-case.

## Configuration

- `env()` is read only inside `config/`; everywhere else reads `config()`, which survives
  `config:cache`.
- A required setting is checked in a service provider's `boot()` and throws when missing. The cache
  store must support atomic locks (`redis`, `database`, `memcached`, `dynamodb`); `file` and `array`
  are refused outside local development.
- Queues dispatch `after_commit`; each queue's `retry_after` exceeds the longest `$timeout` on it.

## Security mechanisms

| Rule | Laravel mechanism |
| --- | --- |
| Deny by default | Surface guard on every mount; `auth.php` the only exception |
| Record authorization | Policies, `can:` route middleware, `Gate::authorize()` inside the Action |
| Raw-HTML sinks | `{!! !!}` in Blade |
| Row lock | `lockForUpdate()` inside `DB::transaction()` |
| Raw SQL | `DB::raw`, `selectRaw`, `whereRaw`, `orderByRaw` — bindings only |
| Signed surface | `signed` middleware on the mount; `URL::temporarySignedRoute()` |
| CSRF exemption | `bootstrap/app.php` `validateCsrfTokens(except: …)`, each backed by an ADR |

## Testing

- Pest. `php artisan make:test <Name> --no-interaction`; `--unit` only for pure units.
- Trace with groups: `it('refuses a withdrawal above the balance', …)->group('0012.R3');` and run one
  requirement with `php artisan test --compact --group=0012.R3`.
- Fakes: `Http::fake()` (assert the host), `Queue::fake()`, `Event::fake()`, `Mail::fake()`;
  `$this->travelTo()` for time.
- The suite creates its own database and refuses to run against one whose name lacks the test suffix.
- `preventLazyLoading()` and `preventSilentlyDiscardingAttributes()` are on outside production.

## Tooling

- Create files with `php artisan make:<type> --no-interaction`, then move them into the module.
- Confirm installed versions with `composer show <vendor/package>` before relying on an API.
- Laravel Boost, where installed: `search-docs` for version-specific behaviour, `database-schema`
  before a migration, `record-rule` for durable rules into `.ai/rules/`.
- Formatting: `vendor/bin/pint --dirty --format agent`. Static analysis: Larastan at the level the
  stack ADR sets.
- Complexity: a `nikic/php-parser` walker or `lizard`, run outside the tree. Unused packages:
  `composer-unused`.

---

Related: [`stack-vue.md`](stack-vue.md) · [`stack-react.md`](stack-react.md) · [`architecture.md`](architecture.md) · [`coding.md`](coding.md)
