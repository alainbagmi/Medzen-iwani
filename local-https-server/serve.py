#!/usr/bin/env python3
"""
Local HTTPS Server for MedZen Flutter Web App
Serves the build/web directory over HTTPS for camera/microphone testing.

Usage:
    python3 serve.py

Access from any device on the network:
    https://10.10.11.138:8443
"""

import http.server
import ssl
import os
import sys

# Configuration
PORT = 8443
WEB_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'build', 'web')
CERT_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'server.crt')
KEY_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'server.key')
LOCAL_SDK_DIR = os.path.dirname(os.path.abspath(__file__))  # For SDK file

class CORSHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    """HTTP handler with CORS headers for local development."""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=WEB_DIR, **kwargs)

    def do_GET(self):
        """Handle GET requests, with special handling for SDK files."""
        # Serve Chime SDK from local-https-server directory
        if self.path == '/amazon-chime-sdk-medzen.min.js':
            sdk_path = os.path.join(LOCAL_SDK_DIR, 'amazon-chime-sdk-medzen.min.js')
            if os.path.exists(sdk_path):
                self.send_response(200)
                self.send_header('Content-Type', 'application/javascript')
                self.end_headers()
                with open(sdk_path, 'rb') as f:
                    self.wfile.write(f.read())
                print(f"📦 Served local Chime SDK")
                return
        # Default handler for all other requests
        super().do_GET()

    def end_headers(self):
        # Add CORS headers for local development
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        # Required for SharedArrayBuffer (used by some WebAssembly features)
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        super().end_headers()

    def do_OPTIONS(self):
        """Handle preflight CORS requests."""
        self.send_response(200)
        self.end_headers()

    def log_message(self, format, *args):
        """Custom logging with emoji indicators."""
        print(f"📡 {self.address_string()} - {format % args}")

def main():
    # Verify paths exist
    if not os.path.exists(WEB_DIR):
        print(f"❌ Error: Web directory not found: {WEB_DIR}")
        print("   Run 'flutter build web --release' first")
        sys.exit(1)

    if not os.path.exists(CERT_FILE) or not os.path.exists(KEY_FILE):
        print(f"❌ Error: SSL certificates not found")
        print(f"   Expected: {CERT_FILE}")
        print(f"   Expected: {KEY_FILE}")
        sys.exit(1)

    # Create SSL context
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.load_cert_chain(CERT_FILE, KEY_FILE)

    # Create and configure server
    server_address = ('0.0.0.0', PORT)
    httpd = http.server.HTTPServer(server_address, CORSHTTPRequestHandler)
    httpd.socket = context.wrap_socket(httpd.socket, server_side=True)

    # Print startup info
    print("=" * 60)
    print("🏥 MedZen Local HTTPS Server")
    print("=" * 60)
    print(f"📁 Serving: {WEB_DIR}")
    print(f"🔒 SSL Certificate: {CERT_FILE}")
    print()
    print("🌐 Access URLs:")
    print(f"   Local:   https://localhost:{PORT}")
    print(f"   Network: https://10.10.11.138:{PORT}")
    print()
    print("⚠️  Browser will show security warning (self-signed cert)")
    print("   Click 'Advanced' → 'Proceed' to continue")
    print()
    print("📋 Press Ctrl+C to stop the server")
    print("=" * 60)

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n🛑 Server stopped")
        httpd.shutdown()

if __name__ == '__main__':
    main()
