# Complete Beginner Setup Guide — GeoPulse Member 1 (Snowflake)

This assumes you've never used Snowflake, a terminal, Python, Airflow, or Git
before. Follow it top to bottom, in order. Don't skip ahead.

---

## PART 1: Create your free Snowflake account

1. Open your browser and go to **https://signup.snowflake.com/**
2. Fill in the form:
   - Email, name, company (write "Student Project" or your college name)
   - Click **Continue**
3. On the next screen it asks you to choose a **Cloud Provider** and **Region**.
   - Pick **AWS**
   - Pick a region close to India — e.g. **Asia Pacific (Mumbai)**
   - Leave the edition as **Standard**
   - Click **Get Started**
4. Check your email — Snowflake sends a verification link. Click it.
5. It will ask you to set a **username** and **password**. Write these down
   somewhere safe (a notes app) — you'll need them constantly.
6. After verifying, you'll land on the Snowflake home page, called
   **Snowsight**. This is the web app where you'll do most of your SQL work.
   The URL in your browser's address bar will look something like:
   `https://app.snowflake.com/ap-southeast-1/abxy123/...`
   — that middle part (`abxy123`) is your **account locator**. Copy it
   somewhere; you'll need it later for the command-line tool and Airflow.

**How to find your account locator/URL again later:** log into
snowflake.com → Snowsight → click your username bottom-left → "Account" →
it shows your account details there too.

---

## PART 2: Run your first SQL script in Snowsight

1. Inside Snowsight (the web app from Part 1), look at the left sidebar.
   Click **Worksheets**.
2. Click the blue **+ Worksheet** button (usually top-right) to open a
   blank SQL editor.
3. Open the file `sql/day01_setup_account.sql` from the project I gave you
   (open it in Notepad / VS Code / any text editor — it's just plain text).
4. **Select all the text in that file (Ctrl+A) and copy it (Ctrl+C).**
5. Go back to your blank Snowsight worksheet and paste it in (Ctrl+V).
6. To run it: you can run one line at a time, or the whole thing.
   - To run **one statement**: click anywhere inside that SQL statement
     (between two semicolons `;`), then press **Ctrl+Enter** (or the ▶ Run
     button top-right).
   - To run **everything**: select all the text (Ctrl+A) then Ctrl+Enter —
     Snowsight will run each statement one after another.
7. Watch the bottom panel — it shows results/errors for each statement as
   it runs. If a line goes red/shows an error, stop and re-read it —
   usually it means something above it didn't finish (e.g. you weren't
   using the right role yet).
8. **Important:** one line near the bottom of that file is commented out
   (it starts with `--`, meaning "don't run this"):
   ```
   -- GRANT ROLE GEOPULSE_DEV TO USER <your_username>;
   ```
   You need to un-comment this and put in your actual username. So:
   - Delete the `--` at the start of that line
   - Replace `<your_username>` with the username you created in Part 1
     (no quotes needed, just type it plain, e.g.
     `GRANT ROLE GEOPULSE_DEV TO USER TANU123;`)
   - Run that one line by itself (click on it, Ctrl+Enter)
9. Repeat this whole process (copy → paste → run) for
   `sql/day02_geography_tables.sql`.

**How you'll know it worked:** run this at the bottom of any worksheet:
```sql
SELECT CURRENT_WAREHOUSE(), CURRENT_DATABASE(), CURRENT_SCHEMA(), CURRENT_ROLE();
```
It should return one row showing `GEOPULSE_WH`, `GEOPULSE_DB`, etc. instead
of blank/NULL values.

---

## PART 3: Install tools on your laptop (Python, terminal basics)

You need a **terminal** (also called command line/command prompt) to run
Python scripts. Here's how to open one:

- **Windows:** Press the Windows key, type `cmd`, press Enter. (Or install
  "Git Bash" later in Part 6 — a nicer terminal.)
- **Mac:** Press Cmd+Space, type `Terminal`, press Enter.

