///|
test "empty repository" {
  let actual = @ledger.run(
    "{\"schema_version\":1,\"initial\":{\"repo\":\"demo/shop\",\"revision\":\"sha-a\",\"usages\":[]},\"changes\":[]}",
  )
  assert_eq(actual.1, true)
  assert_true(
    @json.parse(actual.0) ==
    @json.parse(
      "{\"ok\":true,\"report\":{\"schema_version\":1,\"repo\":\"demo/shop\",\"revision\":\"sha-a\",\"totals\":[],\"receipts\":[]}}",
    ),
  )
}

///|
test "initial snapshot" {
  let actual = @ledger.run(
    "{\"schema_version\":1,\"initial\":{\"repo\":\"demo/shop\",\"revision\":\"sha-a\",\"usages\":[{\"file\":\"src/a.tsx\",\"component\":\"@demo/ui/Button\",\"count\":2}]},\"changes\":[]}",
  )
  assert_eq(actual.1, true)
  assert_true(
    @json.parse(actual.0) ==
    @json.parse(
      "{\"ok\":true,\"report\":{\"schema_version\":1,\"repo\":\"demo/shop\",\"revision\":\"sha-a\",\"totals\":[{\"component\":\"@demo/ui/Button\",\"references\":2,\"files\":1}],\"receipts\":[]}}",
    ),
  )
}

///|
test "increase usages" {
  let actual = @ledger.run(
    "{\"schema_version\":1,\"initial\":{\"repo\":\"demo/shop\",\"revision\":\"sha-a\",\"usages\":[{\"file\":\"src/a.tsx\",\"component\":\"@demo/ui/Button\",\"count\":2}]},\"changes\":[{\"id\":\"mr-1:sha-b\",\"repo\":\"demo/shop\",\"base\":\"sha-a\",\"head\":\"sha-b\",\"usages\":[{\"file\":\"src/a.tsx\",\"component\":\"@demo/ui/Button\",\"count\":3}]}]}",
  )
  assert_eq(actual.1, true)
  assert_true(
    @json.parse(actual.0) ==
    @json.parse(
      "{\"ok\":true,\"report\":{\"schema_version\":1,\"repo\":\"demo/shop\",\"revision\":\"sha-b\",\"totals\":[{\"component\":\"@demo/ui/Button\",\"references\":3,\"files\":1}],\"receipts\":[{\"id\":\"mr-1:sha-b\",\"status\":\"applied\",\"base\":\"sha-a\",\"head\":\"sha-b\",\"delta\":[{\"component\":\"@demo/ui/Button\",\"references\":1,\"files\":0}]}]}}",
    ),
  )
}

///|
test "delete last use" {
  let actual = @ledger.run(
    "{\"schema_version\":1,\"initial\":{\"repo\":\"demo/shop\",\"revision\":\"sha-a\",\"usages\":[{\"file\":\"src/a.tsx\",\"component\":\"@demo/ui/Button\",\"count\":2}]},\"changes\":[{\"id\":\"mr-1:sha-b\",\"repo\":\"demo/shop\",\"base\":\"sha-a\",\"head\":\"sha-b\",\"usages\":[]}]}",
  )
  assert_eq(actual.1, true)
  assert_true(
    @json.parse(actual.0) ==
    @json.parse(
      "{\"ok\":true,\"report\":{\"schema_version\":1,\"repo\":\"demo/shop\",\"revision\":\"sha-b\",\"totals\":[],\"receipts\":[{\"id\":\"mr-1:sha-b\",\"status\":\"applied\",\"base\":\"sha-a\",\"head\":\"sha-b\",\"delta\":[{\"component\":\"@demo/ui/Button\",\"references\":-2,\"files\":-1}]}]}}",
    ),
  )
}

