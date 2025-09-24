#!/bin/sh
set -e  # Exit on error for production reliability

# Validate required environment variables
: "${SITECRT:?ERROR: SITECRT is required}"
: "${SITEKEY:?ERROR: SITEKEY is required}"
: "${STEP_CA_URL:?ERROR: STEP_CA_URL is required}"
: "${STEP_EMAIL:?ERROR: STEP_EMAIL is required}"
: "${STEP_DOMAIN:?ERROR: STEP_DOMAIN is required}"

# Optional: STEP_SANS can be empty
STEP_SANS="${STEP_SANS:-}"

# Log function for consistent output
log() {
    printf "[%s] %s\n" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1"
}

# Function to fetch Let's Encrypt root certificate
update_root() {
    local root="${1:?ERROR: root path required}"
    
    log "Fetching Let's Encrypt root certificate"
    rm -f "${root}" && log "Removed old root: ${root}"
    
    local attempts=0
    local max_attempts=3
    while [ $attempts -lt $max_attempts ]; do
        if step ca root "${root}" --ca-url "${STEP_CA_URL}"; then
            log "Successfully fetched root certificate: ${root}"
            return 0
        fi
        attempts=$((attempts + 1))
        log "Failed to fetch root certificate, attempt ${attempts}/${max_attempts}"
        sleep 5
    done
    log "ERROR: Exceeded attempts to fetch root certificate" >&2
    return 1
}

# Function to generate ACME token for certificate issuance
get_token() {
    local name="${1:?ERROR: name required}"
    local sans="${2:-}"
    
    log "Generating ACME token for ${name}"
    local args="--ca-url ${STEP_CA_URL} --email ${STEP_EMAIL} ${name}"
    
    # Add SANs if provided
    if [ -n "${sans}" ]; then
        for san in ${sans//,/ }; do
            args="${args} --san ${san}"
        done
    fi
    
    local token
    token=$(step ca token ${args} 2>/dev/null)
    if [ $? -ne 0 ]; then
        log "ERROR: Failed to retrieve ACME token" >&2
        return 1
    fi
    log "Token retrieved successfully"
    echo "${token}"
}

# Main initialization function
init() {
    log "Starting certificate initialization"
    
    # Clean up old certificates
    rm -f "${SITECRT}" "${SITEKEY}" && \
        log "Removed old certificates: ${SITECRT}, ${SITEKEY}"
    
    # Fetch Let's Encrypt root
    update_root "${STEP_ROOT}" || return 1
    
    # Generate token for domain
    local token
    token=$(get_token "${STEP_DOMAIN}" "${STEP_SANS}")
    if [ $? -ne 0 ]; then
        log "ERROR: Token retrieval failed" >&2
        return 1
    fi
    
    # Request certificate
    log "Requesting certificate for ${STEP_DOMAIN}"
    if step ca certificate \
        --token "${token}" \
        --ca-url "${STEP_CA_URL}" \
        --email "${STEP_EMAIL}" \
        "${STEP_DOMAIN}" \
        "${SITECRT}" \
        "${SITEKEY}" \
        --not-after 2160h; then  # 90 days max for Let's Encrypt
        log "Certificate issued successfully"
    else
        log "ERROR: Certificate issuance failed" >&2
        return 1
    fi
    
    # Verify certificate
    if step certificate inspect "${SITECRT}" --format json | grep -q '"validity"'; then
        log "Certificate verification passed"
    else
        log "ERROR: Certificate verification failed" >&2
        return 1
    fi
}

# Execute initialization
if init; then
    log "Step CLI initialized for Let's Encrypt"
else
    log "ERROR: Failed to initialize Step CLI" >&2
    exit 1
fi

# Secure file permissions
chmod 600 "${SITEKEY}" "${SITECRT}" "${STEP_ROOT}"
log "Set secure permissions on certificate files"

# Execute the provided command (e.g., renew daemon)
exec "$@"
