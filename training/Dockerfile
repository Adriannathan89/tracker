FROM python:3.12-slim
WORKDIR /workspace
COPY training/requirements.txt training/requirements.txt
RUN pip install --no-cache-dir -r training/requirements.txt
COPY training/ training/
ENV OPENBLAS_NUM_THREADS=1
ENTRYPOINT ["python", "training/src/train.py"]
