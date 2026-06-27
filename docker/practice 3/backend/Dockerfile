FROM python:3.11-slim

WORKDIR /app

ENV APP_NAME="Backend API"
ENV DB_HOST="db"
ENV DB_PORT="5432"

COPY app.py .

RUN chown -R 1001:1001 /app
USER 1001

EXPOSE 5000

CMD ["python", "app.py"]
