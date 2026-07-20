import os
import sys

from dataclasses import dataclass

from .defaults import _CELERY_APP, _WSGI_APP


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


@dataclass
class Runner:
    workdir: str | None = os.environ.get("AA_PROJECT_DIR")
    worker_concurrency: str | None = os.environ.get("AA_WORKER_CONCURRENCY", "5")
    web_workers: str | None = os.environ.get("AA_WEB_WORKERS", "3")

    @staticmethod
    def _exec(program: str, *args: str) -> None:
        os.execvp(program, [program, *args])

    def _workdir_args(self) -> list[str]:
        return ["--workdir", self.workdir] if self.workdir else []

    @staticmethod
    def manage(*args: str) -> None:
        """Alias for python manage.py <subcommand>"""
        from django.core.management import execute_from_command_line

        execute_from_command_line(["aa", *args])

    @staticmethod
    def migrate(*args: str) -> None:
        Runner.manage("migrate", *args)

    @staticmethod
    def collectstatic(*args: str) -> None:
        Runner.manage("collectstatic", "--no-input", *args)

    @staticmethod
    def celery_scheduler(*args: str) -> None:
        Runner._exec("celery", "-A", _CELERY_APP, "beat", *args)

    def celery_worker(self, *args: str) -> None:
        self._exec(
            "celery",
            "-A",
            _CELERY_APP,
            "worker",
            "--pool=threads",
            f"--concurrency={self.worker_concurrency}",
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

    def web(self, *args: str) -> None:
        self._exec(
            "gunicorn",
            _WSGI_APP,
            f"--workers={self.web_workers}",
            "--timeout",
            "120",
            "--no-control-socket",
            *args,
        )

    def run(self, argv: list[str] | None = None) -> int:
        argv = sys.argv[1:] if argv is None else argv
        cmd = argv[0] if argv else "help"
        rest = argv[1:]

        method = _COMMANDS.get(cmd)
        if method is None:
            sys.stderr.write(_HELP)
            return 0 if cmd == "help" else 2

        getattr(self, method)(*rest)
        return 0


def main() -> int:
    return Runner().run()


if __name__ == "__main__":
    raise SystemExit(main())
