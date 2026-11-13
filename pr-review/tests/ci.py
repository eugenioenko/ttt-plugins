"""Real-binary CI tab checks using an isolated config and fake gh."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

FAKE_GH = r'''
import json, os, sys
from pathlib import Path
args = sys.argv[1:]
root = Path(os.environ["CI_FIXTURE"])
scenario = os.environ["CI_SCENARIO"]
with (root / "calls").open("a") as log: log.write(json.dumps(args) + "\n")
if args[:2] == ["pr", "view"]:
    print(json.dumps({"number": 7, "title": "CI fixture", "state": "OPEN"}))
elif args[:2] == ["pr", "diff"]:
    print("diff --git a/a.go b/a.go\n--- a/a.go\n+++ b/a.go\n@@ -1 +1 @@\n-old\n+new")
elif "--paginate" not in args:
    print(json.dumps({"title": "CI fixture", "head": {"sha": "a" * 40}, "user": {"login": "author"},
                      "html_url": "https://github.com/example/repo/pull/7"}))
elif "/check-runs?" in args[2]:
    marker = root / "loaded"
    count = int(marker.read_text()) + 1 if marker.exists() else 1
    marker.write_text(str(count))
    if scenario == "error":
        print("Checks unavailable", file=sys.stderr); sys.exit(1)
    if scenario == "invalid":
        print("invalid JSON"); sys.exit(0)
    if scenario == "empty": sys.exit(0)
    jobs = [("Build", "completed", "success"), ("Lint", "completed", "failure"),
            ("Test", "in_progress", None), ("Deploy", "queued", None),
            ("Docs", "completed", "skipped"), ("Optional", "completed", "neutral"),
            ("Cancelled", "completed", "cancelled"), ("Timeout", "completed", "timed_out"),
            ("Approval", "completed", "action_required")]
    if scenario == "refresh" and count == 2: jobs[0] = ("Ready to refresh", "completed", "success")
    if scenario in ("refresh", "poll") and count > 2: jobs = [("Finished", "completed", "success")]
    for name, status, conclusion in jobs:
        print(json.dumps(dict(name=name, status=status, conclusion=conclusion)))
else:
    if scenario not in ("empty", "error", "invalid"):
        print(json.dumps({"context": "External CI", "state": "success"}))
'''


def run(binary, scenario, sidebar_width=65):
    with tempfile.TemporaryDirectory(prefix="ttt-ci-") as tmp:
        root = Path(tmp)
        config = root / "config"
        config.mkdir()
        (config / "state.json").write_text(json.dumps({"sidebarWidth": sidebar_width}))
        fake = root / "gh"
        fake.write_text("#!" + sys.executable + "\n" + FAKE_GH)
        fake.chmod(0o755)
        env = dict(os.environ, TTT_CONFIG_DIR=str(config), CI_FIXTURE=tmp, CI_SCENARIO=scenario)
        env["PATH"] = tmp + os.pathsep + env["PATH"]
        artifact = Path("/tmp/ttt-pr-ci")
        artifact.mkdir(exist_ok=True)
        screen = artifact / (scenario + ".txt")
        script = ['exec "PR Review: Show"', 'type https://github.com/example/repo/pull/7',
                  'key Enter', 'wait-for "PR #7: CI fixture"']
        summary = {"empty": " 0 0 0", "error": " !", "invalid": " !"}.get(scenario, " 2 2 3 3")
        script += ['wait-for "' + summary + '"', 'screenshot ' + str(artifact / (scenario + '-button.txt')),
                   'exec "PR Review: CI"', 'wait-for "CI · example/repo #7"']
        expected = {"empty": "No CI jobs reported", "error": "Checks unavailable",
                    "invalid": "GitHub returned invalid JSON"}.get(scenario, "External CI")
        script += ['wait-for "' + expected + '"']
        if scenario == "refresh":
            script += ['wait-for "Ready to refresh"', 'key Enter', 'wait-for Finished', 'wait-for " 2 0 0"']
        if scenario == "poll":
            script += ['wait-for Finished timeout=35000', 'wait-for " 2 0 0"']
        script += ['screenshot ' + str(screen), 'quit']
        result = subprocess.run([binary, '--size', '160x40', '--plugin',
                                 str(Path(__file__).resolve().parents[1] / 'init.lua'),
                                 '--exec', '; '.join(script)], cwd=root, env=env, capture_output=True, timeout=45)
        assert result.returncode == 0, result.stderr.decode()
        text = screen.read_text()
        if scenario == "mixed":
            for label in ["Build", "Passed", "Lint", "Failed", "Test", "Running", "Deploy", "Pending", "Docs", "Skipped", "Neutral", "Cancelled", "Timed out", "Action required"]:
                assert label in text, (label, text)
        calls = [json.loads(line) for line in (root / "calls").read_text().splitlines()]
        ci = [args for args in calls if "--paginate" in args]
        assert ci and all("/commits/" + "a" * 40 + "/" in args[2] for args in ci), calls
        assert all("--method" not in args for args in calls), calls
        print(scenario + ": passed")


if __name__ == "__main__":
    for scenario in ["mixed", "empty", "error", "invalid", "refresh", "poll"]:
        run(str(Path(sys.argv[1]).resolve()), scenario)
