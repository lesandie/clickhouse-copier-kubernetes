import os
from datetime import datetime
from typing import Dict, List

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel


# Pydantic models
class Job(BaseModel):
    folder: str
    timestamp: datetime
    log_path: str | None = None
    log_error_path: str | None = None


class JobList(BaseModel):
    job_list: Dict[str, Job]


# ENVIRONMENT VARIABLES
# Check that COPIER_LOGS is set in the ENV
BASE_DIR = os.getenv("COPIER_LOGS")

# Functions


def list_dir(basedir: str) -> List[str]:
    """
    Returns a list of all the directories
    """
    listdir = [
        dir_
        for dir_ in os.listdir(basedir)
        if os.path.isdir(os.path.join(basedir, dir_))
        and dir_.find("clickhouse-copier_") != -1
    ]

    return listdir


def list_jobs(basedir: str) -> Dict[str, Job]:
    """
    Returns a dictionary of all the jobs
    """
    try:

        job_list = {}

        for job in list_dir(basedir):
            # if dir list has not a correct dir skip it

            folder = job
            job_string = job.split("_")
            raw_timestamp = job_string[1]
            job_id = job_string[1] + "_" + job_string[2]
            timestamp = datetime.strptime(raw_timestamp, "%Y%m%d%H%M%S")
            log_path = os.path.join(basedir, folder, "log.log")
            log_error_path = os.path.join(basedir, folder, "log.err.log")
            job_value = {
                "folder": folder,
                "timestamp": timestamp,
                "log_path": log_path,
                "log_error_path": log_error_path,
            }
            job_line = {job_id: job_value}
            job_list.update(job_line)

        return job_list

    except FileNotFoundError:
        raise HTTPException(
            status_code=404,
            detail="Does the base directory exist? or is the PVC deployed?",
        )


def cat_logs(filename) -> list[str]:
    """
    cat the logfile
    """
    # check if the file exists
    if check_filepath(filename):
        with open(filename, "r") as f:
            content = f.readlines()
        return content
    else:
        raise HTTPException(
            status_code=404,
            detail="Does the base directory exist? or is the PVC deployed?",
        )


def check_filepath(filepath) -> bool:
    """
    Checks if the input path is correct and a file exists
    """
    if os.path.isfile(filepath):
        return True
    else:
        return False


# FastAPI app
log_reader = FastAPI()


# livenessProbe
@log_reader.get("/")
async def root():
    return {"message": "OK"}


# List job executions
@log_reader.get(
    "/v0/jobs/",
    response_model=JobList,
    response_model_exclude_unset=True
    # response_model_exclude=["log_path", "log_error_path"],
)
async def list_():
    # BaseModel property names must match the keys in the dict returned for pydantic validation
    job_list = list_jobs(BASE_DIR)
    return {"job_list": job_list}


# Get job execution cat log
@log_reader.get("/v0/job/{job_id}/log/")
async def log(job_id):
    try:
        job_list = list_jobs(BASE_DIR)
        log_file = job_list[job_id]["log_path"]
        return {"data": cat_logs(log_file)}
    except KeyError:
        raise HTTPException(
            status_code=404,
            detail="Job ID not found, check the url for the correct job id",
        )


# Get job execution cat error_log
@log_reader.get("/v0/job/{job_id}/error_log/")
async def error_log(job_id):
    try:
        job_list = list_jobs(BASE_DIR)
        log_file = job_list[job_id]['log_error_path']
        return {"data": cat_logs(log_file)}
    except KeyError:
        raise HTTPException(
            status_code=404,
            detail="Job ID not found, check the url for the correct job id",
        )