///|
test "file rename preserves counts" {
  let actual = @ledger.run(
    "{\"schema_version\":1,\"initial\":{\"repo\":\"demo/shop\",\"revision\":\"sha-a\",\"usages\":[{\"file\":\"src/a.tsx\",\"component\":\"@demo/ui/Button\",\"count\":2}]},\"changes\":[{\"id\":\"mr-1:sha-b\",\"repo\":\"demo/shop\",\"base\":\"sha-a\",\"head\":\"sha-b\",\"usages\":[{\"file\":\"src/moved.tsx\",\"component\":\"@demo/ui/Button\",\"count\":2}]}]}",
  )
  assert_eq(actual.1, true)
  assert_true(
    @json.parse(actual.0) ==
    @json.parse(
      "{\"ok\":true,\"report\":{\"schema_version\":1,\"repo\":\"demo/shop\",\"revision\":\"sha-b\",\"totals\":[{\"component\":\"@demo/ui/Button\",\"references\":2,\"files\":1}],\"receipts\":[{\"id\":\"mr-1:sha-b\",\"status\":\"applied\",\"base\":\"sha-a\",\"head\":\"sha-b\",\"delta\":[]}]}}",
    ),
  )
}

///|
test "split use across files" {
  let actual = @ledger.run(
    "{\"schema_version\":1,\"initial\":{\"repo\":\"demo/shop\",\"revision\":\"sha-a\",\"usages\":[{\"file\":\"src/a.tsx\",\"component\":\"@demo/ui/Button\",\"count\":2}]},\"changes\":[{\"id\":\"mr-1:sha-b\",\"repo\":\"demo/shop\",\"base\":\"sha-a\",\"head\":\"sha-b\",\"usages\":[{\"file\":\"src/a.tsx\",\"component\":\"@demo/ui/Button\",\"count\":1},{\"file\":\"src/b.tsx\",\"component\":\"@demo/ui/Button\",\"count\":1}]}]}",
  )
  assert_eq(actual.1, true)
  assert_true(
    @json.parse(actual.0) ==
    @json.parse(
      "{\"ok\":true,\"report\":{\"schema_version\":1,\"repo\":\"demo/shop\",\"revision\":\"sha-b\",\"totals\":[{\"component\":\"@demo/ui/Button\",\"references\":2,\"files\":2}],\"receipts\":[{\"id\":\"mr-1:sha-b\",\"status\":\"applied\",\"base\":\"sha-a\",\"head\":\"sha-b\",\"delta\":[{\"component\":\"@demo/ui/Button\",\"references\":0,\"files\":1}]}]}}",
    ),
  )
}

///|
test "replace component" {
  let actual = @ledger.run(
    "{\"schema_version\":1,\"initial\":{\"repo\":\"demo/shop\",\"revision\":\"sha-a\",\"usages\":[{\"file\":\"src/a.tsx\",\"component\":\"@demo/ui/Button\",\"count\":2}]},\"changes\":[{\"id\":\"mr-1:sha-b\",\"repo\":\"demo/shop\",\"base\":\"sha-a\",\"head\":\"sha-b\",\"usages\":[{\"file\":\"src/a.tsx\",\"component\":\"@demo/ui/Input\",\"count\":1}]}]}",
  )
  assert_eq(actual.1, true)
  assert_true(
    @json.parse(actual.0) ==
    @json.parse(
      "{\"ok\":true,\"report\":{\"schema_version\":1,\"repo\":\"demo/shop\",\"revision\":\"sha-b\",\"totals\":[{\"component\":\"@demo/ui/Input\",\"references\":1,\"files\":1}],\"receipts\":[{\"id\":\"mr-1:sha-b\",\"status\":\"applied\",\"base\":\"sha-a\",\"head\":\"sha-b\",\"delta\":[{\"component\":\"@demo/ui/Button\",\"references\":-2,\"files\":-1},{\"component\":\"@demo/ui/Input\",\"references\":1,\"files\":1}]}]}}",
    ),
  )
}

