import abc

from celery.schedules import BaseSchedule
from datetime import timedelta
from typing import Any


class AddOn(abc.ABC):
    """Data to configure additional AA functionality."""

    @property
    @abc.abstractmethod
    def module(self) -> str: ...

    @property
    @abc.abstractmethod
    def vars(self) -> dict[str, Any]: ...

    @vars.setter
    @abc.abstractmethod
    def vars(self, kvs: dict[str, Any]) -> None: ...


class Module(AddOn):
    """App plugin."""

    def __init__(self, *, module: str) -> None:
        self._module = module
        self._vars = dict()

    @property
    def module(self) -> str:
        return self._module

    @property
    def vars(self) -> dict[str, Any]:
        return self._vars

    @vars.setter
    def vars(self, kvs: dict[str, Any]) -> None:
        new_vars = self._vars | kvs
        self._vars = new_vars


class AppPlugin(Module):
    """An app plugin."""

    def __init__(self, module: str) -> None:
        super().__init__(module)
        self._schedule: dict[str, dict[str, Any]] | None = None

    def schedule_task(
        self,
        name: str,
        *,
        task: str,
        schedule: int | float | timedelta | BaseSchedule,
    ) -> None:
        """
        Add a scheduled task for this plugin.

        :name: A name for the task in the celery beat schedule.
        :task: Module path for the task.
        :schedule: The celery beat schedule.
        """
        val = dict(task=task, schedule=schedule)
        if not self._schedule:
            self._schedule = {name: val}
        else:
            self._schedule[name] = val

    @property
    def schedule(self) -> dict[str, dict[str, Any]]:
        return self._schedule or {}

    @schedule.setter
    def schedule(self, schedule: dict[str, dict[str, Any]]) -> None:
        self._schedule = schedule
