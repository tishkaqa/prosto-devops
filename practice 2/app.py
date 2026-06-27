#!/usr/bin/env python3
import os
from http.server import HTTPServer, BaseHTTPRequestHandler

REGISTRY = os.getenv('REGISTRY', 'Unknown')

class SimpleHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()

        html = f"""
        <html>
        <head><title>Task 2</title></head>
        <body style="font-family: Arial; text-align: center; padding: 50px;">
            <h1>Задание 2 выполнено!</h1>
            <h2>Yandex Mirror Registry</h2>
            <p>Registry: <strong>{REGISTRY}</strong></p>
            <p>Базовый образ: <code>cr.yandex/mirror/python:3.11-slim</code></p>
        </body>
        </html>
        """
        self.wfile.write(html.encode())

    def log_message(self, format, *args):
        print(f"{self.address_string()} - {format % args}")

if __name__ == '__main__':
    print(f"Registry: {REGISTRY}")
    print("Starting server on port 8080...")
    server = HTTPServer(('0.0.0.0', 8080), SimpleHandler)
    server.serve_forever()
