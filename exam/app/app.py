import base64
import pickle

from flask import Flask, request, render_template_string

app = Flask(__name__)

LANDING = """<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Acme Status</title>
    <style>
        :root { color-scheme: light dark; }
        body { font-family: system-ui, sans-serif; margin: 0; background: #0f172a; color: #e2e8f0; }
        .wrap { max-width: 640px; margin: 8vh auto; padding: 0 16px; }
        .card { background: #1e293b; border: 1px solid #334155; border-radius: 12px; padding: 32px; }
        h1 { margin: 0 0 4px; }
        .sub { color: #94a3b8; margin: 0 0 24px; }
        .ok { color: #4ade80; font-weight: 600; }
        code { background: #0f172a; padding: 2px 6px; border-radius: 6px; }
    </style>
</head>
<body>
    <div class="wrap">
        <div class="card">
            <h1>Acme Status</h1>
            <p class="sub">Internal service health dashboard</p>
            <p>API: <span class="ok">operational</span></p>
            <p>Workers: <span class="ok">operational</span></p>
            <p>Database: <span class="ok">operational</span></p>
            <!-- TODO before launch: the /greet endpoint still renders the
                 visitor's name straight through the template engine. Remove
                 or sanitize it. e.g. /greet?name=YourName -->
            <!-- Also pending: /api/prefs restores the user's saved settings
                 from a base64 pickled 'prefs' value. Migrate off pickle. -->
        </div>
    </div>
</body>
</html>"""


@app.route("/")
def index():
    return LANDING


@app.route("/greet")
def greet():
    name = request.args.get("name", "guest")
    # VULNERABLE BY DESIGN (entry #1): user input is concatenated into the template
    # source and handed to Jinja2, which evaluates {{ ... }} expressions in it.
    # Server-Side Template Injection -> RCE as the 'app' user. e.g.:
    #   /greet?name={{7*7}}
    #   /greet?name={{cycler.__init__.__globals__.os.popen('id').read()}}
    tpl = "<h1>Hello, " + name + "!</h1>"
    return render_template_string(tpl)


@app.route("/api/prefs")
def prefs():
    raw = request.args.get("prefs") or request.cookies.get("prefs")
    if not raw:
        # Show the expected format so the endpoint is discoverable.
        sample = base64.b64encode(pickle.dumps({"theme": "dark"})).decode()
        return ("No prefs provided. Send ?prefs=<base64> or a 'prefs' cookie.\n"
                "Example value: " + sample + "\n")
    # VULNERABLE BY DESIGN (entry #2): untrusted input is base64-decoded and passed
    # to pickle.loads, which executes the object's __reduce__ on deserialization.
    # Insecure deserialization -> RCE as the 'app' user.
    data = pickle.loads(base64.b64decode(raw))
    return "Preferences loaded: " + repr(data) + "\n"


if __name__ == "__main__":
    # debug=False on purpose: the SSTI / pickle RCE are the intended paths,
    # not the Werkzeug console.
    app.run(host="0.0.0.0", port=5000)
