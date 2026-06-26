import json
import os
from urllib.parse import urlparse

from celery.schedules import crontab

from .base import *  # noqa: F401,F403

ROOT_URLCONF = "allauth.urls"
WSGI_APPLICATION = "allauth.wsgi.application"

DEBUG = os.environ.get("AA_DEBUG", "False") == "True"

SITE_NAME = os.environ["AA_SITE_NAME"]
SITE_URL = os.environ["AA_SITE_URL"]
ALLOWED_HOSTS = [urlparse(SITE_URL).hostname]
CSRF_TRUSTED_ORIGINS = [SITE_URL]

STATIC_ROOT = os.environ["AA_STATIC_ROOT"]
STATICFILES_DIRS = []

# BASE_DIR points into the read-only venv, so redirect every file log handler to
# a writable directory.
_log_dir = os.environ["AA_LOG_DIR"]
for _handler in LOGGING.get("handlers", {}).values():  # noqa: F405
    if "filename" in _handler:
        _handler["filename"] = os.path.join(
            _log_dir, os.path.basename(_handler["filename"])
        )

# MySQL over the local socket. The service user created in nixos has socket
# auth (no password).
DATABASES["default"] = {  # noqa: F405
    "ENGINE": "django.db.backends.mysql",
    "NAME": os.environ["AA_DB_NAME"],
    "USER": os.environ["AA_DB_USER"],
    "OPTIONS": {
        "unix_socket": os.environ.get("AA_DB_SOCKET", "/run/mysqld/mysqld.sock"),
        "charset": "utf8mb4",
    },
}

# Secrets from the sops EnvironmentFile.
SECRET_KEY = os.environ["SECRET_KEY"]
ESI_SSO_CLIENT_ID = os.environ["ESI_SSO_CLIENT_ID"]
ESI_SSO_CLIENT_SECRET = os.environ["ESI_SSO_CLIENT_SECRET"]
ESI_USER_CONTACT_EMAIL = os.environ.get("ESI_USER_CONTACT_EMAIL", "")

# Apps contributed by enabled Nix features.
INSTALLED_APPS += [  # noqa: F405
    app for app in os.environ.get("AA_EXTRA_INSTALLED_APPS", "").split(",") if app
]


# Periodic tasks contributed by enabled features.
def _cron(expr):
    minute, hour, dom, month, dow = expr.split()
    return crontab(
        minute=minute,
        hour=hour,
        day_of_month=dom,
        month_of_year=month,
        day_of_week=dow,
    )


for _entry in json.loads(os.environ.get("AA_BEAT_JSON", "[]")):
    CELERYBEAT_SCHEDULE[_entry["name"]] = {  # noqa: F405
        "task": _entry["task"],
        "schedule": _cron(_entry["schedule"]),
    }

# Discord feature enabled:
if os.environ.get("DISCORD_ENABLED"):
    DISCORD_GUILD_ID = os.environ["DISCORD_GUILD_ID"]
    DISCORD_APP_ID = os.environ["DISCORD_APP_ID"]
    DISCORD_APP_SECRET = os.environ["DISCORD_APP_SECRET"]
    DISCORD_BOT_TOKEN = os.environ["DISCORD_BOT_TOKEN"]
    DISCORD_CALLBACK_URL = os.environ["DISCORD_CALLBACK_URL"]
    DISCORD_SYNC_NAMES = os.environ.get("DISCORD_SYNC_NAMES", "False") == "True"
