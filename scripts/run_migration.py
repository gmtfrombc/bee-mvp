#!/usr/bin/env python3
"""
Simple migration runner for Supabase SQL files
"""
import os
import sys
from supabase import create_client, Client


def run_migration(migration_file: str):
    """Run a SQL migration file against Supabase"""

    # Load environment variables
    supabase_url = os.getenv('SUPABASE_URL')
    supabase_key = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

    if not supabase_url or not supabase_key:
        print(
            'Error: Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY environment variables')
        return False

    # Create client
    supabase: Client = create_client(supabase_url, supabase_key)

    try:
        # Read migration file
        with open(migration_file, 'r') as f:
            migration_sql = f.read()

        print(f'Running migration: {migration_file}')

        # Split into individual statements and execute
        statements = [stmt.strip()
                      for stmt in migration_sql.split(';') if stmt.strip()]

        for i, statement in enumerate(statements):
            if statement:
                print(f'Executing statement {i+1}/{len(statements)}...')
                try:
                    result = supabase.sql(statement)
                    print(f'Statement {i+1} executed successfully')
                except Exception as e:
                    print(f'Error in statement {i+1}: {e}')
                    if 'already exists' not in str(e).lower():
                        raise

        print('Migration completed successfully!')
        return True

    except Exception as e:
        print(f'Migration failed: {e}')
        return False


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print('Usage: python run_migration.py <migration_file>')
        sys.exit(1)

    migration_file = sys.argv[1]

    if not os.path.exists(migration_file):
        print(f'Error: Migration file {migration_file} not found')
        sys.exit(1)

    success = run_migration(migration_file)
    sys.exit(0 if success else 1)
