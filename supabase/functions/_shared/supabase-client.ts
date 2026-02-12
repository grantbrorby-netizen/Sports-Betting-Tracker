import { createClient, SupabaseClient } from "@supabase/supabase-js";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

/** Client that respects RLS — pass the user's JWT */
export function createAnonClient(authToken: string): SupabaseClient {
  return createClient(supabaseUrl, supabaseAnonKey, {
    global: {
      headers: { Authorization: `Bearer ${authToken}` },
    },
  });
}

/** Admin client that bypasses RLS — use only in Edge Functions */
export function createAdminClient(): SupabaseClient {
  return createClient(supabaseUrl, supabaseServiceKey);
}
