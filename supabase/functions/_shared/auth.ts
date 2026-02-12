/** Extract and decode user from Supabase JWT in Authorization header */
export interface AuthUser {
  id: string;
  email: string;
  role: string;
}

export function getUserFromRequest(req: Request): AuthUser | null {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) return null;

  const token = authHeader.slice(7);
  return decodeJWT(token);
}

export function getTokenFromRequest(req: Request): string | null {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) return null;
  return authHeader.slice(7);
}

function decodeJWT(token: string): AuthUser | null {
  try {
    const parts = token.split(".");
    if (parts.length !== 3) return null;

    const payload = JSON.parse(atob(parts[1]));
    return {
      id: payload.sub,
      email: payload.email ?? "",
      role: payload.role ?? "authenticated",
    };
  } catch {
    return null;
  }
}
