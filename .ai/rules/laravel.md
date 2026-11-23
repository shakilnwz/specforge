---
paths:
  - '**/*.php'
  - composer.json
---

# Laravel

## Bound conventions
`docs/conventions/stack-laravel.md` realises the core conventions for every Laravel app. Read it
beside the core section it realises; where the two seem to disagree, the core wins and the profile
is a defect to report.

## Traps agents fall into here
- A route file never sets its host, prefix, transport middleware or guard; `RouteServiceProvider`'s
  mount table does.
- A list endpoint gets no FormRequest, Data object or Action, and returns a `*DataTableResponse`.
- A response shape is a Resource; never an array literal beyond the bare `message` envelope.
- Reusable filters are `by<Attribute>` on the module's QueryBuilder — never `where*`, and never a
  scope that holds a rule.
- `env()` only in `config/`; read settings with `config()`.
- Queues dispatch `after_commit`; a job's `$timeout` stays below its queue's `retry_after`.

## Framework mechanics
- Confirm a package's installed version (`composer show <vendor/package>`) before relying on its
  API; where Laravel Boost is installed, use `search-docs` for version-specific behaviour.
- Create files with `php artisan make:<type> --no-interaction`, then move them into the module and
  bring them to the conventions.
- Formatting (`vendor/bin/pint --dirty --format agent`) runs with lint, when asked; CI enforces it.
- Tests are Pest, tagged `->group('NNNN.Rn')`; when asked to run them, run the minimum:
  `php artisan test --compact --filter=<Name>` or `--group=NNNN.Rn`.
- A "Unable to locate file in Vite manifest" error means the asset was never built — ask, do not
  guess.
