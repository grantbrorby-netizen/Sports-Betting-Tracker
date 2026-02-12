# Privacy Policy

**AgentHub — AI Agent Marketplace**

Last Updated: 2026-02-12

---

## 1. Introduction

AgentHub ("we", "our", "us") operates the AgentHub mobile application (the "App"). This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use the App.

By using the App, you agree to the collection and use of information in accordance with this policy.

---

## 2. Information We Collect

### 2.1 Account Information
- **Email address** — used for authentication and account recovery
- **Display name** — optional, shown in-app
- **Apple ID token** — if you sign in with Apple (we do not receive your Apple password)

### 2.2 Usage Data
- **Agent execution history** — inputs you provide to AI agents and the outputs generated
- **Daily usage counts** — number of AI calls per model tier
- **Automation configurations** — schedules and agent chains you create
- **Installed agents** — which agents you have added from the store

### 2.3 Subscription Data
- **Subscription tier** — Free, Starter, Pro, or Unlimited
- **StoreKit transaction IDs** — provided by Apple for purchase verification
- **Trial status** — whether your free trial is active

### 2.4 Device Information
- **Device token** — for push notifications (only if you enable automations)
- We do **not** collect device identifiers (IDFA), location, contacts, or photos.

### 2.5 Bring Your Own Key (BYOK)
- If you provide your own API keys (OpenAI, Anthropic), they are **encrypted with AES-256-GCM** before storage and are never logged or transmitted in plaintext.

---

## 3. How We Use Your Information

We use collected information to:

- **Provide the service** — execute AI agents, deliver automation results, manage subscriptions
- **Enforce usage limits** — track daily AI calls against your tier allowance
- **Send push notifications** — deliver automation results you have configured
- **Improve the App** — aggregate, anonymized usage statistics
- **Prevent abuse** — rate limiting and security scanning

We do **not**:
- Sell your personal data to third parties
- Use your data for advertising
- Train AI models on your inputs or outputs

---

## 4. AI Provider Data Sharing

When you run an AI agent, your inputs are sent to one of the following providers to generate a response:

| Provider | Data Sent | Their Privacy Policy |
|---|---|---|
| **OpenAI** | Agent prompt + your inputs | https://openai.com/privacy |
| **Anthropic** | Agent prompt + your inputs | https://www.anthropic.com/privacy |

- If you use **BYOK**, requests are made directly using your API key and are subject to that provider's terms.
- If you use **platform-provided AI**, requests are made using our API keys. Providers may process data per their policies, but we have agreements that prohibit training on our API traffic.

---

## 5. Data Storage and Security

- All data is stored in **Supabase** (hosted on AWS), protected by **Row Level Security** — you can only access your own data.
- BYOK API keys are encrypted with **AES-256-GCM** at rest.
- All communication uses **HTTPS/TLS**.
- Authentication uses **JWT tokens** with short expiration windows.
- Edge functions enforce **per-user rate limiting**.

---

## 6. Data Retention

| Data Type | Retention Period |
|---|---|
| Account information | Until you delete your account |
| Agent execution history | 90 days, then automatically deleted |
| Usage tracking | 30 days rolling window |
| Automation run history | 30 days |
| BYOK keys | Until you remove them |
| Subscription data | Duration of subscription + 30 days |

---

## 7. Your Rights

You have the right to:

- **Access** your data — view all stored information via the App
- **Delete** your account and all associated data — contact us or use in-app settings
- **Export** your execution history — available via the App
- **Revoke BYOK keys** — delete your API keys at any time
- **Opt out of push notifications** — disable in iOS Settings or remove automations

### GDPR (EU/EEA Users)
If you are in the EU/EEA, you additionally have the right to:
- Request data portability
- Object to processing
- Lodge a complaint with your local data protection authority

### CCPA (California Users)
California residents have the right to:
- Know what personal information is collected
- Request deletion of personal information
- Not be discriminated against for exercising privacy rights

---

## 8. Children's Privacy

AgentHub is not intended for children under 13. We do not knowingly collect personal information from children under 13. If you believe we have collected such information, contact us immediately.

---

## 9. Changes to This Policy

We may update this Privacy Policy from time to time. We will notify you of material changes via in-app notification or email. Continued use after changes constitutes acceptance.

---

## 10. Contact Us

For privacy questions, data requests, or concerns:

- **Email**: privacy@agenthub.app
- **Subject line**: "Privacy Request — [Your Request]"

We will respond within 30 days.
