from __future__ import annotations
from celery.schedules import BaseSchedule
from datetime import timedelta
from typing import Any
from urllib.parse import urlparse
import os

from .celery import app as celery_app  # noqa: F401


def _apply_runtime_env(ns: dict[str, Any]) -> list[str]:
    exported: list[str] = []

    static_root = os.environ.get("AA_STATIC_ROOT")
    if static_root is not None:
        ns["STATIC_ROOT"] = static_root
        ns["STATICFILES_DIRS"] = []
        exported += ["STATIC_ROOT", "STATICFILES_DIRS"]

    # BASE_DIR is in the nix store, so we can't write log files there, so we
    # have to re-point all loggers.
    log_dir = os.environ.get("AA_LOG_DIR")
    if log_dir is not None:
        for handler in ns.get("LOGGING", {}).get("handlers", {}).values():
            if "filename" in handler:
                handler["filename"] = os.path.join(
                    log_dir, os.path.basename(handler["filename"])
                )

    # The user authenticates as a unix user who has rw on this socket, so there
    # is no password.
    db_name = os.environ.get("AA_DB_NAME")
    if db_name is not None:
        ns.setdefault("DATABASES", {})["default"] = {
            "ENGINE": "django.db.backends.mysql",
            "NAME": db_name,
            "USER": os.environ["AA_DB_USER"],
            "OPTIONS": {
                "unix_socket": os.environ.get(
                    "AA_DB_SOCKET", "/run/mysqld/mysqld.sock"
                ),
                "charset": "utf8mb4",
            },
        }
        exported.append("DATABASES")

    return exported


class _DefaultVars:
    def __init__(self, name: str) -> None:
        self._variables: dict[str, Any] = {
            "DEBUG": os.environ.get("AA_DEBUG", "False") == "True",
            "SITE_NAME": name,
            "SITE_URL": os.environ["AA_SITE_URL"],
            "ROOT_URLCONF": "allauth_lib.urls",
            "WSGI_APPLICATION": "allauth_lib.wsgi.application",
            "ALLOWED_HOSTS": [urlparse(os.environ["AA_SITE_URL"]).hostname],
            "CSRF_TRUSTED_ORIGINS": [os.environ["AA_SITE_URL"]],
            "SECRET_KEY": os.environ["SECRET_KEY"],
            "ESI_SSO_CLIENT_ID": os.environ["ESI_SSO_CLIENT_ID"],
            "ESI_SSO_CLIENT_SECRET": os.environ["ESI_SSO_CLIENT_SECRET"],
            "ESI_USER_CONTACT_EMAIL": os.environ.get("ESI_USER_CONTACT_EMAIL", ""),
        }
        # The Alliance Auth project template sets these defaults.
        # See https://gitlab.com/allianceauth/allianceauth/-/blob/4c67e51469415078cde577e84b8bdffa5cb83616/allianceauth/project_template/project_name/celery.py
        self._celery_conf: dict[str, Any] = {
            "broker_connection_retry_on_startup": True,
            "worker_soft_shutdown_timeout": 300,
            "worker_enable_soft_shutdown_on_idle": True,
            "broker_transport_options": {
                "priority_steps": list(range(10)),
                "queue_order_strategy": "priority",
            },
            "task_default_priority": 5,
            "worker_prefetch_multiplier": 1,
            "worker_eta_task_limit": 100,
            "ONCE": {
                "backend": "allianceauth.services.tasks.DjangoBackend",
                "settings": {},
            },
            "task_routes": {
                "discord.*": {"queue": "services"},
            },
        }


class AllianceAuthApp(_DefaultVars):
    def __init__(self, name: str) -> None:
        super().__init__(name)
        self._installed_apps: list[str] = []
        self._beat_schedule: dict[str, dict[str, Any]] = {}

    def var(self, *, name: str, value: Any) -> AllianceAuthApp:
        """
        Sets a variable to a value.

        Arguments:
            name (str): The Python identifier for the value.  This should be in
                SCREAMING_SNAKE_CASE if the AA Django app is the intended
                consumer, as Django ignores variables named in another format.
            value (Any): The value to assign to this variable.
        """
        self._variables[name] = value
        return self

    def add_plugin(self, *, module: str) -> AllianceAuthApp:
        """Adds a plugin app to install.

        Arguments:
            module (str): The module path to the plugin app, e.g.,
                `"allianceauth.eveonline.autogroups`.
        """
        self._installed_apps.append(module)
        return self

    def add_service(
        self, *, key: str, module: str, schedule: int | float | timedelta | BaseSchedule
    ) -> AllianceAuthApp:
        """
        Adds a service to the AA app.

        Arguments:
            key (str): Unique ID for the schedule entry for the service.
            module (str): The module path to the service.
            schedule: Celery beat schedule for the service.
        """
        self._installed_apps.append(module)
        self._beat_schedule[key] = {"task": module, "schedule": schedule}
        return self

    def celery_conf(self, *, key: str, value: Any) -> AllianceAuthApp:
        """Add a setting in the celery app for AA.

        Arguments:
            key (str): The conf key name.
            value (Any): The value.
        """
        self._celery_conf[key] = value
        return self

    def celery_conf_multi(
        self, *mappings: dict[str, Any], **kwargs: Any
    ) -> AllianceAuthApp:
        """Add multiple settings in the celery app for AA."""
        for m in mappings:
            self._celery_conf.update(m)
        self._celery_conf.update(kwargs)
        return self

    def install(self, namespace: dict[str, Any]) -> None:
        """
        Add this instance's variables to a module namespace's `__all__` tuple.

        This class exists so that a user's settings module may be set
        dynamically and without having to hardcode secrets.  This gets to that
        runtime by being wildcard imported, so this method populates the list of
        variables that appear in such an import.

        Note that this will exclude all other module namespace members from a
        wildcard import.  Use a named import if needed.

        Arguments:
            namespace (dict[str, Any]): A module namespace to "install" this
                instance's variables into.  Intended to be called with the value
                `globals()` at the end of the file where this app is configured.
        """
        ns = namespace
        exported: list[str] = []

        exported += _apply_runtime_env(ns)

        ns["INSTALLED_APPS"] = [*ns.get("INSTALLED_APPS", []), *self._installed_apps]
        exported.append("INSTALLED_APPS")

        ns["EXTRA_CELERY_CONF"] = {
            **ns.get("EXTRA_CELERY_CONF", {}),
            **self._celery_conf,
        }
        exported.append("EXTRA_CELERY_CONF")

        if self._beat_schedule:
            ns["CELERYBEAT_SCHEDULE"] = {
                **ns.get("CELERYBEAT_SCHEDULE", {}),
                **self._beat_schedule,
            }
            exported.append("CELERYBEAT_SCHEDULE")

        for k, v in self._variables.items():
            ns[k] = v
            exported.append(k)

        all_ = list(ns.get("__all__", []))
        seen = set(all_)
        for n in exported:
            if n not in seen:
                all_.append(n)
                seen.add(n)
        # Deduplicated and coerced to a list.
        ns["__all__"] = all_
