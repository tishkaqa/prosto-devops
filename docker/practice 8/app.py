#!/usr/bin/env python3
import os
import time
import random
import string
from http.server import HTTPServer, BaseHTTPRequestHandler

LOG_LEVEL = os.getenv('LOG_LEVEL', 'DEBUG').upper()

class LoggingHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        # Генерация случайных данных для логов
        request_id = ''.join(random.choices(string.ascii_letters + string.digits, k=32))

        # DEBUG - пиздец сколько логов
        if LOG_LEVEL == 'DEBUG':
            for i in range(100):
                print(f"[DEBUG] Request {request_id} - Processing step {i}")
                print(f"[DEBUG] Random data: {''.join(random.choices(string.ascii_letters, k=500))}")
                print(f"[DEBUG] Memory state: {random.randint(1000000, 9999999)} bytes")

        # INFO - много логов
        elif LOG_LEVEL == 'INFO':
            for i in range(10):
                print(f"[INFO] Request {request_id} - Step {i}")

        # PROD - минимум логов
        elif LOG_LEVEL == 'PROD':
            print(f"[PROD] Request processed: {request_id[:8]}")

        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()

        html = f"""
        <html>
        <body style="font-family: monospace; padding: 20px;">
            <h2>Log Level Test</h2>
            <p>Current LOG_LEVEL: <strong>{LOG_LEVEL}</strong></p>
            <p>Request ID: {request_id[:8]}</p>
            <p>Check container logs to see the difference!</p>
            <hr>
            <ul>
                <li>DEBUG - generates ~100 log lines per request (INSANE!)</li>
                <li>INFO - generates ~10 log lines per request</li>
                <li>PROD - generates 1 log line per request</li>
            </ul>
        </body>
        </html>
        """
        self.wfile.write(html.encode())

    def log_message(self, format, *args):
        # Отключаем стандартные логи HTTP сервера
        pass

if __name__ == '__main__':
    print("=" * 60)
    print(f"Starting app with LOG_LEVEL={LOG_LEVEL}")
    print("WARNING: DEBUG mode generates INSANE amount of logs!")
    print("=" * 60)

    server = HTTPServer(('0.0.0.0', 8080), LoggingHandler)
    server.serve_forever()
