import { assertEquals, assert, assertNotEquals } from "https://deno.land/std@0.220.0/assert/mod.ts";
import { encrypt, decrypt, createKeyHint, hexToBytes, bytesToHex } from "../_shared/encryption.ts";

// Generate a random 256-bit key in hex for tests
function generateTestKey(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(32));
  return bytesToHex(bytes);
}

// --- Tests ---

Deno.test("encrypt and decrypt roundtrip", async () => {
  const key = generateTestKey();
  const plaintext = "sk-test-1234567890abcdef";

  const encrypted = await encrypt(plaintext, key);
  const decrypted = await decrypt(encrypted, key);

  assertEquals(decrypted, plaintext);
});

Deno.test("encrypted output differs from plaintext", async () => {
  const key = generateTestKey();
  const plaintext = "sk-test-1234567890abcdef";

  const encrypted = await encrypt(plaintext, key);
  assertNotEquals(encrypted, plaintext);
  assert(encrypted.length > plaintext.length);
});

Deno.test("different encryptions produce different ciphertexts (random IV)", async () => {
  const key = generateTestKey();
  const plaintext = "sk-test-1234567890abcdef";

  const encrypted1 = await encrypt(plaintext, key);
  const encrypted2 = await encrypt(plaintext, key);

  // Random IV means same plaintext → different ciphertext
  assertNotEquals(encrypted1, encrypted2);

  // Both decrypt to the same value
  assertEquals(await decrypt(encrypted1, key), plaintext);
  assertEquals(await decrypt(encrypted2, key), plaintext);
});

Deno.test("decrypt with wrong key fails", async () => {
  const key1 = generateTestKey();
  const key2 = generateTestKey();
  const plaintext = "sk-test-secret";

  const encrypted = await encrypt(plaintext, key1);

  let threw = false;
  try {
    await decrypt(encrypted, key2);
  } catch {
    threw = true;
  }
  assert(threw, "Decrypting with wrong key should throw");
});

Deno.test("hexToBytes and bytesToHex roundtrip", () => {
  const original = "0a1b2c3d4e5f";
  const bytes = hexToBytes(original);
  const result = bytesToHex(bytes);
  assertEquals(result, original);
});

Deno.test("createKeyHint masks long keys", () => {
  const hint = createKeyHint("sk-test-1234567890abcdef");
  assertEquals(hint, "sk-te...def");
});

Deno.test("createKeyHint returns **** for short keys", () => {
  assertEquals(createKeyHint("short"), "****");
  assertEquals(createKeyHint("12345678"), "****");
});

Deno.test("createKeyHint works with 9-char boundary", () => {
  const hint = createKeyHint("123456789");
  assertEquals(hint, "12345...789");
});

Deno.test("encrypt handles empty string", async () => {
  const key = generateTestKey();
  const encrypted = await encrypt("", key);
  const decrypted = await decrypt(encrypted, key);
  assertEquals(decrypted, "");
});

Deno.test("encrypt handles unicode", async () => {
  const key = generateTestKey();
  const plaintext = "api-key-with-émojis-🔑";
  const encrypted = await encrypt(plaintext, key);
  const decrypted = await decrypt(encrypted, key);
  assertEquals(decrypted, plaintext);
});
