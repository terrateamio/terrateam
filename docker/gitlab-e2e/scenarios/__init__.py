"""Scenario registry.

Importing this package registers every scenario.  Add new modules here so
``run-scenario --all`` picks them up.
"""

from . import (  # noqa: F401
    item02,
    item03,
    item04,
    item05,
    item06,
    item07,
    item13_14,
    phase1,
)

__all__ = [
    "phase1",
    "item02",
    "item03",
    "item04",
    "item05",
    "item06",
    "item07",
    "item13_14",
]