///|
test "duplicate event is no op" {
  let actual = @ledger.run(
    "{\"schema_version\":1,\"initial\":{\"repo\":\"demo/shop\",\"revision\":\"sha-a\",\"usages\":[{\"file\":\"src/a.tsx\",\"component\":\"@demo/ui/Button\",\"count\":2}]},\"changes\":[{\"id\":\"mr-1:sha-b\",\"repo\":\"demo/shop\",\"base\":\"sha-a\",\"head\":\"sha-b\",\"usages\":[{\"file\":\"src/a.tsx\",\"component\":\"@demo/ui/Button\",\"count\":3}]},{\"id\":\"mr-1:sha-b\",\"repo\":\"demo/shop\",\"base\":\"sha-a\",\"head\":\"sha-b\",\"usages\":[{\"file\":\"src/a.tsx\",\"component\":\"@demo/ui/Button\",\"count\":3}]}]}",
  )
  assert_eq(actual.1, true)
  assert_true(
    @json.parse(actual.0) ==
    @json.parse(
      "{\"ok\":true,\"report\":{\"schema_version\":1,\"repo\":\"demo/shop\",\"revision\":\"sha-b\",\"totals\":[{\"component\":\"@demo/ui/Button\",\"references\":3,\"files\":1}],\"receipts\":[{\"id\":\"mr-1:sha-b\",\"status\":\"applied\",\"base\":\"sha-a\",\"head\":\"sha-b\",\"delta\":[{\"component\":\"@demo/ui/Button\",\"references\":1,\"files\":0}]},{\"id\":\"mr-1:sha-b\",\"status\":\"duplicate\",\"base\":\"sha-a\",\"head\":\"sha-b\",\"delta\":[]}]}}",
    ),
  )
}

///|
test "late replay stays at latest head" {
  let actual = @ledger.run(
    "{\"schema_version\":1,\"initial\":{\"repo\":\"demo/shop\",\"revision\":\"sha-a\",\"usages\":[{\"file\":\"src/a.tsx\",\"component\":\"@demo/ui/Button\",\"count\":2}]},\"changes\":[{\"id\":\"mr-1:sha-b\",\"repo\":\"demo/shop\",\"base\":\"sha-a\",\"head\":\"sha-b\",\"usages\":[{\"file\":\"src/a.tsx\",\"component\":\"@demo/ui/Button\",\"count\":3}]},{\"id\":\"mr-2:sha-c\",\"repo\":\"demo/shop\",\"base\":\"sha-b\",\"head\":\"sha-c\",\"usages\":[{\"file\":\"src/a.tsx\",\"component\":\"@demo/ui/Button\",\"count\":5}]},{\"id\":\"mr-1:sha-b\",\"repo\":\"demo/shop\",\"base\":\"sha-a\",\"head\":\"sha-b\",\"usages\":[{\"file\":\"src/a.tsx\",\"component\":\"@demo/ui/Button\",\"count\":3}]}]}",
  )
  assert_eq(actual.1, true)
  assert_true(
    @json.parse(actual.0) ==
    @json.parse(
      "{\"ok\":true,\"report\":{\"schema_version\":1,\"repo\":\"demo/shop\",\"revision\":\"sha-c\",\"totals\":[{\"component\":\"@demo/ui/Button\",\"references\":5,\"files\":1}],\"receipts\":[{\"id\":\"mr-1:sha-b\",\"status\":\"applied\",\"base\":\"sha-a\",\"head\":\"sha-b\",\"delta\":[{\"component\":\"@demo/ui/Button\",\"references\":1,\"files\":0}]},{\"id\":\"mr-2:sha-c\",\"status\":\"applied\",\"base\":\"sha-b\",\"head\":\"sha-c\",\"delta\":[{\"component\":\"@demo/ui/Button\",\"references\":2,\"files\":0}]},{\"id\":\"mr-1:sha-b\",\"status\":\"duplicate\",\"base\":\"sha-a\",\"head\":\"sha-b\",\"delta\":[]}]}}",
    ),
  )
}

