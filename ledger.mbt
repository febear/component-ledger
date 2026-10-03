///|
pub(all) struct Usage {
  file : String
  component : String
  count : Int
} derive(Eq, ToJson, @json.FromJson)

///|
pub(all) struct Snapshot {
  repo : String
  revision : String
  usages : Array[Usage]
} derive(Eq, ToJson, @json.FromJson)

///|
pub(all) struct Change {
  id : String
  repo : String
  base : String
  head : String
  usages : Array[Usage]
} derive(Eq, ToJson, @json.FromJson)

///|
pub(all) struct Request {
  schema_version : Int
  initial : Snapshot
  changes : Array[Change]
} derive(ToJson, @json.FromJson)

///|
pub(all) struct Total {
  component : String
  references : Int
  files : Int
} derive(Eq, ToJson)

///|
pub(all) struct Delta {
  component : String
  references : Int
  files : Int
} derive(Eq, ToJson)

///|
pub(all) struct Receipt {
  id : String
  status : String
  base : String
  head : String
  delta : Array[Delta]
} derive(Eq, ToJson)

///|
pub(all) struct Report {
  schema_version : Int
  repo : String
  revision : String
  totals : Array[Total]
  receipts : Array[Receipt]
} derive(Eq, ToJson)

///|
pub suberror LedgerError {
  Invalid(String)
} derive(Eq)

///|
// Use UTF-16 lexical order rather than MoonBit's length-first String order.
fn lexical(a : String, b : String) -> Int {
  let bound = if a.length() < b.length() { a.length() } else { b.length() }
  for i = 0; i < bound; i = i + 1 {
    let order = a[i].compare(b[i])
    if order != 0 {
      return order
    }
  }
  a.length().compare(b.length())
}

///|
// The wire schema uses integers only. Validate before FromJson can truncate.
fn check_numbers(value : Json) -> Unit raise LedgerError {
  match value {
    Number(number, ..) =>
      if number < -2147483648.0 ||
        number > 2147483647.0 ||
        number.to_int().to_double() != number {
        raise Invalid("invalid-json-or-shape")
      }
    Object(fields) =>
      for _, child in fields {
        check_numbers(child)
      }
    Array(items) =>
      for child in items {
        check_numbers(child)
      }
    _ => ()
  }
}

///|
fn nonempty(value : String, name : String) -> Unit raise LedgerError {
  if value.trim().is_empty() {
    raise Invalid("empty:" + name)
  }
}

///|
fn normalize(rows : Array[Usage]) -> Array[Usage] raise LedgerError {
  let result = rows.copy()
  result.sort_by(fn(a, b) {
    let file_order = lexical(a.file, b.file)
    if file_order != 0 {
      file_order
    } else {
      lexical(a.component, b.component)
    }
  })
  for i = 0; i < result.length(); i = i + 1 {
    let row = result[i]
    nonempty(row.file, "file")
    nonempty(row.component, "component")
    if row.count <= 0 {
      raise Invalid("count-must-be-positive")
    }
    if row.count > 100000000 {
      raise Invalid("count-limit")
    }
    if i > 0 &&
      result[i - 1].file == row.file &&
      result[i - 1].component == row.component {
      raise Invalid("duplicate-file-component")
    }
  }
  result
}

///|
fn totals(rows : Array[Usage]) -> Array[Total] raise LedgerError {
  let counts : Map[String, Int] = Map([])
  let files : Map[String, Int] = Map([])
  for row in rows {
    let count = counts.get(row.component).unwrap_or(0)
    // Keep arithmetic safely below the signed 32-bit limit on every backend.
    if count > 1000000000 - row.count {
      raise Invalid("total-limit")
    }
    counts[row.component] = count + row.count
    files[row.component] = files.get(row.component).unwrap_or(0) + 1
  }
  let keys = counts.keys().collect()
  keys.sort_by(lexical)
  keys.map(fn(key) {
    { component: key, references: counts[key], files: files[key], }
  })
}

