FROM cr.yandex/mirror/python:3.11-slim
WORKDIR /app
COPY app.py .
RUN useradd -m -u 1001 noroot
USER noroot
EXPOSE 8080
CMD ["python", "app.py"]
