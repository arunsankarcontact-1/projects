from flask import Flask, jsonify
import os

app = Flask(__name__)
color = os.environ.get("COLOR", "blue")
version = os.environ.get("VERSION", "1.0.0")

@app.route("/health")
def health():
    return jsonify({"color": color, "version": version})

@app.route("/version")
def version_endpoint():
    return jsonify({"color": color, "version": version})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
