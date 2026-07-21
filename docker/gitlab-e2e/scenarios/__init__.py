"""Scenario registry.

Importing this package registers every scenario.  Add new modules here so
``run-scenario --all`` picks them up.
"""

from . import item03, item04, phase1  # noqa: F401

__all__ = ["phase1", "item03", "item04"]
