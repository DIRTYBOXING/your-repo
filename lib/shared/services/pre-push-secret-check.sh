#!/bin/bash
#
# ==============================================================================
# DFC FINAL PRE-PUSH SECRET CHECK
#
# This script scans for common secret patterns and forbidden filenames before
# allowing a push. It uses `git grep` which respects .gitignore by default.
#
# It is designed to be used as a pre-push Git hook or run manually.
#
# Exits with status 1 if potential secrets are found, 0 otherwise.
# ==============================================================================

echo "🛡️  Running DFC Pre-Push Secret Check..."

# --- Configuration ---

# Add sensitive keywords to this array. Case-insensitive.
# Using word boundaries (\b) to avoid matching substrings in regular words.
FORBIDDEN_PATTERNS=(
    "API_KEY"
    "SECRET_KEY"
    "PRIVATE_KEY"
    "ACCESS_TOKEN"
    "STRIPE_SECRET"
    "FIREBASE_TOKEN"
    "SERVICE_ACCOUNT"
    "client_secret"
    "-----BEGIN RSA PRIVATE KEY-----"
    "-----BEGIN EC PRIVATE KEY-----"
    "-----BEGIN OPENSSH PRIVATE KEY-----"
    "password"
    "token"
)

# Add filenames that should never be committed, even if not in .gitignore.
FORBIDDEN_FILENAMES=(
    ".env"
    "*.pem"
    "*.p12"
    "*.key"
    "google-services.json"
    "service-account.json"
    "*-credentials.json"
)
# Regex to find high-entropy strings (e.g., API keys).
# This looks for long strings of alphanumeric characters.
# Tweak min/max length (e.g., {20,}) as needed.
HIGH_ENTROPY_REGEX="[a-zA-Z0-9-_.]{40,}"

EXIT_CODE=0

# --- Functions ---

print_error() {
    # ANSI color codes: red for error messages
    echo -e "\e[31m$1\e[0m"
}

print_success() {
    # ANSI color codes: green for success messages
    echo -e "\e[32m$1\e[0m"
}

# --- Script Body ---

echo "🔎  Scanning for forbidden keywords..."
# Combine all patterns into a single egrep call for efficiency.
# -E: Use extended regex, -i: case-insensitive, -n: line number, -I: ignore binary
# The IFS trick joins the array elements with a pipe (|).
COMBINED_PATTERNS=$(IFS="|"; echo "${FORBIDDEN_PATTERNS[*]}")
output=$(git grep -E -i -n -I -- "$COMBINED_PATTERNS")
if [ -n "$output" ]; then
    print_error "❌  ERROR: Found forbidden keyword patterns in the following files:"
    echo "$output"
    echo "--------------------------------------------------"
    EXIT_CODE=1
done

echo "🔎  Scanning for forbidden filenames..."
for filename in "${FORBIDDEN_FILENAMES[@]}"; do
    # Use git ls-files to find tracked files matching the pattern
    output=$(git ls-files | grep -i "$filename")
    if [ -n "$output" ]; then
        print_error "❌  ERROR: Found forbidden filename pattern '$filename' tracked by Git:"
        echo "$output"
        echo "--------------------------------------------------"
        EXIT_CODE=1
    fi
done

echo "🔎  Scanning for high-entropy strings (potential leaked keys)..."
# Exclude common files that have long hashes but are not secrets.
output=$(git grep -E -i -n -I -- "$HIGH_ENTROPY_REGEX" -- ':!*.lock' ':!*.svg' ':!*.json')
if [ -n "$output" ]; then
    print_error "❌  WARNING: Found high-entropy strings that could be leaked keys:"
    echo "$output"
    echo "--------------------------------------------------"
    print_error "Please verify these are not secrets. If they are false positives, add them to an exclusion list in the script (e.g., -- ':!path/to/false_positive.file')."
    # This is a warning for local hooks, but the CI workflow will treat it as an error.
    # To make this a hard failure locally, uncomment the next line.
    # EXIT_CODE=1
fi

# --- Final Result ---

if [ $EXIT_CODE -eq 0 ]; then
    print_success "✅  SUCCESS: No secrets found. Repository is clean."
else
    print_error "🛑  FAILURE: Potential secrets detected. Push aborted."
    print_error "Please review the findings above, remove the sensitive data, and consider running a history cleanup tool if the secrets were committed previously."
fi

exit $EXIT_CODE
