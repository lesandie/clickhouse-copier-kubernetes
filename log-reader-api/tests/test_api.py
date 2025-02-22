import pytest
import ujson
from app.main import list_dir, log_reader
from fastapi.testclient import TestClient

TEST_DIR = "tests/data"
# listdir problems relative paths to fix
BASE_DIR_LIST = ["clickhouse-copier_20220519202024_1"]

client = TestClient(log_reader)


def test_root():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"message": "OK"}


@pytest.fixture
def jobs_response():
    with open(f"{TEST_DIR}/job_response.jsonl", "r") as f:
        return ujson.load(f)


def test_list(jobs_response: dict, mocker):
    mocker.patch("app.main.list_dir", return_value=BASE_DIR_LIST)
    response = client.get("/v0/jobs/")
    print(response.json())
    assert response.status_code == 200
    assert response.json() == jobs_response


@pytest.fixture
def log_response():
    with open(f"{TEST_DIR}/log_response.jsonl", "r") as f:
        return ujson.load(f)


def test_log(log_response: dict, mocker):
    mocker.patch("app.main.list_dir", return_value=BASE_DIR_LIST)
    response = client.get("/v0/job/20220519202024_1/log/")
    assert response.status_code == 200
    assert response.json() == log_response


@pytest.fixture
def error_log_response():
    with open(f"{TEST_DIR}/error_log_response.jsonl", "r") as f:
        return ujson.load(f)


def test_error_log(error_log_response: dict, mocker):
    mocker.patch("app.main.list_dir", return_value=BASE_DIR_LIST)
    response = client.get("/v0/job/20220519202024_1/error_log/")
    assert response.status_code == 200
    assert response.json() == error_log_response
