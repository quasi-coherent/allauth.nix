from celery import Celery
from celery.app import trace

from django.conf import settings

app = Celery("allauth")

# Read configuration from the active Django settings.  This happens lazily, so
# we're OK--by the time a celery worker is created, the django settings have
# been loaded, then updated by the next method.
app.config_from_object("django.conf:settings")


# Apply after configuration is finalized because otherwise it can happen
# sporadically that the Django settings aren't completely loaded by the time
# celery is started.  I don't know why; doesn't happen every time.
@app.on_after_configure.connect
def _apply_extra_conf(sender, **_kwargs):
    sender.conf.update(getattr(settings, "EXTRA_CELERY_CONF", {}))


# Scans all INSTALLED_MODULE locations for a tasks.py with celery tasks and adds
# any that it finds.
app.autodiscover_tasks(lambda: settings.INSTALLED_APPS)

trace.LOG_SUCCESS = "Task %(name)s[%(id)s] succeeded in %(runtime)ss"
