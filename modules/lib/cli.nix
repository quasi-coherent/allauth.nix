{
  package,
  projectDir,
  projectName,
  writeShellApplication,
}:
writeShellApplication {
  name = "aa";
  runtimeInputs = [ package ];
  text = ''
    AA_PROJECT_DIR="${projectDir}"
    AA_PROJECT_NAME="${projectName}"

    # The project package is shipped in the venv; settings are read from the
    # environment (see allauth/settings/local.py).
    export DJANGO_SETTINGS_MODULE="''${DJANGO_SETTINGS_MODULE:-''${AA_PROJECT_NAME}.settings.local}"

    worker_conc="''${AA_WORKER_CONCURRENCY:-5}"
    web_workers="''${AA_WEB_WORKERS:-3}"

    cmd="''${1:-help}"
    [ "$#" -gt 0 ] && shift || true

    case "$cmd" in
      manage)          exec python -m django "$@" ;;
      migrate)         exec python -m django migrate "$@" ;;
      collectstatic)   exec python -m django collectstatic --no-input "$@" ;;
      celery-worker)   exec celery -A "$AA_PROJECT_NAME" worker \
                          --pool=threads \
                          --concurrency="$worker_conc" \
                          --workdir "$AA_PROJECT_DIR" "$@" ;;
      celery-services)  exec celery -A "$AA_PROJECT_NAME" worker \
                          --pool=threads \
                          --concurrency=1 \
                          --workdir "$AA_PROJECT_DIR" \
                          -Q services "$@" ;;
      celery-scheduler) exec celery -A "$AA_PROJECT_NAME" beat "$@" ;;
      web|gunicorn)     exec gunicorn "''${AA_PROJECT_NAME}.wsgi" \
                          --workers="$web_workers" --timeout 120 \
                          --no-control-socket "$@" ;;
      help|*)
        cat >&2 <<EOF
    aa <command> — Alliance Auth wrapper (project: ''${AA_PROJECT_NAME})

      manage ...       Alias for django-admin (python -m django)
      migrate          Apply database migrations
      collectstatic    Collect static assets
      celery-worker    Start celery worker processes
      celery-services  Start a celery worker with backing queue 'services'
      celery-scheduler Start the beat periodic task scheduler
      web              Start the WSGI application server
    EOF
        [ "$cmd" = help ] && exit 0 || exit 2 ;;
    esac
  '';
}