///|
test "row order does not break deduplication" {
  let actual = @ledger.run(
    "{\"schema_version\":1,\"initial\":{\"repo\":\"demo/shop\",\"revision\":\"sha-a\",\"usages\":[{\"file\":\"src/a.tsx\",\"component\":\"@demo/ui/Button\",\"count\":2}]},\"changes\":[{\"id\":\"mr-1:sha-b\",\"repo\":\"demo/shop\",\"base\":\"sha-a\",\"head\":\"sha-b\",\"usages\":[{\"file\":\"b\",\"component\":\"@demo/ui/Button\",\"count\":2},{\"file\":\"a\",\"component\":\"@demo/ui/Button\",\"count\":2}]},{\"id\":\"mr-1:sha-b\",\"repo\":\"demo/shop\",\"base\":\"sha-a\",\"head\":\"sha-b\",\"usages\":[{\"file\":\"a\",\"component\":\"@demo/ui/Button\",\"count\":2},{\"file\":\"b\",\"component\":\"@demo/ui/Button\",\"count\":2}]}]}",
  )
  assert_eq(actual.1, true)
  assert_true(
    @json.parse(actual.0) ==
    @json.parse(
      "{\"ok\":true,\"report\":{\"schema_version\":1,\"repo\":\"demo/shop\",\"revision\":\"sha-b\",\"totals\":[{\"component\":\"@demo/ui/Button\",\"references\":4,\"files\":2}],\"receipts\":[{\"id\":\"mr-1:sha-b\",\"status\":\"applied\",\"base\":\"sha-a\",\"head\":\"sha-b\",\"delta\":[{\"component\":\"@demo/ui/Button\",\"references\":2,\"files\":1}]},{\"id\":\"mr-1:sha-b\",\"status\":\"duplicate\",\"base\":\"sha-a\",\"head\":\"sha-b\",\"delta\":[]}]}}",
    ),
  )
}

///|
test "totals and deltas are sorted" {
  let actual = @ledger.run(
    "{\"schema_version\":1,\"initial\":{\"repo\":\"demo/shop\",\"revision\":\"sha-a\",\"usages\":[]},\"changes\":[{\"id\":\"mr-1:sha-b\",\"repo\":\"demo/shop\",\"base\":\"sha-a\",\"head\":\"sha-b\",\"usages\":[{\"file\":\"src/a.tsx\",\"component\":\"z\",\"count\":2},{\"file\":\"src/a.tsx\",\"component\":\"a\",\"count\":2}]}]}",
  )
  assert_eq(actual.1, true)
  assert_true(
    @json.parse(actual.0) ==
    @json.parse(
      "{\"ok\":true,\"report\":{\"schema_version\":1,\"repo\":\"demo/shop\",\"revision\":\"sha-b\",\"totals\":[{\"component\":\"a\",\"references\":2,\"files\":1},{\"component\":\"z\",\"references\":2,\"files\":1}],\"receipts\":[{\"id\":\"mr-1:sha-b\",\"status\":\"applied\",\"base\":\"sha-a\",\"head\":\"sha-b\",\"delta\":[{\"component\":\"a\",\"references\":2,\"files\":1},{\"component\":\"z\",\"references\":2,\"files\":1}]}]}}",
    ),
  )
}

///|
test "conflicting retry rejected" {
  let actual = @ledger.run(
    "{\"schema_version\":1,\"initial\":{\"repo\":\"demo/shop\",\"revision\":\"sha-a\",\"usages\":[{\"file\":\"src/a.tsx\",\"component\":\"@demo/ui/Button\",\"count\":2}]},\"changes\":[{\"id\":\"mr-1:sha-b\",\"repo\":\"demo/shop\",\"base\":\"sha-a\",\"head\":\"sha-b\",\"usages\":[{\"file\":\"src/a.tsx\",\"component\":\"@demo/ui/Button\",\"count\":3}]},{\"id\":\"mr-1:sha-b\",\"repo\":\"demo/shop\",\"base\":\"sha-a\",\"head\":\"sha-b\",\"usages\":[{\"file\":\"src/a.tsx\",\"component\":\"@demo/ui/Button\",\"count\":4}]}]}",
  )
  assert_eq(actual.1, false)
  assert_true(
    @json.parse(actual.0) ==
    @json.parse("{\"ok\":false,\"error\":\"event-id-conflict:mr-1:sha-b\"}"),
  )
}