///|
fn difference(before : Array[Total], after : Array[Total]) -> Array[Delta] {
  let old : Map[String, Total] = Map([])
  let next : Map[String, Total] = Map([])
  let names : Map[String, Bool] = Map([])
  for item in before {
    old[item.component] = item
    names[item.component] = true
  }
  for item in after {
    next[item.component] = item
    names[item.component] = true
  }
  let keys = names.keys().collect()
  keys.sort_by(lexical)
  let result : Array[Delta] = []
  for key in keys {
    let a = old.get(key).unwrap_or({ component: key, references: 0, files: 0, })
    let b = next
      .get(key)
      .unwrap_or({ component: key, references: 0, files: 0, })
    if a.references != b.references || a.files != b.files {
      result.push({
        component: key,
        references: b.references - a.references,
        files: b.files - a.files,
      })
    }
  }
  result
}

///|
/// Replay one repository's full snapshots in explicit base/head order.
/// Nothing is committed externally. Any invalid event rejects the entire request.
pub fn replay(request : Request) -> Report raise LedgerError {
  if request.schema_version != 1 {
    raise Invalid("unsupported-schema-version")
  }
  nonempty(request.initial.repo, "repo")
  nonempty(request.initial.revision, "revision")
  let mut current = totals(normalize(request.initial.usages))
  let mut revision = request.initial.revision
  let seen : Map[String, Change] = Map([])
  let revisions : Map[String, Bool] = Map([(revision, true)])
  let receipts : Array[Receipt] = []
  for raw in request.changes {
    nonempty(raw.id, "id")
    nonempty(raw.base, "base")
    nonempty(raw.head, "head")
    if raw.repo != request.initial.repo {
      raise Invalid("repository-mismatch")
    }
    let change = Change::{ ..raw, usages: normalize(raw.usages), }
    match seen.get(change.id) {
      Some(previous) => {
        if previous != change {
          raise Invalid("event-id-conflict:" + change.id)
        }
        receipts.push({
          id: change.id,
          status: "duplicate",
          base: change.base,
          head: change.head,
          delta: [],
        })
        continue
      }
      None => ()
    }
    if change.base != revision {
      raise Invalid("stale-base:" + change.id)
    }
    if revisions.contains(change.head) {
      raise Invalid("reused-head:" + change.id)
    }
    let updated = totals(change.usages)
    receipts.push({
      id: change.id,
      status: "applied",
      base: change.base,
      head: change.head,
      delta: difference(current, updated),
    })
    current = updated
    revision = change.head
    seen[change.id] = change
    revisions[revision] = true
  }
  {
    schema_version: 1,
    repo: request.initial.repo,
    revision,
    totals: current,
    receipts,
  }
}

///|
/// JSON adapter. The boolean is false for malformed data and invalid transitions.
pub fn run(input : String) -> (String, Bool) {
  try {
    let data = @json.parse(input)
    check_numbers(data)
    let request : Request = @json.from_json(data)
    let report = replay(request)
    (
      ToJson::to_json(
        Map([("ok", true.to_json()), ("report", ToJson::to_json(report))]),
      ).stringify(),
      true,
    )
  } catch {
    Invalid(message) =>
      (
        ToJson::to_json(
          Map([("ok", false.to_json()), ("error", message.to_json())]),
        ).stringify(),
        false,
      )
    _ =>
      (
        ToJson::to_json(
          Map([
            ("ok", false.to_json()),
            ("error", "invalid-json-or-shape".to_json()),
          ]),
        ).stringify(),
        false,
      )
  }
}

///|
pub extend Usage with Eq::{equal, not_equal}

///|
pub extend Usage with ToJson::{to_json}

///|
pub extend Usage with @json.FromJson::{from_json}

///|
pub extend Snapshot with Eq::{equal, not_equal}

///|
pub extend Snapshot with ToJson::{to_json}

///|
pub extend Snapshot with @json.FromJson::{from_json}

///|
pub extend Change with Eq::{equal, not_equal}

///|
pub extend Change with ToJson::{to_json}

///|
pub extend Change with @json.FromJson::{from_json}

///|
pub extend Request with ToJson::{to_json}

///|
pub extend Request with @json.FromJson::{from_json}

///|
pub extend Total with Eq::{equal, not_equal}

///|
pub extend Total with ToJson::{to_json}

///|
pub extend Delta with Eq::{equal, not_equal}

///|
pub extend Delta with ToJson::{to_json}

///|
pub extend Receipt with Eq::{equal, not_equal}

///|
pub extend Receipt with ToJson::{to_json}

///|
pub extend Report with Eq::{equal, not_equal}

///|
pub extend Report with ToJson::{to_json}

///|
pub extend LedgerError with Eq::{equal, not_equal}
