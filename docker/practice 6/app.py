#!/usr/bin/env python3
import os
from http.server import HTTPServer, BaseHTTPRequestHandler

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()

        html = """
        <html>
        <body style="font-family: Arial; text-align: center; padding: 50px;">
            <h1>Dockerfile Optimization Demo</h1>
            <p>If you see this, the app is working!</p>
        </body>
        </html>
        """
        self.wfile.write(html.encode())

    def log_message(self, format, *args):
        pass

if __name__ == '__main__':
    server = HTTPServer(('0.0.0.0', 8080), Handler)
    server.serve_forever()
