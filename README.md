# Digital Ebook Library

A small full-stack product: a Ruby on Rails JSON API backend and a Flutter
frontend styled as a classic bookshelf, letting a user upload, browse,
search, read, download, and delete ebooks (PDF, with EPUB accepted for
storage/download).

```
ebook-library/
├── backend/     Rails API (Ruby on Rails 7, API-only, SQLite, Active Storage)
└── frontend/    Flutter app (Provider for state, Dio/http for networking)
```

## 1. Project overview

- **Backend**: Rails API exposing CRUD + search + download endpoints for
  ebooks. Files are stored with Active Storage on local disk.
- **Frontend**: Flutter app with a bookshelf-style library screen, an
  upload flow, debounced search, and an in-app PDF reader.
- **Product framing**: the goal was a small, honest product, not a demo —
  explicit empty/loading/error states, delete confirmation, and graceful
  handling of unsupported file types and oversized uploads.

## 2. Tech stack

| Layer | Choice | Why |
|---|---|---|
| Backend | Ruby on Rails 7 (API-only), SQLite, Active Storage | Fast to build a clean REST API with file handling and validations without the overhead of a separate object-storage service for local dev. |
| Backend tests | RSpec + FactoryBot | Standard, readable request/model specs. |
| Frontend | Flutter (Dart), Provider | Provider keeps state management simple and testable without extra boilerplate for an app this size. |
| Frontend networking | `http` (JSON) + `dio` (multipart upload / binary download) | `dio` makes multipart upload and byte-stream download noticeably less code than raw `http`. |
| Frontend reading | `flutter_pdfview` | Lightweight native PDF rendering with page callbacks for a page counter. |

### On Active Storage

Ebook files and optional cover images are attached to the `Ebook` model via
Active Storage (`has_one_attached :file`, `has_one_attached :cover`), using
the `Disk` service (`config/storage.yml`) so everything runs locally with no
external dependency. Swapping to S3/GCS for production is a config-only
change — no controller/model code would need to change.

## 3. Setup instructions

### Prerequisites

- Ruby 3.2.x, Bundler
- Node is **not** required for the API-only Rails app
- Flutter SDK (3.19+ recommended), with an Android emulator or iOS
  simulator (or a physical device)

### Backend — running it

```bash
cd backend
bundle install
bin/rails db:create db:migrate
bin/rails db:seed        # optional demo data, see "Known limitations"
bin/rails server         # starts on http://localhost:3000
```

### Frontend — running it

```bash
cd frontend
flutter pub get

# Android emulator (10.0.2.2 maps to the host machine's localhost):
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000

# iOS simulator / desktop (simulator shares the host network):
flutter run --dart-define=API_BASE_URL=http://localhost:3000

# Physical device: use your machine's LAN IP instead of localhost, e.g.
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:3000
```

`API_BASE_URL` defaults to `http://10.0.2.2:3000` (Android emulator) if not
passed, since that was the primary target used during development.

### Running tests

```bash
# Backend
cd backend
bundle exec rspec

# Frontend
cd frontend
flutter test
```

> **Note on this submission's environment**: this repository was authored
> in a sandbox without Ruby/Rails or the Flutter SDK installed, so the test
> suites below were written to the same standard I'd use on a real project
> but have not been executed here. Please run `bundle exec rspec` and
> `flutter test` locally to confirm — I'd normally paste the passing output
> into this README, and did not want to fabricate it.

## 4. API overview

Base path: `/api`

| Method | Path | Description |
|---|---|---|
| `GET` | `/ebooks` | List all ebooks, most recently uploaded first. |
| `GET` | `/ebooks/search?q=keyword` | Search by title, author, or original file name. Empty/missing `q` returns everything. |
| `GET` | `/ebooks/:id` | Ebook details. |
| `POST` | `/ebooks` | Upload an ebook. `multipart/form-data`: `title` (required), `author` (optional), `file` (required, PDF/EPUB), `cover` (optional image). |
| `GET` | `/ebooks/:id/download` | Streams the raw file with the correct `Content-Type` and `Content-Disposition: attachment`. |
| `DELETE` | `/ebooks/:id` | Deletes the ebook and its attached files. |

