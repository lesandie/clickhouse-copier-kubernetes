#!/bin/sh
uvicorn --host 0.0.0.0 --port 8000 --workers 2 --reload app.main:logreader
