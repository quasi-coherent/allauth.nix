import os

from urllib.parse import urlparse
from typing import Any

_CELERY_APP = "allauth"
_WSGI_APP = "allauth.wsgi"


def _var_defaults(site_name: str, site_url: str) -> dict[str, Any]:
    return {
        "DEBUG": os.environ.get("AA_DEBUG", "False") == "True",
        "SITE_URL": site_url,
        "ROOT_URLCONF": "allauth.urls",
        "WSGI_APPLICATION": "allauth.wsgi.application",
        "ALLOWED_HOSTS": [urlparse(site_url).hostname],
        "CSRF_TRUSTED_ORIGINS": [site_url],
        "SECRET_KEY": os.environ["SECRET_KEY"],
        "ESI_SSO_CLIENT_ID": os.environ["ESI_SSO_CLIENT_ID"],
        "ESI_SSO_CLIENT_SECRET": os.environ["ESI_SSO_CLIENT_SECRET"],
        "ESI_USER_CONTACT_EMAIL": os.environ.get("ESI_USER_CONTACT_EMAIL", ""),
    }


_CELERY_CONF_DEFAULTS = {
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
