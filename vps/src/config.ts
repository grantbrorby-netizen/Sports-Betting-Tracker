import "dotenv/config";

function requireEnv(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

function optionalEnv(name: string, defaultValue: string): string {
  return process.env[name] ?? defaultValue;
}

export interface Config {
  supabaseUrl: string;
  supabaseServiceRoleKey: string;
  redisUrl: string;
  apnsKeyId: string;
  apnsTeamId: string;
  apnsKeyPath: string;
  apnsBundleId: string;
  pollIntervalMs: number;
  aiBrokerUrl: string;
}

export const config: Config = {
  supabaseUrl: requireEnv("SUPABASE_URL"),
  supabaseServiceRoleKey: requireEnv("SUPABASE_SERVICE_ROLE_KEY"),
  redisUrl: optionalEnv("REDIS_URL", "redis://localhost:6379"),
  apnsKeyId: requireEnv("APNS_KEY_ID"),
  apnsTeamId: requireEnv("APNS_TEAM_ID"),
  apnsKeyPath: optionalEnv("APNS_KEY_PATH", "./apns-key.p8"),
  apnsBundleId: requireEnv("APNS_BUNDLE_ID"),
  pollIntervalMs: parseInt(optionalEnv("POLL_INTERVAL_MS", "30000"), 10),
  aiBrokerUrl: optionalEnv(
    "AI_BROKER_URL",
    `${requireEnv("SUPABASE_URL")}/functions/v1/ai-broker`
  ),
};
