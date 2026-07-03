param(
    [string]$PythonExe,
    [string]$DatabaseUrl
)

$ErrorActionPreference = 'Stop'

if (-not $PythonExe) {
    if (Test-Path '.venv\Scripts\python.exe') {
        $PythonExe = '.venv\Scripts\python.exe'
    }
    elseif (Test-Path '.venv-py314-backup-20260416\Scripts\python.exe') {
        $PythonExe = '.venv-py314-backup-20260416\Scripts\python.exe'
    }
    else {
        $PythonExe = 'python'
    }
}

if (-not $DatabaseUrl) {
    $DatabaseUrl = $env:CONTROLROOM_DATABASE_URL
}
if (-not $DatabaseUrl) {
    $DatabaseUrl = $env:DATABASE_URL
}
if (-not $DatabaseUrl) {
    $DatabaseUrl = $env:DFC_DATABASE_URL
}

if (-not $DatabaseUrl) {
    throw 'No CONTROLROOM_DATABASE_URL, DATABASE_URL, or DFC_DATABASE_URL is configured.'
}

$migrationFiles = @(
    'migrations/20260416_create_event_outbox.sql',
    'migrations/20260416_enhance_event_outbox_dispatcher.sql',
    'migrations/20260416_create_superbeast_persistence_tables.sql'
)

$pythonScript = @'
import pathlib
import sys

import psycopg2

database_url = sys.argv[1]
migration_files = sys.argv[2:]

conn = psycopg2.connect(database_url)
conn.autocommit = False

try:
    with conn.cursor() as cursor:
        for migration_path in migration_files:
            sql = pathlib.Path(migration_path).read_text(encoding='utf-8')
            cursor.execute(sql)
            print(f'Applied {migration_path}')
    conn.commit()
    print('Superbeast migrations applied successfully.')
except Exception:
    conn.rollback()
    raise
finally:
    conn.close()
'@

$pythonScript | & $PythonExe - $DatabaseUrl @migrationFiles
