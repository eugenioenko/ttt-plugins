"""Run with python3 tests/smoke.py /path/to/bin/ttt. GitHub writes use a fake gh."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

FAKE_GH = r'''
import json, os, sys
from pathlib import Path
args = sys.argv[1:]
log = Path(os.environ["TTT_REVIEW_LOG"])
scenario = os.environ["TTT_REVIEW_SCENARIO"]
body = json.load(sys.stdin) if "--input" in args else None
method = args[args.index("--method") + 1] if "--method" in args else "GET"
entry = {"args": args, "method": method, "body": body}
with log.open("a") as f: f.write(json.dumps(entry) + "\n")
calls = [json.loads(line) for line in log.read_text().splitlines()]
if args[:2] == ["pr", "list"]:
    result = [{"number": 7, "title": "Fixture change", "author": {"login": "contributor"}, "isDraft": False}]
elif args[:2] == ["pr", "view"]:
    result = {"number": 7, "title": "Fixture change", "author": {"login": "contributor"}, "isDraft": False}
elif args[:2] == ["pr", "diff"]:
    requests = sum(c["args"] == args for c in calls)
    if scenario == "refresh-merge" and requests == 2:
        sys.exit("Diff unavailable")
    updated = scenario == "refresh-merge" and requests > 1
    print("diff --git a/example.go b/example.go\n--- a/example.go\n+++ b/example.go\n@@ -1 +1 @@\n-old\n+" + ("refreshed diff" if updated else "new"))
    sys.exit(0)
elif "--paginate" in args:
    if "/commits/" in args[2]: sys.exit(0)
    kind = "Inline" if "graphql" in args else "Review" if args[2].endswith("/reviews") else "Discussion"
    if scenario == "comments-fail" and kind == "Inline":
        print("Inline comments unavailable", file=sys.stderr); sys.exit(1)
    if kind == "Inline" and scenario != "comments-empty":
        print(json.dumps({"id": "thread", "path": "example.go", "line": 3, "comments": {"nodes": [
            {"author": {"login": "reviewer"}, "body": "Inline fixture message"}]}}))
    elif scenario != "comments-empty":
        print(json.dumps({"id": 1, "user": {"login": "reviewer"}, "created_at": "2026-10-19T10:00:00Z",
                          "body": kind + " fixture message", "path": "example.go" if kind == "Inline" else None, "line": 3}))
    sys.exit(0)
elif method == "POST":
    if scenario == "approval-fails":
        print("Review refused", file=sys.stderr); sys.exit(1)
    result = {"id": 123}
elif method == "PUT":
    if scenario == "merge-refused":
        print(json.dumps({"merged": False, "message": "Head changed"})); sys.exit(0)
    if scenario == "retry-merge" and sum(c["method"] == "PUT" for c in calls) == 1:
        print("CI still running", file=sys.stderr); sys.exit(1)
    result = {"merged": True}
else:
    changed = scenario in ("head-changed", "refresh-merge") and sum(c["args"] == args for c in calls) > 1
    result = {"number": 7, "title": "Updated title" if changed else "Fixture change", "body": "Review fixture", "state": "open",
              "html_url": "https://github.com/example/repo/pull/7", "user": {"login": "contributor"},
              "head": {"sha": ("b" if changed else "a") * 40}}
print(json.dumps(result))
'''


def run_case(binary, scenario, action, merge=False, size="140x40"):
    with tempfile.TemporaryDirectory(prefix="ttt-pr-review-test-") as tmp:
        root = Path(tmp)
        config = root / "config"
        plugin = Path(__file__).resolve().parents[1]
        shutil.copytree(plugin, config / "plugins/pr-review")
        manifest = json.loads((plugin / "plugin.ttt.json").read_text())
        (config / "plugins.ttt.json").write_text(json.dumps([{
            "name": "pr-review", "version": "0.1.0", "enabled": True,
            "grantsVersion": 2, "permissions": manifest["permissions"],
        }]))
        (config / "state.json").write_text(json.dumps({"sidebarWidth": 48}))
        fake_bin = root / "bin"
        fake_bin.mkdir()
        gh = fake_bin / "gh"
        gh.write_text("#!" + sys.executable + "\n" + FAKE_GH)
        gh.chmod(0o755)
        log = root / "calls.jsonl"
        env = dict(os.environ, TTT_CONFIG_DIR=str(config),
                   TTT_REVIEW_SCENARIO=scenario, TTT_REVIEW_LOG=str(log))
        env["PATH"] = str(fake_bin) + os.pathsep + env["PATH"]
        artifacts = Path("/tmp/ttt-pr-review-layout")
        artifacts.mkdir(exist_ok=True)
        direct = scenario in ("direct-pr", "saved-repositories")
        commands = ['exec "PR Review: Show"',
                    'type ' + ("https://github.com/example/repo/pull/7" if direct else "example/repo"), 'key Enter']
        if not direct:
            commands += ['wait-for "#7 Fixture change"', 'screenshot ' + str(artifacts / "sidebar.txt"), 'click 6 12']
        commands += ['wait-for "PR #7: Fixture change"']
        if action == "MERGE":
            if scenario == "refresh-merge":
                commands += ['click 47 6', 'wait-for "Refresh"', 'click 50 11', 'wait-for "Diff unavailable"',
                             'click 47 6', 'wait-for "Refresh"', 'click 50 11',
                             'wait-for "PR #7: Updated title"', 'wait-for "refreshed diff"',
                             'screenshot ' + str(artifacts / 'refreshed.txt')]
            commands += ['wait-for "  0 0 0"', 'screenshot ' + str(artifacts / "actions.txt")]
            if scenario == "squash":
                commands += ['click 42 8']
            else:
                commands += ['click 47 6', 'wait-for "Refresh"', 'click 50 10']
            commands += ['wait-for "Merge example/repo#7?"', 'wait-for "[x] Squash merge"',
                         'screenshot ' + str(artifacts / "merge-dialog.txt")]
            if scenario == "refresh-merge":
                commands += ['key Space', 'wait-for "[ ] Squash merge"']
            if scenario == "merge-cancel":
                commands += ['key Tab', 'key Enter', 'click 47 6', 'wait-for "Save repository"', 'key Escape']
            else:
                commands += ['key Tab', 'key Tab', 'key Enter']
                expected = "Merge failed: Head changed" if scenario == "merge-refused" else "Merged PR #7"
                commands += ['wait-for "' + expected + '"']
            commands += ['quit']
            result = subprocess.run([binary, '--size', size, '--exec', '; '.join(commands)],
                                    cwd=root, env=env, capture_output=True, timeout=25)
            assert result.returncode == 0, result.stderr.decode()
            calls = [json.loads(line) for line in log.read_text().splitlines()]
            if scenario == "refresh-merge":
                screen = (artifacts / 'refreshed.txt').read_text()
                assert "Fixture change" not in screen and screen.count("#7 Updated title") == 2, screen
            writes = [c for c in calls if c["method"] != "GET"]
            if scenario == "merge-cancel":
                assert not writes, writes
            else:
                assert len(writes) == 1 and writes[0]["args"] == [
                    "api", "--method", "PUT", "repos/example/repo/pulls/7/merge", "--input", "-"], writes
                refreshed = scenario == "refresh-merge"
                assert writes[0]["body"] == {"sha": ("b" if refreshed else "a") * 40,
                                             "merge_method": "merge" if refreshed else "squash"}, writes
            print(scenario + ": passed", flush=True)
            return
        if action == "SAVE":
            commands += ['click 47 6', 'wait-for "Save repository"', 'click 50 15',
                         'wait-for "Saved repositories"', 'click 47 6', 'wait-for "Save repository"',
                         'click 50 15', 'wait-for "Repository already saved"', 'quit']
            def run(script):
                try:
                    return subprocess.run([binary, '--size', size, '--exec', '; '.join(script)],
                                          cwd=root, env=env, check=True, timeout=25, capture_output=True)
                except subprocess.CalledProcessError as e:
                    print(e.stderr.decode()); raise
            run(commands)
            store = config / "state/plugins/pr-review.json"
            assert json.loads(store.read_text())["saved_repositories"] == ["https://github.com/example/repo"]
            run(['exec "PR Review: Show"', 'wait-for "Saved repositories"', 'click 6 31', 'wait-for "Open pull requests"',
                 'screenshot ' + str(artifacts / "saved.txt"), 'quit'])
            screen = (artifacts / "saved.txt").read_text().splitlines()
            assert "Saved repositories" in screen[30] and "Load" in screen[4], screen[:15]
            calls = [json.loads(line) for line in log.read_text().splitlines()]
            lists = [c for c in calls if c["args"][:2] == ["pr", "list"]]
            assert len(lists) == 1 and lists[0]["args"][lists[0]["args"].index("--repo") + 1] == "example/repo", calls
            assert all(c["method"] == "GET" for c in calls), calls
            print(scenario + ": passed", flush=True)
            return
        if action == "BROWSE":
            commands += ['click 47 6', 'wait-for "Comments"', 'wait-for "Review"',
                         'key Enter', 'wait-for "Comments · PR #7"']
            expected = {"comments-empty": "No comments yet.", "comments-fail": "Inline comments unavailable"}.get(scenario, "Inline fixture message")
            commands += ['wait-for "' + expected + '"']
            if scenario != "comments-empty":
                commands += ['wait-for "Discussion fixture message"']
                if size != "140x40":
                    width, height = map(int, size.split('x'))
                    commands += ['click ' + str(width - 2) + ' ' + str(height - 3)]
                commands += ['wait-for "Review fixture message"']
            commands += ['screenshot ' + str(artifacts / (scenario + ".txt")), 'quit']
            subprocess.run([binary, '--size', size, '--exec', '; '.join(commands)],
                           cwd=root, env=env, check=True, timeout=25, capture_output=True)
            calls = [json.loads(line) for line in log.read_text().splitlines()]
            assert len([c for c in calls if "--paginate" in c["args"] and "/commits/" not in c["args"][2]]) == 3, calls
            assert all(c["method"] == "GET" for c in calls), calls
            print(scenario + ": passed", flush=True)
            return
        commands += ['click 47 6', 'wait-for "Comments"', 'wait-for "Review"',
                     'key Down', 'key Enter', 'wait-for "Review PR #7"',
                     'type Thank you for the patch', 'key Enter', 'type Second line',
                     'screenshot ' + str(artifacts / "dialog.txt"), 'key Tab']
        if merge:
            commands += ['key Space', 'wait-for "Approve & merge"']
        commands += ['key Tab', 'key Tab']
        if action == "APPROVE":
            commands += ['key Tab']
        commands += ['key Enter']
        expected = {
            "comment": "Commented on PR #7",
            "approve": "Approved PR #7",
            "merge": "Approved and merged PR #7",
            "approval-fails": "Review refused",
            "head-changed": "PR changed or closed",
            "retry-merge": "Retry merge",
        }[scenario]
        commands += ['wait-for "' + expected + '"']
        if scenario == "retry-merge":
            commands += ['key Tab', 'key Tab', 'key Tab', 'key Enter',
                         'wait-for "Approved and merged PR #7"']
        commands += ['quit']
        subprocess.run([binary, '--size', size, '--exec', '; '.join(commands)],
                       cwd=root, env=env, check=True, timeout=25, capture_output=True)
        calls = [json.loads(line) for line in log.read_text().splitlines()]
        posts = [c for c in calls if c["method"] == "POST"]
        puts = [c for c in calls if c["method"] == "PUT"]
        assert len(posts) == (0 if scenario == "head-changed" else 1), calls
        if posts:
            assert posts[0]["body"] == {
                "event": action, "body": "Thank you for the patch\nSecond line", "commit_id": "a" * 40,
            }, posts
        expected_merges = 2 if scenario == "retry-merge" else int(scenario == "merge")
        assert len(puts) == expected_merges, calls
        assert all(c["body"] == {"sha": "a" * 40, "merge_method": "squash"} for c in puts)
        print(scenario + ": passed", flush=True)


if __name__ == "__main__":
    binary = str(Path(sys.argv[1]).resolve())
    for scenario, action, merge in [
        ("squash", "MERGE", False), ("refresh-merge", "MERGE", False),
        ("merge-cancel", "MERGE", False), ("merge-refused", "MERGE", False),
        ("comment", "COMMENT", True), ("approve", "APPROVE", False),
        ("merge", "APPROVE", True), ("approval-fails", "APPROVE", True),
        ("head-changed", "APPROVE", True), ("retry-merge", "APPROVE", True),
        ("comments", "BROWSE", False), ("comments-empty", "BROWSE", False),
        ("comments-fail", "BROWSE", False), ("direct-pr", "BROWSE", False),
        ("saved-repositories", "SAVE", False),
    ]:
        run_case(binary, scenario, action, merge)
