-- =================================================================
-- Clear Test Conversation Logs for a Specific User
-- =================================================================
--
-- Author: Gemini AI Assistant
-- Date: 2024-07-15
--
-- Description:
-- This script is intended for development and testing purposes. It
-- removes all conversation log entries for a specific user ID.
-- This is useful for clearing out test data that might interfere
-- with features like rate-limiting, allowing for a clean testing
-- state.
--
-- !!! WARNING !!!
-- This is a destructive operation.
-- Do not run this in a production environment without confirming
-- the user ID and understanding the consequences.
--
-- =================================================================

DELETE FROM public.conversation_logs
WHERE user_id = 'f8833dd4-1851-4a61-8bfd-b8769cd4068e';

-- After running the delete command, you can uncomment the line below
-- to verify that the records have been removed. It should return a count of 0.

-- SELECT count(*) FROM public.conversation_logs WHERE user_id = 'f8833dd4-1851-4a61-8bfd-b8769cd4068e'; 