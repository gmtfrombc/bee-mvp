// Edge Function entry point for Supabase deployment
import handler from './mod.ts';

Deno.serve(handler); 