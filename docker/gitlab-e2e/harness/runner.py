"""Entry point: ``run-scenario <id> [<id> ...]`` or ``run-scenario --all``."""

import argparse
import sys
import time
import traceback

from . import config, fixture as fixture_mod, gitlab, scenario as scenario_mod

# Importing the scenarios package populates the registry.
import scenarios  # noqa: F401,E402  (side-effecting import, must follow the above)


PASS = "PASS"
FAIL = "FAIL"
SKIP = "SKIP"


def _logger(prefix):
    def log(message):
        print("[%s] %s" % (prefix, message), flush=True)

    return log


def run_one(cfg, gl, id_):
    fn = scenario_mod.REGISTRY[id_]
    log = _logger(id_)
    log("=== %s: %s" % (id_, fn.description))
    started = time.time()

    fixture = fixture_mod.Fixture(
        gl, cfg, log, fixture_mod.unique_name(id_.replace(".", "-"))
    )
    ctx = scenario_mod.Ctx(gl, cfg, fixture, log)
    try:
        fn(ctx)
    except scenario_mod.Skipped as exc:
        log("SKIP: %s" % exc)
        return SKIP, str(exc), time.time() - started
    except Exception as exc:  # noqa: BLE001 - the runner reports every failure
        log("FAIL: %s" % exc)
        traceback.print_exc()
        return FAIL, str(exc), time.time() - started
    finally:
        try:
            fixture.destroy()
        except Exception:  # noqa: BLE001
            traceback.print_exc()

    elapsed = time.time() - started
    log("PASS (%.0fs)" % elapsed)
    return PASS, "", elapsed


def main(argv=None):
    parser = argparse.ArgumentParser(prog="run-scenario")
    parser.add_argument("ids", nargs="*", help="scenario ids to run, e.g. 1.1 item03")
    parser.add_argument("--all", action="store_true", help="run every registered scenario")
    parser.add_argument("--list", action="store_true", help="list registered scenarios")
    args = parser.parse_args(argv)

    if args.list:
        for id_ in sorted(scenario_mod.REGISTRY):
            fn = scenario_mod.REGISTRY[id_]
            print("%-10s %s" % (id_, fn.description))
        return 0

    ids = sorted(scenario_mod.REGISTRY) if args.all else args.ids
    if not ids:
        parser.error("give one or more scenario ids, or --all (see --list)")

    unknown = [i for i in ids if i not in scenario_mod.REGISTRY]
    if unknown:
        parser.error("unknown scenario(s): %s" % ", ".join(unknown))

    cfg = config.load()
    gl = gitlab.Gitlab(cfg.gitlab_api_url, cfg.gitlab_token)

    version = gl.version()
    user = gl.current_user()
    print(
        "gitlab %s (enterprise=%s) as %s -> terrateam %s"
        % (
            version.get("version"),
            version.get("enterprise"),
            user.get("username"),
            cfg.terrateam_url,
        ),
        flush=True,
    )

    results = []
    for id_ in ids:
        results.append((id_,) + run_one(cfg, gl, id_))

    print("\n=== summary ===", flush=True)
    for id_, status, message, elapsed in results:
        line = "%-6s %-10s %5.0fs" % (status, id_, elapsed)
        if message:
            line += "  %s" % message
        print(line, flush=True)

    failed = [r for r in results if r[1] == FAIL]
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
