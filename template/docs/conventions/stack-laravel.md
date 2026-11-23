# Laravel Profile

How the core conventions are realised in a Laravel app, and the rules only Laravel needs.
Normative for every app the **Stacks** table in `AGENTS.md` assigns to Laravel. It realises
[`architecture.md`](architecture.md), [`coding.md`](coding.md), [`security.md`](security.md) and
[`testing.md`](testing.md); it never relaxes them. A Vue frontend in the same app follows
[`stack-vue.md`](stack-vue.md).

## Scope

Applies to:

- every `*.php` file, `composer.json`, Blade templates, `config/`, `routes/`, `database/`

## Concepts

| Concept | Laravel |
| --- | --- |
| Entry point | Controller method; Artisan command; queued Job's `handle()` |
| Input validation | `FormRequest` (`rules()`, `authorize()`) |
| Command | Spatie `Data` object, `readonly` properties, with TypeScript generation |
| Action | `final` class `<Verb><Noun>Action` with one public `execute()` |
| Query | `final` class under `Queries/`, called with request primitives |
| Repository | `final` class under `Repositories/`, only where complex or reused; no interface |
| Model | Eloquent model; reusable filters on a custom QueryBuilder (`newEloquentBuilder()`) |
| Response | Spatie `Resource` under `Http/Resources/` |
| List response | `*DataTableResponse` extending the project's shared `DataTableResponse` |
| Job / Listener | Queued Job extending a tier in `Modules\Core\Jobs`; Listener calling an Action |
| Module | `modules/<Module>/` via `nwidart/laravel-modules` |
| Surface declaration | `Modules\Core\Providers\RouteServiceProvider` |
| Arch tests | Pest `arch()`; `deptrac` for the module graph |
| Formatter | Pint (`declare_strict_types` on) |

## Modules

`modules/<Module>/` is a mini-application — PHP classes under `app/`, then `config/`, `database/`,
`lang/`, `resources/`, `routes/`, `tests/` — with flat namespaces, so `Modules\Product\Models\Product`
lives in `modules/Product/app/Models/`. Discovery is `nwidart/laravel-modules`; every directory is a
module, with no on/off registry. Each app's `Modules\Core\Providers\ModuleServiceProvider` binds the
module directories at runtime. A module's `composer.json` declares only its own psr-4 roots, which
`wikimedia/composer-merge-plugin` folds into the app's — adding a module means adding its
`composer.json`, not editing the app's. Package requires stay at the app level.

- A module's public surface is its `Contracts/` namespace, its `Events/`, and its `Queries/`. Another
  module importing anything else under `Modules\<Other>\` — a Model, an Action, a Repository, a
  Resource — is reaching through the seam.
- Invisible edges are `<module>::` translation and view namespaces, `config('<module>.…')` reads,
  and container bindings by string. They count as dependencies.
- `deptrac` (run from CI) holds the graph to the one declared in ADR-0002.

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
does. `RouteServiceProvider`'s mount table is the only place any of it is set.

- **A route file never sets what its directory means.** No `Route::domain()`, no `web` or `api`
  middleware, no URL starting with a mount prefix (`api/`, `web/`, `admin/`, `account/`), and no
  surface guard.
- **`auth.php` is the one reserved name.** It is mounted without its surface's guard, and assigns
  `guest` and `auth` route by route. It holds the sign-in, sign-up and recovery screens, and the
  pages those screens link to.
- Middleware about the route itself stays in the file: `can:`, `throttle:`, `honeypot`, or `signed`
  on a route whose mount does not already apply it.
- One file per resource, kebab-case after the URL segment: `brands.php` holds `brands/*`.
- `api` answers JSON only. A session-backed JSON call whose URL is outside `/api` — a storefront
  cart — sits in `web`.
- `GET <resource>/{id}` uses `->whereNumber()` on each id. `edit` names only a server-rendered
  screen under `web`.
- The provider registers the panel SPAs after the mounts; their catch-all excludes each panel's
  `api/` and `web/` namespaces, which is why every server-rendered panel route lives under `web/`.

`tests/Arch/RouteFileTest.php` fails a route file outside a mount, and one that sets any part of its
mount itself.

## List endpoints

Every list returns the DataTables.net envelope — `draw`, `recordsTotal`, `recordsFiltered`, `data`,
nothing else — produced by a `*DataTableResponse`. It is `Responsable`, so it satisfies the
controller return-type rule with no wrapping. Rows are projected through `addColumn` and
`editColumn`; the Eloquent engine must own the projection to push filtering down into SQL.

```php
public function datatable(): TicketDataTableResponse
{
    $tickets = Ticket::query()
        ->customerList($this->authenticatedCustomerId());

    return new TicketDataTableResponse($tickets);
}
```

- Resolve enum filters with `$request->enum()`, which yields `null` for anything unrecognised.
  Paging, ordering and search arrive in the DataTables parameters and are never read off the request.
- A caching list caches the rendered payload keyed on `start`, `length` and `search[value]` — not on
  `page` and `per_page` — because the engine applies them inside `render()`, after the controller
  has handed the builder over.
- The route is named `datatable` and sits beside the resource's other routes:
  `Route::get('tickets/datatable', [TicketController::class, 'datatable'])->name('admin.tickets.datatable');`

## Models

Members are declared in this order of groups; within a group the existing order stands.

1. Trait `use` statements — one per statement, alphabetical, contiguous with no blank line between
2. Constants
3. Configuration properties: `$connection`, `$table`, `$primaryKey`, `$keyType`, `$incrementing`,
   `$timestamps`, `$dateFormat`, `$fillable` or `$guarded`, `$translatedAttributes`, `$hidden`,
   `$visible`, `$appends`, `$with`, `$withCount`, `$dispatchesEvents`, then model-specific
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
- Mass assignment goes through `$fillable` populated from a `Data` object, never `$request->all()`.

## The core rules, in PHP

Construction is its own step; the Action's result is its own step:

```php
$data = SaveStoreData::fromRequest($request);

$store = $action->execute($data);

$resource = StoreCreatedResource::fromData($store, $data->store_name);

return response()->json($resource);
```

`response()->json($action->execute($id))` builds nothing and stays inline; so does
`return StoreCreatedResource::fromData($store, $data->store_name);`. A plain accessor stays in the
argument: `CreateTicketData::fromRequest($request, $this->authenticatedCustomerId())`.

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

$resource = PageResource::fromModel($page);

return response()->json($resource);
```

A construction on one branch stays there — hoisting it turns the `null` into a fatal:

```php
return $customer ? CustomerAccountData::fromModel($customer) : null;
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

      /** @var OrderStatusOptionResource[] */
      #[DataCollectionOf(OrderStatusOptionResource::class)]
      public readonly DataCollection $available_statuses,

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
  job and a same-named listener or action, alias the job import with `Job`. The abstract queue tiers
  in `Modules\Core\Jobs` keep it — `HighPriorityEmailJob`, `CpuIntensiveJob` — because the word names
  the tier.
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
| Raw-HTML sinks | `{!! !!}` in Blade, `v-html` in Vue, `|raw` in Twig |
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

Related: [`stack-vue.md`](stack-vue.md) · [`architecture.md`](architecture.md) · [`coding.md`](coding.md)
