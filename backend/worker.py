# app/worker.py
from threading import Lock

_jobs: dict[str, dict] = {}
_lock = Lock()

def enqueue_job(job_id: str, initial_state: dict):
    with _lock:
        _jobs[job_id] = initial_state.copy()

def set_job(job_id: str, new_state: dict):
    with _lock:
        if job_id in _jobs:
            _jobs[job_id].update(new_state)
        else:
            _jobs[job_id] = new_state.copy()

def get_job(job_id: str) -> dict:
    with _lock:
        return _jobs.get(job_id, None)
