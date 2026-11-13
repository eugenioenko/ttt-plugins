"""Real-binary Timeline checks with an isolated config and fake GitHub responses."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

from ci import FAKE_GH as BASE_GH

TIMELINE_GH = r'''
elif "/pulls/7/commits?" in " ".join(args):
    assert "--paginate" in args and args[-2:] == ["--jq", ".[] | @json"]
    marker = root / "timeline-loads"
    count = int(marker.read_text()) + 1 if marker.exists() else 1
    marker.write_text(str(count))
    if scenario == "timeline-error" or (scenario == "timeline-retry" and count == 2):
        print("Commits unavailable from GitHub", file=sys.stderr); sys.exit(1)
    if scenario == "timeline-invalid":
        print('{"sha":true}'); sys.exit(0)
    if scenario == "timeline-empty": sys.exit(0)
    commits = [
        {"sha": "a" * 40, "author": None, "committer": None,
         "commit": {"message": "Initial work\n\nLonger description", "author": {"name": "José", "date": "2026-11-11T10:00:00Z"},
                    "committer": {"name": "José", "date": "2026-11-11T10:00:00Z"}}},
        {"sha": "b" * 40, "author": {"login": "alice"}, "committer": {"login": "merger"},
         "commit": {"message": "Latest fix", "author": {"name": "Alice", "date": "2026-11-12T11:00:00Z"},
                    "committer": {"name": "Merger", "date": "2026-11-12T13:00:00Z"}}},
    ]
    if scenario in ("timeline-refresh", "timeline-retry") and count >= (3 if scenario == "timeline-retry" else 2):
        commits.append({"sha": "c" * 40, "commit": {"message": "New commit"}})
    for commit in commits: print(json.dumps(commit))
'''
FAKE_GH = BASE_GH.replace('elif "--paginate" not in args:', TIMELINE_GH + '\nelif "--paginate" not in args:')


def run(binary, scenario, plugin=None):
    with tempfile.TemporaryDirectory(prefix="ttt-timeline-") as tmp:
        root = Path(tmp)
        config = root / "config"
        config.mkdir()
        (config / "state.json").write_text(json.dumps({"sidebarWidth": 65}))
        fake = root / "gh"
        fake.write_text("#!" + sys.executable + "\n" + FAKE_GH)
        fake.chmod(0o755)
        env = dict(os.environ, TTT_CONFIG_DIR=str(config), CI_FIXTURE=tmp, CI_SCENARIO=scenario)
        env["PATH"] = tmp + os.pathsep + env["PATH"]
        artifacts = Path("/tmp/ttt-pr-timeline")
        artifacts.mkdir(exist_ok=True)
        screen = artifacts / (scenario + ".txt")
        commands = ['exec "PR Review: Show"', 'type https://github.com/example/repo/pull/7',
                    'key Enter', 'wait-for "PR #7: CI fixture"', 'exec "PR Review: Timeline"']
        expected = {"timeline-error": "Commits unavailable from GitHub", "timeline-invalid": "GitHub returned an invalid commit",
                    "timeline-empty": "No commits in this pull request."}.get(scenario, "Latest fix")
        commands += ['wait-for "' + expected + '"']
        if scenario == "timeline-populated":
            commands += ['wait-for "Committer: @merger"', 'screenshot ' + str(artifacts / 'newest.txt'),
                         'key Tab', 'key Down', 'wait-for "' + 'a' * 40 + '"', 'wait-for "Author: José"']
        if scenario == "timeline-retry":
            commands += ['key Enter', 'wait-for "Showing previously loaded commits."', 'wait-for "Latest fix"']
        if scenario in ("timeline-refresh", "timeline-retry"):
            commands += ['key Enter', 'wait-for "New commit"', 'wait-for "3 commits"',
                         'wait-for "' + 'b' * 40 + '"']
        commands += ['screenshot ' + str(screen), 'quit']
        result = subprocess.run([binary, '--size', '170x40', '--plugin', str(plugin or Path(__file__).resolve().parents[1] / 'init.lua'),
                                 '--exec', '; '.join(commands)], cwd=root, env=env, capture_output=True, timeout=25)
        assert result.returncode == 0, result.stderr.decode()
        text = screen.read_text()
        assert 'coming soon' not in text
        if scenario == "timeline-populated":
            newest = (artifacts / 'newest.txt').read_text()
            assert newest.index('Latest fix') < newest.index('Initial work'), newest
            for expected in ['bbbbbbbb', '@alice', '2026-11-12 13:00:00 UTC', 'Committer: @merger', 'b' * 40]:
                assert expected in newest, (expected, newest)
            assert 'Author: José' in text and 'a' * 40 in text
        calls = [json.loads(line) for line in (root / 'calls').read_text().splitlines()]
        timeline = [args for args in calls if '/pulls/7/commits?' in ' '.join(args)]
        assert len(timeline) == (3 if scenario == 'timeline-retry' else 2 if scenario == 'timeline-refresh' else 1), calls
        assert all('--method' not in args for args in calls), calls
        print(scenario + ': passed', flush=True)


if __name__ == '__main__':
    for scenario in ['timeline-populated', 'timeline-empty', 'timeline-error', 'timeline-invalid', 'timeline-refresh', 'timeline-retry']:
        run(str(Path(sys.argv[1]).resolve()), scenario)
