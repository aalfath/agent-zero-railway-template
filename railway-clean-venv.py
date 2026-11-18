#!/usr/bin/env python3
"""Remove files that the upstream image deleted but that are still present at runtime.

Some runtimes (Railway's included, seen 2026-11-18) don't apply the "deleted" markers of later image
layers, so files removed by a later layer reappear. In agent0ai/agent-zero that leaves numpy 2.x files
over numpy 1.26, and memory, knowledge and embeddings then fail with
"All ufuncs must have type numpy.ufunc".

At build time the Dockerfile records every path under /opt/venv-a0 (BuildKit sees the correct tree).
Here we delete paths that are not in that list and are older than the list itself, so files written
at runtime (newer than the list) are never touched. On a runtime that applies layers correctly there
is nothing to delete.
"""
import os, shutil, sys

ROOT = "/opt/venv-a0"
MANIFEST = "/opt/railway-venv-manifest.txt"

def main() -> int:
    try:
        with open(MANIFEST, encoding="utf-8", errors="surrogateescape") as f:
            keep = set(line.rstrip("\n") for line in f)
        cutoff = os.stat(MANIFEST).st_mtime
    except OSError as e:
        print(f"[railway-start] venv check skipped: {e}", file=sys.stderr)
        return 0
    stale = []
    for dirpath, dirnames, filenames in os.walk(ROOT):
        for name in list(dirnames):
            p = os.path.join(dirpath, name)
            if p not in keep:
                try:
                    if os.lstat(p).st_mtime <= cutoff:
                        stale.append(p)
                        dirnames.remove(name)  # whole directory is stale; don't walk into it
                except OSError:
                    pass
        for name in filenames:
            p = os.path.join(dirpath, name)
            if p not in keep:
                try:
                    if os.lstat(p).st_mtime <= cutoff:
                        stale.append(p)
                except OSError:
                    pass
    for p in stale:
        try:
            if os.path.isdir(p) and not os.path.islink(p):
                shutil.rmtree(p)
            else:
                os.unlink(p)
        except OSError as e:
            print(f"[railway-start] could not remove {p}: {e}", file=sys.stderr)
    if stale:
        print(f"[railway-start] removed {len(stale)} leftover paths from {ROOT} that the image had deleted")
    return 0

if __name__ == "__main__":
    sys.exit(main())
