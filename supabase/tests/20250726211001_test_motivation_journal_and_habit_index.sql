-- pgTAP tests for motivation_journal and habit_index tables
SET search_path TO public;

-- motivation_journal
SELECT has_table('public','motivation_journal','motivation_journal table should exist');
SELECT has_column('public','motivation_journal','user_id','motivation_journal has user_id column');
SELECT has_column('public','motivation_journal','date','motivation_journal has date column');
SELECT col_is_pk('public','motivation_journal','id','motivation_journal.id is primary key');
SELECT col_is_unique('public','motivation_journal','user_id,date','motivation_journal has unique user_id+date');

-- habit_index
SELECT has_table('public','habit_index','habit_index table should exist');
SELECT has_column('public','habit_index','user_id','habit_index has user_id column');
SELECT has_column('public','habit_index','index_date','habit_index has index_date column');
SELECT col_is_pk('public','habit_index','id','habit_index.id is primary key');
SELECT col_is_unique('public','habit_index','user_id,index_date','habit_index has unique user_id+index_date'); 