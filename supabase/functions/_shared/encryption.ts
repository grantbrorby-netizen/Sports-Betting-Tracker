/** AES-256-GCM encryption for BYOK API keys */

const ALGORITHM = "AES-GCM";
const KEY_LENGTH = 256;
const IV_LENGTH = 12;
const TAG_LENGTH = 128;

function getEncryptionKey(): string {
  const key = Deno.env.get("ENCRYPTION_KEY");
  if (!key) throw new Error("ENCRYPTION_KEY not set");
  return key;
}

function hexToBytes(hex: string): Uint8Array {
  const bytes = new Uint8Array(hex.length / 2);
  for (let i = 0; i < hex.length; i += 2) {
    bytes[i / 2] = parseInt(hex.substring(i, i + 2), 16);
  }
  return bytes;
}

function bytesToHex(bytes: Uint8Array): string {
  return Array.from(bytes)
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

async function importKey(keyHex: string): Promise<CryptoKey> {
  const keyBytes = hexToBytes(keyHex);
  return await crypto.subtle.importKey(
    "raw",
    keyBytes,
    { name: ALGORITHM, length: KEY_LENGTH },
    false,
    ["encrypt", "decrypt"],
  );
}

/** Encrypt a plaintext string. Returns hex(iv + ciphertext). */
export async function encrypt(plaintext: string): Promise<string> {
  const keyHex = getEncryptionKey();
  const key = await importKey(keyHex);

  const iv = crypto.getRandomValues(new Uint8Array(IV_LENGTH));
  const encoded = new TextEncoder().encode(plaintext);

  const ciphertext = new Uint8Array(
    await crypto.subtle.encrypt(
      { name: ALGORITHM, iv, tagLength: TAG_LENGTH },
      key,
      encoded,
    ),
  );

  // Prepend IV to ciphertext
  const combined = new Uint8Array(iv.length + ciphertext.length);
  combined.set(iv);
  combined.set(ciphertext, iv.length);

  return bytesToHex(combined);
}

/** Decrypt a hex(iv + ciphertext) string. Returns plaintext. */
export async function decrypt(encryptedHex: string): Promise<string> {
  const keyHex = getEncryptionKey();
  const key = await importKey(keyHex);

  const combined = hexToBytes(encryptedHex);
  const iv = combined.slice(0, IV_LENGTH);
  const ciphertext = combined.slice(IV_LENGTH);

  const decrypted = await crypto.subtle.decrypt(
    { name: ALGORITHM, iv, tagLength: TAG_LENGTH },
    key,
    ciphertext,
  );

  return new TextDecoder().decode(decrypted);
}

/** Create a masked hint from an API key: "sk-ab...xy" */
export function createKeyHint(apiKey: string): string {
  if (apiKey.length <= 8) return "****";
  return `${apiKey.slice(0, 5)}...${apiKey.slice(-3)}`;
}
