# 🐝 Supa Script - BEE-MVP Development Server

Quick startup script for the BEE-MVP Supabase development environment.

## Usage

```bash
./supa
```

## What it does

1. **Checks Docker** - Verifies if Docker is running
2. **Starts Docker** - If not running, launches Docker Desktop and waits for it to be ready
3. **Cleans up** - Kills any existing Supabase processes
4. **Starts Supabase** - Launches the functions server with proper environment

## Output

```
🐝 Starting BEE-MVP Supabase Environment...
✅ Docker is already running
🧹 Cleaning up any existing Supabase processes...
🚀 Starting Supabase functions server...
📁 Using environment file: ./app/.env
🌐 Server will be available at: http://127.0.0.1:54321

💡 Press Ctrl+C to stop the server
📋 Logs will appear below:
----------------------------------------
```

## Requirements

- Docker Desktop (for macOS) or Docker (for Linux)
- Supabase CLI installed
- `./app/.env` file with proper configuration

## Notes

- Script automatically waits up to 60 seconds for Docker to start
- Cleans up any existing Supabase processes before starting
- Uses the environment file from `./app/.env`
- Press `Ctrl+C` to stop the server

## Troubleshooting

If Docker fails to start automatically:
1. Start Docker Desktop manually
2. Wait for it to be fully loaded
3. Run `./supa` again 