#!/bin/bash
set -euo pipefail

echo "🔧 BEE-MVP Local Testing Environment Setup"
echo "=========================================="

cd "$(dirname "$0")/.."

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check system dependencies
check_system_deps() {
    log_info "Checking system dependencies..."
    
    # PostgreSQL
    if ! command -v psql >/dev/null 2>&1; then
        log_error "PostgreSQL not found. Install with: brew install postgresql"
        exit 1
    fi
    
    # Python
    if ! command -v python >/dev/null 2>&1; then
        log_error "Python not found. Install Python 3.8+ from python.org"
        exit 1
    fi
    
    # Flutter
    if ! command -v flutter >/dev/null 2>&1; then
        log_error "Flutter not found. Install from https://flutter.dev/docs/get-started/install"
        exit 1
    fi
    
    # Terraform
    if ! command -v terraform >/dev/null 2>&1; then
        log_error "Terraform not found. Install with: brew install terraform"
        exit 1
    fi
    
    log_success "All system dependencies found"
}

# Setup Python virtual environment
setup_python_env() {
    log_info "Setting up Python virtual environment..."
    
    if [[ ! -d "venv" ]]; then
        log_info "Creating virtual environment..."
        python -m venv venv
    fi
    
    log_info "Activating virtual environment..."
    source venv/bin/activate
    
    log_info "Upgrading pip..."
    pip install --upgrade pip >/dev/null
    
    if [[ -f "tests/requirements-minimal.txt" ]]; then
        log_info "Installing Python test dependencies..."
        pip install -r tests/requirements-minimal.txt >/dev/null
    else
        log_warning "tests/requirements-minimal.txt not found, installing basic dependencies..."
        pip install pytest black ruff psycopg2-binary >/dev/null
    fi
    
    log_success "Python environment ready"
}

# Setup PostgreSQL
setup_postgresql() {
    log_info "Setting up PostgreSQL..."
    
    # Check if PostgreSQL is running
    if ! pgrep -f postgres >/dev/null; then
        log_info "Starting PostgreSQL..."
        if command -v brew >/dev/null 2>&1; then
            brew services start postgresql
        else
            log_warning "Please start PostgreSQL manually"
        fi
    fi
    
    # Test connection
    if psql -c "\q" 2>/dev/null; then
        log_success "PostgreSQL connection working"
    else
        log_error "Cannot connect to PostgreSQL. Please check your installation."
        exit 1
    fi
    
    # Check version
    PSQL_VERSION=$(psql --version | grep -oE '[0-9]+\.[0-9]+')
    MAJOR_VERSION=$(echo $PSQL_VERSION | cut -d. -f1)
    
    log_info "PostgreSQL version: $PSQL_VERSION"
    
    if [ "$MAJOR_VERSION" -lt 14 ]; then
        log_warning "PostgreSQL $PSQL_VERSION detected. CI uses PostgreSQL 14."
        log_warning "Consider upgrading: brew upgrade postgresql"
    fi
}

# Setup Flutter environment
setup_flutter() {
    log_info "Setting up Flutter environment..."
    
    cd app
    
    # Check Flutter doctor
    log_info "Running Flutter doctor..."
    if ! flutter doctor --android-licenses >/dev/null 2>&1; then
        log_warning "Some Flutter dependencies may be missing. Run 'flutter doctor' for details."
    fi

    # Enforce Flutter version consistency
    REQUIRED_FLUTTER_VERSION="3.32.1"
    INSTALLED_VERSION=$(flutter --version 2>/dev/null | head -n1 | awk '{print $2}')
    if [[ "$INSTALLED_VERSION" != "$REQUIRED_FLUTTER_VERSION"* ]]; then
        log_error "Flutter $REQUIRED_FLUTTER_VERSION required but $INSTALLED_VERSION found."
        log_error "Please switch with: flutter version $REQUIRED_FLUTTER_VERSION"
        exit 1
    fi
    
    # Get dependencies
    log_info "Getting Flutter dependencies..."
    flutter pub get >/dev/null
    
    cd ..
    log_success "Flutter environment ready"
}

# Make scripts executable
setup_scripts() {
    log_info "Making test scripts executable..."
    
    chmod +x scripts/test_all_local.sh
    chmod +x scripts/test_database_only.sh
    chmod +x scripts/setup_local_testing.sh
    
    log_success "Test scripts are now executable"
}

# Create helpful aliases
create_aliases() {
    log_info "Creating helpful command aliases..."
    
    cat > scripts/aliases.sh << 'EOF'
#!/bin/bash
# BEE-MVP Testing Aliases
# Source this file in your shell: source scripts/aliases.sh

alias bee-test-all='./scripts/test_all_local.sh'
alias bee-test-db='./scripts/test_database_only.sh'
alias bee-setup='./scripts/setup_local_testing.sh'

echo "🚀 BEE-MVP aliases loaded:"
echo "  bee-test-all  - Run complete test suite"
echo "  bee-test-db   - Run database tests only"
echo "  bee-setup     - Setup local environment"
EOF

    log_success "Aliases created in scripts/aliases.sh"
    log_info "To use aliases, run: source scripts/aliases.sh"
}

# Test the setup
test_setup() {
    log_info "Testing the setup..."
    
    # Quick database test
    if ! ./scripts/test_database_only.sh >/dev/null 2>&1; then
        log_warning "Database test failed. Please check your PostgreSQL setup."
    else
        log_success "Database test passed"
    fi
    
    # Python environment test
    source venv/bin/activate
    if ! python -c "import pytest, black, ruff" 2>/dev/null; then
        log_warning "Python dependencies test failed"
    else
        log_success "Python environment test passed"
    fi
}

# Main setup function
main() {
    echo ""
    log_info "Setting up local testing environment..."
    echo ""
    
    check_system_deps
    setup_postgresql
    setup_python_env
    setup_flutter
    setup_scripts
    create_aliases
    test_setup
    
    echo ""
    log_success "🎉 Local testing environment is ready!"
    echo ""
    echo "Quick start commands:"
    echo "  ./scripts/test_all_local.sh     - Run full test suite"
    echo "  ./scripts/test_database_only.sh - Quick database validation"
    echo "  source scripts/aliases.sh       - Load helpful aliases"
    echo ""
    echo "Development workflow:"
    echo "  1. Make your changes"
    echo "  2. Run ./scripts/test_all_local.sh"
    echo "  3. If tests pass: git commit && git push"
    echo ""
    echo "🚫 No more whack-a-mole debugging!"
    echo ""
}

main "$@" 