///|
test "stale baseline rejected" {
  let actual = @ledger.run(
    "{\"schema_version\":1,\"initial\":{\"repo\":\"demo/shop\",\"revision\":\"sha-a\",\"usages\":[{\"file\":\"src/a.tsx\",\"component\":\"@demo/ui/Button\",\"count\":2}]},\"changes\":[{\"id\":\"mr-1:sha-b\",\"repo\":\"demo/shop\",\"base\":\"old\",\"head\":\"sha-b\",\"usages\":[{\"file\":\"src/a.tsx\",\"component\":\"@demo/ui/Button\",\"count\":3}]}]}",
  )
  assert_eq(actual.1, false)
  assert_true(
    @json.parse(actual.0) ==
    @json.parse("{\"ok\":false,\"error\":\"stale-base:mr-1:sha-b\"}"),
  )
}

///|
test "cross repo rejected" {
  let actual = @ledger.run(
    "{\"schema_version\":1,\"initial\":{\"repo\":\"demo/shop\",\"revision\":\"sha-a\",\"usages\":[{\"file\":\"src/a.tsx\",\"component\":\"@demo/ui/Button\",\"count\":2}]},\"changes\":[{\"id\":\"mr-1:sha-b\",\"repo\":\"other\",\"base\":\"sha-a\",\"head\":\"sha-b\",\"usages\":[{\"file\":\"src/a.tsx\",\"component\":\"@demo/ui/Button\",\"count\":3}]}]}",
  )
  assert_eq(actual.1, false)
  assert_true(
    @json.parse(actual.0) ==
    @json.parse("{\"ok\":false,\"error\":\"repository-mismatch\"}"),
  )
}

///|
test "same head rejected" {
  let actual = @ledger.run(
    "{\"schema_version\":1,\"initial\":{\"repo\":\"demo/shop\",\"revision\":\"sha-a\",\"usages\":[{\"file\":\"src/a.tsx\",\"component\":\"@demo/ui/Button\",\"count\":2}]},\"changes\":[{\"id\":\"mr-1:sha-b\",\"repo\":\"demo/shop\",\"base\":\"sha-a\",\"head\":\"sha-a\",\"usages\":[{\"file\":\"src/a.tsx\",\"component\":\"@demo/ui/Button\",\"count\":3}]}]}",
  )
  assert_eq(actual.1, false)
  assert_true(
    @json.parse(actual.0) ==
    @json.parse("{\"ok\":false,\"error\":\"reused-head:mr-1:sha-b\"}"),
  )
}

///|
test "old head cannot be reused" {
  let actual = @ledger.run(
    "{\"schema_version\":1,\"initial\":{\"repo\":\"demo/shop\",\"revision\":\"sha-a\",\"usages\":[{\"file\":\"src/a.tsx\",\"component\":\"@demo/ui/Button\",\"count\":2}]},\"changes\":[{\"id\":\"mr-1:sha-b\",\"repo\":\"demo/shop\",\"base\":\"sha-a\",\"head\":\"sha-b\",\"usages\":[{\"file\":\"src/a.tsx\",\"component\":\"@demo/ui/Button\",\"count\":3}]},{\"id\":\"x\",\"repo\":\"demo/shop\",\"base\":\"sha-b\",\"head\":\"sha-a\",\"usages\":[{\"file\":\"src/a.tsx\",\"component\":\"@demo/ui/Button\",\"count\":3}]}]}",
  )
  assert_eq(actual.1, false)
  assert_true(
    @json.parse(actual.0) ==
    @json.parse("{\"ok\":false,\"error\":\"reused-head:x\"}"),
  )
}

