from flask import Flask

app = Flask(__name__)

# Optional: Load environment variables or configs
app.config.from_pyfile('../config.py', silent=True)

# Import routes after the app object is created to avoid circular imports.
from app import routes  # noqa: E402, F401