**Example response** (`GET /api/ebooks`):

```json
[
  {
    "id": 1,
    "title": "Clean Code",
    "author": "Robert C. Martin",
    "file_type": "application/pdf",
    "file_size": 2456789,
    "uploaded_at": "2026-06-20T10:15:00.000Z",
    "cover_url": null,
    "download_url": "http://localhost:3000/api/ebooks/1/download"
  }
]
```

**Errors** are always JSON: `{ "errors": ["..."] }` with an appropriate
status code (`404` not found, `422` validation failure, `400` bad request).

## 5. Product thinking / edge cases handled

- **Empty library** → dedicated empty-shelf illustration + upload CTA,
  distinct from "no search results" (which suggests trying another query
  instead of uploading).
- **Upload failure** (bad type, no file, oversized) → inline form error,
  form stays populated so the user doesn't retype everything.
- **Oversized file** → rejected server-side (100 MB cap) with a clear
  message; Rails validation runs before persisting anything.
- **Search, no results** → distinct empty state with the query echoed
  back.
- **Loading states** → spinner while list/search is in flight; pull-to-
  refresh on the shelf.
- **Delete** → confirmation dialog naming the book; optimistic UI removal
  that rolls back if the API call fails, with a snackbar explaining why.
- **Download failure** → surfaced via snackbar rather than failing
  silently.
- **Non-PDF reading** (EPUB) → in-app reading is PDF-only for this
  milestone; EPUB files can still be uploaded, listed, searched, and
  downloaded, and the reader screen explains this instead of showing a
  blank/broken viewer.

## 6. Testing

### Backend (RSpec, `backend/spec`)

- **Model spec** (`spec/models/ebook_spec.rb`): title/file presence,
  supported file types, file size limit, default title fallback, search
  by title/author, blank-query behavior.
- **Request specs** (`spec/requests/api/ebooks_spec.rb`): index (incl.
  empty library), show (incl. 404), create (incl. missing file and
  unsupported type), search, download (incl. content type and 404),
  delete (incl. 404).

### Frontend (`flutter test`, `frontend/test`)

- `library_state_test.dart` — the `LibraryState` notifier: load, empty
  result, error handling, search filtering, optimistic delete with
  rollback on failure.
- `ebook_cover_test.dart` — cover/spine rendering, tap-to-open,
  long-press-to-delete gesture.
- `empty_state_test.dart` — empty-library and no-search-results widgets.
- `library_screen_test.dart` — end-to-end widget test against a fake API:
  ebook cards render, debounced search filters the shelf, delete
  confirmation dialog blocks/allows removal correctly.

A `FakeApiService` (`frontend/test/fakes/fake_api_service.dart`) stands in
for the real network layer so these tests run offline and deterministically.

### Manual testing checklist

- [ ] Fresh install, empty library shows the empty-shelf state
- [ ] Upload a PDF with title + author → appears on the shelf immediately
- [ ] Upload a file with no title → validation blocks submit
- [ ] Upload a `.txt` file → rejected with a clear error
- [ ] Upload a file > 100 MB → rejected with a clear error
- [ ] Search by partial title → filters correctly
- [ ] Search by author → filters correctly
- [ ] Search with no matches → no-results state, not empty-library state
- [ ] Clear search → full shelf returns
- [ ] Tap a PDF → opens in the in-app reader, pages turn, page counter updates
- [ ] Tap an EPUB → shown the "download to read externally" message
- [ ] Download a book → snackbar confirms save location
- [ ] Long-press a book → confirmation dialog appears
- [ ] Confirm delete → book disappears from shelf and from `GET /api/ebooks`
- [ ] Cancel delete → book remains
- [ ] Stop the Rails server, pull-to-refresh in the app → error state with retry, not a crash

