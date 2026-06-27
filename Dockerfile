FROM python:3.11-slim

LABEL maintainer="TikhonovAA, senior.tixonoff@gmail.com"
LABEL description="Приложение на питоне"
LABEL version="1.0.0"

RUN useradd -m -u 1001 noroot

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV APP_VERSION=1.0.0
ENV ENVIRONMENT=test
ENV STUDENT_NAME=Andrey

COPY requirements.txt .

RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc && \
    pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt && \
    apt-get purge -y --auto-remove gcc && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY . .

RUN chown -R 1001:1001 /app

USER noroot

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/health')" || exit 1

CMD ["python", "app.py"]