///|
test "zero is invalid row count" {
  let actual = @ledger.run(
    "{\"schema_version\":1,\"initial\":{\"repo\":\"demo/shop\",\"revision\":\"sha-a\",\"usages\":[{\"file\":\"src/a.tsx\",\"component\":\"@demo/ui/Button\",\"count\":0}]},\"changes\":[]}",
  )
  assert_eq(actual.1, false)
  assert_true(
    @json.parse(actual.0) ==
    @json.parse("{\"ok\":false,\"error\":\"count-must-be-positive\"}"),
  )
}

///|
test "negative rejected" {
  let actual = @ledger.run(
    "{\"schema_version\":1,\"initial\":{\"repo\":\"demo/shop\",\"revision\":\"sha-a\",\"usages\":[{\"file\":\"src/a.tsx\",\"component\":\"@demo/ui/Button\",\"count\":-1}]},\"changes\":[]}",
  )
  assert_eq(actual.1, false)
  assert_true(
    @json.parse(actual.0) ==
    @json.parse("{\"ok\":false,\"error\":\"count-must-be-positive\"}"),
  )
}

///|
test "row duplicates rejected" {
  let actual = @ledger.run(
    "{\"schema_version\":1,\"initial\":{\"repo\":\"demo/shop\",\"revision\":\"sha-a\",\"usages\":[{\"file\":\"src/a.tsx\",\"component\":\"@demo/ui/Button\",\"count\":2},{\"file\":\"src/a.tsx\",\"component\":\"@demo/ui/Button\",\"count\":2}]},\"changes\":[]}",
  )
  assert_eq(actual.1, false)
  assert_true(
    @json.parse(actual.0) ==
    @json.parse("{\"ok\":false,\"error\":\"duplicate-file-component\"}"),
  )
}

///|
test "empty component rejected" {
  let actual = @ledger.run(
    "{\"schema_version\":1,\"initial\":{\"repo\":\"demo/shop\",\"revision\":\"sha-a\",\"usages\":[{\"file\":\"src/a.tsx\",\"component\":\" \",\"count\":2}]},\"changes\":[]}",
  )
  assert_eq(actual.1, false)
  assert_true(
    @json.parse(actual.0) ==
    @json.parse("{\"ok\":false,\"error\":\"empty:component\"}"),
  )
}

///|
test "empty file rejected" {
  let actual = @ledger.run(
    "{\"schema_version\":1,\"initial\":{\"repo\":\"demo/shop\",\"revision\":\"sha-a\",\"usages\":[{\"file\":\"\",\"component\":\"@demo/ui/Button\",\"count\":2}]},\"changes\":[]}",
  )
  assert_eq(actual.1, false)
  assert_true(
    @json.parse(actual.0) ==
    @json.parse("{\"ok\":false,\"error\":\"empty:file\"}"),
  )
}

///|
test "large row rejected" {
  let actual = @ledger.run(
    "{\"schema_version\":1,\"initial\":{\"repo\":\"demo/shop\",\"revision\":\"sha-a\",\"usages\":[{\"file\":\"src/a.tsx\",\"component\":\"@demo/ui/Button\",\"count\":100000001}]},\"changes\":[]}",
  )
  assert_eq(actual.1, false)
  assert_true(
    @json.parse(actual.0) ==
    @json.parse("{\"ok\":false,\"error\":\"count-limit\"}"),
  )
}