## 7. AI tool usage

**Tools used:** Claude (Claude Code / this assistant), used as the primary
pair-programmer for this assignment.

**How it was used:**
- Scaffolding the Rails app structure (routes, controller, model,
  migrations) and the Flutter app structure (screens, state, services,
  widgets) from the written product brief.
- Writing the RSpec and `flutter_test` suites alongside the implementation,
  covering the behaviors explicitly called out in the assignment (upload,
  listing, search, delete, download, validation/error cases, empty states,
  delete confirmation).
- Drafting this README.

**What was manually reviewed / corrected:**
- An early draft of `ApiService`'s JSON decoding had an over-engineered,
  redundant chain of helper methods instead of a direct `dart:convert`
  `jsonDecode` call — caught on review and rewritten to the straightforward
  version that's in the repo now.
- The reader screen's "try again" retry button was initially written with
  a broken/nonsensical `setState` expression (a leftover from an
  in-progress edit); caught on review and replaced with a plain two-step
  `setState` + re-fetch.
- The bookshelf row-wrapping math (`LayoutBuilder` + row-splitting) was
  checked by hand against edge cases (exactly one book, a row that doesn't
  fill evenly) since off-by-one errors there are easy to introduce and easy
  to miss visually.
- Validation and error-handling logic (file type/size limits, 404 vs 422
  vs 400 responses) was reviewed against the assignment's explicit "what
  happens when X fails" prompts rather than accepted as generated.

**Where this leaves ownership:** every file in this repo was read and
reasoned through, not merely accepted — the two corrections above are
exactly the kind of thing a careless accept-all-suggestions workflow would
have shipped.

## 8. Known limitations

- **Not executed in this environment**: this repo was written in a sandbox
  without Ruby/Rails or the Flutter SDK available (and without network
  access to install them), so `bundle exec rspec` / `flutter test` /
  `bin/rails server` / `flutter run` have not actually been run against
  this code. It's written to standard, idiomatic Rails/Flutter conventions
  and should run with `bundle install` + `flutter pub get`, but please
  treat first-run friction (a missing gem version, a Flutter plugin needing
  its platform folders regenerated via `flutter create .`) as expected and
  quick to fix rather than a sign the design is wrong.
- **Android/iOS platform folders**: only `lib/`, `test/`, `pubspec.yaml`,
  and `assets/` are included for the Flutter app. Run `flutter create .`
  inside `frontend/` once to generate the `android/` and `ios/` platform
  scaffolding before `flutter run`.
- **EPUB reading**: EPUB files can be uploaded, listed, searched,
  downloaded, and deleted, but in-app *reading* is PDF-only. This was a
  deliberate scope cut to keep the reader stable rather than half-working
  on two formats.
- **No authentication**: this is a single-user library with no login,
  matching the assignment's scope. All endpoints are unauthenticated.
- **No last-read-position / zoom controls**: bonus reader features beyond
  basic page navigation were left out to keep the core flows solid.
- **Cover images**: upload supports an optional cover image, but the
  Flutter upload screen doesn't currently expose a cover picker — covers
  fall back to a generated colored "spine" with the title. Wiring a second
  `file_picker` call into the upload form would close this gap.
- **Search** is a simple `LIKE` query (case-insensitive substring match on
  title/author/filename), not full-text search — appropriate for a
  personal library's scale, not for thousands of books.

## 9. Assumptions

- A single user/library (no multi-user accounts) was assumed, in line
  with "the user should be able to..." phrasing throughout the brief
  rather than any mention of accounts or sharing.
- PDF was treated as the required format and EPUB as "accept for
  storage/download, nice-to-have for in-app reading," per the brief's own
  "at minimum, PDF support is expected" note.
- A 100 MB per-file cap was chosen as a reasonable ebook-file ceiling; not
  specified in the brief.