### 3.1 Check if Python is installed
Type this and press Enter:
```
python3 --version
```
(On Windows, try `python --version` if `python3` doesn't work.)

- If it prints something like `Python 3.11.4` → you're good, skip to 3.2.
- If it says "command not found" → go to **https://www.python.org/downloads/**,
  download the installer for your OS, run it. **On Windows, tick the box
  that says "Add Python to PATH"** during install — this is important,
  don't skip it. Restart your terminal after installing and check the
  version again.

### 3.2 Navigate to your project folder in the terminal
First, unzip the project file I gave you (double-click the .zip, or
right-click → Extract All). Note down the folder path, e.g.
`C:\Users\Tanu\Downloads\member1-snowflake-lakehouse` or
`/Users/tanu/Downloads/member1-snowflake-lakehouse`.

In your terminal, type `cd ` (with a space after it) then paste that
folder path, then press Enter. Example:
```
cd C:\Users\Tanu\Downloads\member1-snowflake-lakehouse
```
Type `dir` (Windows) or `ls` (Mac) and press Enter — you should see the
folders `sql`, `python`, `airflow`, `docs`, `setup` listed. If you see
them, you're in the right place.

### 3.3 Create a virtual environment (a clean, isolated Python setup)
This just keeps this project's Python packages separate from everything
else on your laptop. Type these one at a time, pressing Enter after each:
```
python3 -m venv venv
```
This creates a folder called `venv`. Now **activate** it:
- Windows (cmd): `venv\Scripts\activate`
- Mac/Linux: `source venv/bin/activate`

After running that, your terminal prompt should now show `(venv)` at the
start of the line — that means it worked and is now "active." You need to
do this activation step **every time you open a new terminal window** for
this project (but you only create the venv once).

### 3.4 Install the Python packages
With `(venv)` showing, type:
```
pip install snowflake-connector-python pandas pyspark apache-airflow apache-airflow-providers-snowflake
```
This will take a few minutes and print a lot of text — that's normal.
Wait until it finishes and gives you your prompt back.

---

## PART 4: Install SnowSQL (needed to upload files to Snowflake)

Snowsight (the web UI) can't upload files from your laptop — for that you
need a separate small program called SnowSQL.

1. Go to **https://docs.snowflake.com/en/user-guide/snowsql-install-config**

2. Download the installer matching your OS (Windows/Mac/Linux) — there's a
   table of links on that page.
3. Run the installer like any normal program (double-click, click Next/Install).
4. Open a **new** terminal window and type:
   ```
   snowsql -v
   ```
   If it prints a version number, it installed correctly.
5. Log in to test it (replace the placeholders with your real values from
   Part 1):
   ```
   snowsql -a <account_locator> -u <your_username>
   ```
   It will ask for your password — type it (it won't show characters as
   you type, that's normal for password prompts) and press Enter.
   You should land on a prompt that looks like:
   ```
   TANU123#(no warehouse)@(no database).(no schema)>
   ```
   That means you're connected. Type `!quit` and Enter to exit for now.

---

## PART 5: Generate the mock data and load it into Snowflake

### 5.1 Generate the CSV files
Back in your regular terminal (with `(venv)` active, from Part 3), navigate
into the python folder:
```
cd python
```
Then run:
```
python generate_mock_stores.py --out stores.csv --n 5000 --city bengaluru
```
This creates a file called `stores.csv` right there in the `python` folder.
Then run:
```
python generate_catchment_polygons.py --stores stores.csv --out catchments.csv --radius_m 500
```
This creates `catchments.csv` in the same folder.

Check they exist: type `dir` (Windows) or `ls` (Mac) — you should see both
`.csv` files listed now.

### 5.2 Upload the files to Snowflake using SnowSQL
Still in the `python` folder in your terminal, log back into SnowSQL:
```
snowsql -a <account_locator> -u <your_username>
```
Once connected (you see the `TANU123#...>` prompt), type these one at a
time:
```sql
PUT file://stores.csv @GEOPULSE_DB.RAW.store_stage AUTO_COMPRESS=TRUE;
PUT file://catchments.csv @GEOPULSE_DB.STAGING.catchment_stage AUTO_COMPRESS=TRUE;
```
(On Windows, if `file://stores.csv` gives a path error, try the full path
instead, e.g. `file://C:\Users\Tanu\...\python\stores.csv`.)

Each PUT command should print a table showing the file was uploaded
(status: UPLOADED). Then type `!quit` to exit.

### 5.3 Load the uploaded files into actual tables
Go back to **Snowsight in your browser** (Part 2's tool). Open a new
worksheet, paste in the contents of `sql/day03_load_and_validate_stores.sql`,
and run it the same way as before (select all, Ctrl+Enter).

Then do the same with `sql/day08_09_load_catchments_and_tune.sql`.

These scripts will show you validation query results at the end — read
the comments in the file (`-- Any row with invalid_geo > 0...`) to know
what a "good" result looks like (usually: an empty result = success).

---

## PART 6: Set up Airflow locally (for the daily pipeline, Days 16-19)

This part is the most involved — take it slowly.

1. Make sure `(venv)` is active in your terminal (Part 3.3), and you're
   back in the main project folder (`cd ..` if you're still in `python/`).
2. Set an environment variable telling Airflow where to store its files:
   - Mac/Linux: `export AIRFLOW_HOME=~/airflow`
   - Windows (cmd): `set AIRFLOW_HOME=%USERPROFILE%\airflow`
3. Initialize Airflow's internal database (one-time setup):
   ```
   airflow db init
   ```
4. Create yourself an admin login for the Airflow web dashboard:
   ```
   airflow users create --username admin --firstname Tanu --lastname Bedia --role Admin --email you@example.com --password admin
   ```
5. Copy the DAG file into Airflow's dags folder:
   - Mac/Linux: `cp airflow/dags/geopulse_snowflake_dag.py ~/airflow/dags/`
   - Windows: `copy airflow\dags\geopulse_snowflake_dag.py %USERPROFILE%\airflow\dags\`
6. Tell Airflow how to connect to Snowflake. Easiest way: use the web UI
   (next step) rather than the command line.
7. Open **two** terminal windows (both with `(venv)` active and
   `AIRFLOW_HOME` set — repeat step 2 in the second window):
   - In terminal 1: `airflow webserver -p 8080`
   - In terminal 2: `airflow scheduler`
   Leave both running (don't close these windows).
8. Open your browser to **http://localhost:8080** — log in with
   `admin` / `admin` (from step 4).
9. In the top menu, click **Admin → Connections → the blue "+" button**
   to add a new connection. Fill in:
   - Connection Id: `geopulse_snowflake`
   - Connection Type: `Snowflake`
   - Login: your Snowflake username
   - Password: your Snowflake password
   - Schema: `RAW`
   - Extra (paste this, filling in your account locator):
     ```json
     {"account":"<account_locator>","warehouse":"GEOPULSE_WH","database":"GEOPULSE_DB","role":"GEOPULSE_DEV"}
     ```
   - Click **Save**.
10. Back on the main Airflow screen (click "DAGs" in the top menu), find
    `geopulse_snowflake_daily_load` in the list. Flip the toggle on the
    left of it to **On/blue**. Click the ▶ (play) button on the right side
    of that row to manually trigger it once and test it works, rather than
    waiting for the daily schedule.
11. Click into the DAG name, then click a task box, then "Logs" to see
    what happened — this is how you debug if something fails.

---

## PART 7: Git — save and submit your work

Git tracks changes to your files and lets you upload them to GitHub so
your teammates (and instructor) can see your work.

### 7.1 Install Git
- **Windows:** download and install **Git Bash** from
  **https://git-scm.com/downloads** — just click Next through the installer
  with default options. Afterwards, open "Git Bash" from your Start menu —
  use this instead of cmd for all git commands.
- **Mac:** open Terminal and type `git --version` — if not installed,
  macOS will prompt you to install "command line developer tools," click
  Install.

### 7.2 Create a GitHub account (if you don't have one)
Go to **https://github.com/signup** and make an account — it's free.

### 7.3 Create a new repository on GitHub
1. Once logged in, click the **+** icon top-right → **New repository**
2. Name it e.g. `geopulse`
3. Leave it Public or Private (Private if the instructor doesn't need it
   public), don't tick "Add a README" (we already have one)
4. Click **Create repository**
5. GitHub shows you a page with commands — keep this page open, you'll
   need the URL it shows (something like
   `https://github.com/tanubedia/geopulse.git`)

### 7.4 Push your project folder to that repository
In your terminal (Git Bash on Windows), navigate to your project folder:
```
cd path/to/member1-snowflake-lakehouse
```
Then run these one at a time:
```
git init
git add .
git commit -m "Member 1: Snowflake data lakehouse - schema, catchment pipeline, visit log, Airflow DAG"
git remote add origin https://github.com/<your-username>/geopulse.git
git branch -M main
git push -u origin main
```
- The first time you push, it may open a browser window asking you to log
  in to GitHub and authorize — do that, it'll continue automatically.
- After `git push` finishes, refresh the GitHub page in your browser — you
  should see all your files there.

### 7.5 What each git command actually does (so it's not just magic)
- `git init` — turns this folder into a git project (one-time)
- `git add .` — stages every file (marks it as "ready to save")
- `git commit -m "..."` — actually saves a snapshot, with your message
  describing what you did
- `git remote add origin <url>` — tells git "this is the online GitHub
  copy" (one-time)
- `git push` — uploads your saved snapshot(s) to GitHub

Any time you change a file later and want to save/upload it again, you
only need to repeat: `git add .`, `git commit -m "describe the change"`,
`git push`.

### 7.6 If your team already has a shared repo
Ask whoever created it for the URL, then instead of Part 7.3-7.4, do:
```
git clone https://github.com/<team-org>/geopulse.git
```
This downloads it into a new `geopulse` folder. Copy your
`member1-snowflake-lakehouse` folder inside it, then:
```
cd geopulse
git checkout -b member1-snowflake-lakehouse
git add member1-snowflake-lakehouse
git commit -m "Add Member 1 Snowflake lakehouse work"
git push -u origin member1-snowflake-lakehouse
```
Then go to the GitHub page for that repo — it'll show a banner offering to
open a "Pull Request" from your new branch — click that, add a short
description, and submit it so your team can review/merge it.

---

## Never commit your password
Create a file named exactly `.gitignore` (already included in the project)
in the project folder — it tells git to skip your generated CSVs and any
`.env` file, so your Snowflake password never ends up on GitHub. Don't put
your password directly in any `.sql` or `.py` file that you commit.

---

## If you get stuck
Copy the **exact error message** you see (screenshot or copy-paste the
text) and share it — most errors here are one of: wrong account locator,
wrong username/password, forgetting to activate `(venv)`, or running a SQL
script before an earlier one finished. I can tell you exactly what's wrong
if you paste the error.