///|
test "integer overflow guarded" {
  let actual = @ledger.run(
    "{\"schema_version\":1,\"initial\":{\"repo\":\"demo/shop\",\"revision\":\"sha-a\",\"usages\":[{\"file\":\"0\",\"component\":\"@demo/ui/Button\",\"count\":100000000},{\"file\":\"1\",\"component\":\"@demo/ui/Button\",\"count\":100000000},{\"file\":\"2\",\"component\":\"@demo/ui/Button\",\"count\":100000000},{\"file\":\"3\",\"component\":\"@demo/ui/Button\",\"count\":100000000},{\"file\":\"4\",\"component\":\"@demo/ui/Button\",\"count\":100000000},{\"file\":\"5\",\"component\":\"@demo/ui/Button\",\"count\":100000000},{\"file\":\"6\",\"component\":\"@demo/ui/Button\",\"count\":100000000},{\"file\":\"7\",\"component\":\"@demo/ui/Button\",\"count\":100000000},{\"file\":\"8\",\"component\":\"@demo/ui/Button\",\"count\":100000000},{\"file\":\"9\",\"component\":\"@demo/ui/Button\",\"count\":100000000},{\"file\":\"10\",\"component\":\"@demo/ui/Button\",\"count\":100000000}]},\"changes\":[]}",
  )
  assert_eq(actual.1, false)
  assert_true(
    @json.parse(actual.0) ==
    @json.parse("{\"ok\":false,\"error\":\"total-limit\"}"),
  )
}

///|
test "unsupported protocol" {
  let actual = @ledger.run(
    "{\"schema_version\":2,\"initial\":{\"repo\":\"demo/shop\",\"revision\":\"sha-a\",\"usages\":[{\"file\":\"src/a.tsx\",\"component\":\"@demo/ui/Button\",\"count\":2}]},\"changes\":[]}",
  )
  assert_eq(actual.1, false)
  assert_true(
    @json.parse(actual.0) ==
    @json.parse("{\"ok\":false,\"error\":\"unsupported-schema-version\"}"),
  )
}

///|
test "empty repo" {
  let actual = @ledger.run(
    "{\"schema_version\":1,\"initial\":{\"repo\":\"\",\"revision\":\"sha-a\",\"usages\":[{\"file\":\"src/a.tsx\",\"component\":\"@demo/ui/Button\",\"count\":2}]},\"changes\":[]}",
  )
  assert_eq(actual.1, false)
  assert_true(
    @json.parse(actual.0) ==
    @json.parse("{\"ok\":false,\"error\":\"empty:repo\"}"),
  )
}

///|
test "empty revision" {
  let actual = @ledger.run(
    "{\"schema_version\":1,\"initial\":{\"repo\":\"demo/shop\",\"revision\":\" \",\"usages\":[{\"file\":\"src/a.tsx\",\"component\":\"@demo/ui/Button\",\"count\":2}]},\"changes\":[]}",
  )
  assert_eq(actual.1, false)
  assert_true(
    @json.parse(actual.0) ==
    @json.parse("{\"ok\":false,\"error\":\"empty:revision\"}"),
  )
}

///|
test "empty event id" {
  let actual = @ledger.run(
    "{\"schema_version\":1,\"initial\":{\"repo\":\"demo/shop\",\"revision\":\"sha-a\",\"usages\":[{\"file\":\"src/a.tsx\",\"component\":\"@demo/ui/Button\",\"count\":2}]},\"changes\":[{\"id\":\"\",\"repo\":\"demo/shop\",\"base\":\"sha-a\",\"head\":\"sha-b\",\"usages\":[{\"file\":\"src/a.tsx\",\"component\":\"@demo/ui/Button\",\"count\":3}]}]}",
  )
  assert_eq(actual.1, false)
  assert_true(
    @json.parse(actual.0) ==
    @json.parse("{\"ok\":false,\"error\":\"empty:id\"}"),
  )
}

///|
test "empty base" {
  let actual = @ledger.run(
    "{\"schema_version\":1,\"initial\":{\"repo\":\"demo/shop\",\"revision\":\"sha-a\",\"usages\":[{\"file\":\"src/a.tsx\",\"component\":\"@demo/ui/Button\",\"count\":2}]},\"changes\":[{\"id\":\"mr-1:sha-b\",\"repo\":\"demo/shop\",\"base\":\"\",\"head\":\"sha-b\",\"usages\":[{\"file\":\"src/a.tsx\",\"component\":\"@demo/ui/Button\",\"count\":3}]}]}",
  )
  assert_eq(actual.1, false)
  assert_true(
    @json.parse(actual.0) ==
    @json.parse("{\"ok\":false,\"error\":\"empty:base\"}"),
  )
}

