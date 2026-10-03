"""Exercise the real compiled CLI against fixtures and independent invariants."""
import collections
import json
import pathlib
import random
import subprocess

ROOT = pathlib.Path(__file__).resolve().parents[1]
CLI = ROOT / "_build/js/debug/build/cmd/main/main.js"


def invoke(data):
    proc = subprocess.run(
        ["node", str(CLI)], input=json.dumps(data), text=True,
        capture_output=True, check=False, timeout=10,
    )
    result = json.loads(proc.stdout)
    assert proc.returncode == (0 if result["ok"] else 2), proc.stderr
    return result


cases = json.loads((ROOT / "tests/cases.json").read_text())
for case in cases:
    assert invoke(case["input"]) == case["expected"], case["name"]

# Independent oracle: sum the final complete snapshot, then verify that all
# reported deltas telescope to that same result, despite randomly placed retries.
rng = random.Random(20261003)
for iteration in range(40):
    initial = {"repo": "fixture", "revision": "r0", "usages": []}
    events = []
    final = []
    for step in range(1, 9):
        final = [
            {"file": f"src/f{f}.tsx", "component": f"ui/C{c}", "count": rng.randint(1, 8)}
            for f in range(6) for c in range(4) if rng.random() < .3
        ]
        events.append({"id": str(step), "repo": "fixture", "base": f"r{step-1}",
                       "head": f"r{step}", "usages": final})
        if rng.random() < .8:
            retry = dict(rng.choice(events))
            retry["usages"] = list(reversed(retry["usages"]))
            events.append(retry)
    result = invoke({"schema_version": 1, "initial": initial, "changes": events})
    assert result["ok"]
    report = result["report"]
    assert report["revision"] == "r8"
    expected_refs = collections.Counter()
    expected_files = collections.Counter()
    for row in final:
        expected_refs[row["component"]] += row["count"]
        expected_files[row["component"]] += 1
    expected = [{"component": c, "references": expected_refs[c], "files": expected_files[c]}
                for c in sorted(expected_refs)]
    assert report["totals"] == expected
    refs, files = collections.Counter(), collections.Counter()
    for receipt in report["receipts"]:
        if receipt["status"] == "duplicate":
            assert receipt["delta"] == []
        for delta in receipt["delta"]:
            refs[delta["component"]] += delta["references"]
            files[delta["component"]] += delta["files"]
    assert +refs == expected_refs and +files == expected_files
    assert all(v >= 0 for v in refs.values()) and all(v >= 0 for v in files.values())

malformed = subprocess.run(["node", str(CLI)], input="{", text=True, capture_output=True)
assert malformed.returncode == 2 and not json.loads(malformed.stdout)["ok"]
print(f"CLI: {len(cases)} specified cases + 40 seeded history invariants + malformed JSON passed")
