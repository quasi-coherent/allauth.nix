import os
import sys

from .defaults import _CELERY_APP, _WSGI_APP


class Runner:
    @property
    def _workdir(self) -> str | None:
        return os.environ.get("AA_PROJECT_DIR")

    @property
    def _worker_concurrency(self) -> str:
        return os.environ.get("AA_WORKER_CONCURRENCY", "5")

    @property
    def _web_workers(self) -> str:
        return os.environ.get("AA_WEB_WORKERS", "3")

    def manage(self, *args: str) -> None:
        """Alias for python manage.py <subcommand>"""
        from django.core.management import execute_from_command_line

        execute_from_command_line(["aa", *args])

    def migrate(self, *args: str) -> None:
        self.manage("migrate", *args)

    def collectstatic(self, *args: str) -> None:
        self.manage("collectstatic", "--no-input", *args)

    def _workdir_args(self) -> list[str]:
        return ["--workdir", self._workdir] if self._workdir else []

    def celery_worker(self, *args: str) -> None:
        self._exec(
            "celery",
            "-A",
            _CELERY_APP,
            "worker",
            "--pool=threads",
            f"--concurrency={self._worker_concurrency}",
            *self._workdir_args(),
            *args,
        )

    def celery_services(self, *args: str) -> None:
        self._exec(
            "celery",
            "-A",
            _CELERY_APP,
            "worker",
            "--pool=threads",
            "--concurrency=1",
            *self._workdir_args(),
            "-Q",
            "services",
            *args,
        )

    def celery_scheduler(self, *args: str) -> None:
        self._exec("celery", "-A", _CELERY_APP, "beat", *args)

    def web(self, *args: str) -> None:
        self._exec(
            "gunicorn",
            _WSGI_APP,
            f"--workers={self._web_workers}",
            "--timeout",
            "120",
            "--no-control-socket",
            *args,
        )

    @staticmethod
    def _exec(program: str, *args: str) -> None:
        os.execvp(program, [program, *args])


_COMMANDS = {
    "manage": "manage",
    "migrate": "migrate",
    "collectstatic": "collectstatic",
    "celery-worker": "celery_worker",
    "celery-services": "celery_services",
    "celery-scheduler": "celery_scheduler",
    "web": "web",
    "gunicorn": "web",
}

_HELP = """\
aa <command> — Alliance Auth runner

  manage ...       Alias for django-admin (python -m django)
  migrate          Apply database migrations
  collectstatic    Collect static assets
  celery-worker    Start celery worker processes
  celery-services  Start a celery worker with backing queue 'services'
  celery-scheduler Start the beat periodic task scheduler
  web              Start the WSGI (gunicorn) application server
"""


def main(argv: list[str] | None = None) -> int:
    argv = sys.argv[1:] if argv is None else argv
    cmd = argv[0] if argv else "help"
    rest = argv[1:]

    method = _COMMANDS.get(cmd)
    if method is None:
        sys.stderr.write(_HELP)
        return 0 if cmd == "help" else 2

    getattr(Runner(), method)(*rest)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