///|
test "empty head" {
  let actual = @ledger.run(
    "{\"schema_version\":1,\"initial\":{\"repo\":\"demo/shop\",\"revision\":\"sha-a\",\"usages\":[{\"file\":\"src/a.tsx\",\"component\":\"@demo/ui/Button\",\"count\":2}]},\"changes\":[{\"id\":\"mr-1:sha-b\",\"repo\":\"demo/shop\",\"base\":\"sha-a\",\"head\":\"\",\"usages\":[{\"file\":\"src/a.tsx\",\"component\":\"@demo/ui/Button\",\"count\":3}]}]}",
  )
  assert_eq(actual.1, false)
  assert_true(
    @json.parse(actual.0) ==
    @json.parse("{\"ok\":false,\"error\":\"empty:head\"}"),
  )
}

///|
test "malformed shape" {
  let actual = @ledger.run("{}")
  assert_eq(actual.1, false)
  assert_true(
    @json.parse(actual.0) ==
    @json.parse("{\"ok\":false,\"error\":\"invalid-json-or-shape\"}"),
  )
}

///|
test "fractional count" {
  let actual = @ledger.run(
    "{\"schema_version\":1,\"initial\":{\"repo\":\"demo/shop\",\"revision\":\"sha-a\",\"usages\":[{\"file\":\"src/a.tsx\",\"component\":\"@demo/ui/Button\",\"count\":1.5}]},\"changes\":[]}",
  )
  assert_eq(actual.1, false)
  assert_true(
    @json.parse(actual.0) ==
    @json.parse("{\"ok\":false,\"error\":\"invalid-json-or-shape\"}"),
  )
}

///|
test "string count" {
  let actual = @ledger.run(
    "{\"schema_version\":1,\"initial\":{\"repo\":\"demo/shop\",\"revision\":\"sha-a\",\"usages\":[{\"file\":\"src/a.tsx\",\"component\":\"@demo/ui/Button\",\"count\":\"2\"}]},\"changes\":[]}",
  )
  assert_eq(actual.1, false)
  assert_true(
    @json.parse(actual.0) ==
    @json.parse("{\"ok\":false,\"error\":\"invalid-json-or-shape\"}"),
  )
}

///|
test "unicode identifiers" {
  let actual = @ledger.run(
    "{\"schema_version\":1,\"initial\":{\"repo\":\"demo/shop\",\"revision\":\"sha-a\",\"usages\":[{\"file\":\"页面/表单.tsx\",\"component\":\"组件/按钮\",\"count\":3}]},\"changes\":[]}",
  )
  assert_eq(actual.1, true)
  assert_true(
    @json.parse(actual.0) ==
    @json.parse(
      "{\"ok\":true,\"report\":{\"schema_version\":1,\"repo\":\"demo/shop\",\"revision\":\"sha-a\",\"totals\":[{\"component\":\"组件/按钮\",\"references\":3,\"files\":1}],\"receipts\":[]}}",
    ),
  )
}

///|
test "tuple identities do not collide" {
  let actual = @ledger.run(
    "{\"schema_version\":1,\"initial\":{\"repo\":\"demo/shop\",\"revision\":\"sha-a\",\"usages\":[{\"file\":\"a|b\",\"component\":\"c\",\"count\":2},{\"file\":\"a\",\"component\":\"b|c\",\"count\":2}]},\"changes\":[]}",
  )
  assert_eq(actual.1, true)
  assert_true(
    @json.parse(actual.0) ==
    @json.parse(
      "{\"ok\":true,\"report\":{\"schema_version\":1,\"repo\":\"demo/shop\",\"revision\":\"sha-a\",\"totals\":[{\"component\":\"b|c\",\"references\":2,\"files\":1},{\"component\":\"c\",\"references\":2,\"files\":1}],\"receipts\":[]}}",
    ),
  )
}
