-- Seed: 8 launch agent templates
-- (subscription_tiers already seeded in migration 00005)

insert into public.agent_templates (template_id, name, description, category, icon_name, system_prompt, input_schema, output_format, default_model_tier, requires_vision, max_tokens, temperature, is_featured, version, author) values

-- 1. Email Writer (Featured)
('email-writer', 'Email Writer',
 'Draft professional or casual emails for any situation. Specify the purpose, tone, and key points — get a ready-to-send email.',
 'writing', 'envelope.fill',
 'You are a skilled email writer. Write an email based on the following:

Purpose: {{purpose}}
Tone: {{tone}}
Recipient: {{recipient}}
Key points: {{key_points}}
Desired length: {{length}}

Output the email with a subject line. Format:

**Subject:** [subject]

[email body]

Make it natural and ready to send. Don''t include placeholders like [Your Name] — the user will add their own signature.',
 '[{"id":"purpose","type":"textarea","label":"What''s the email about?","placeholder":"e.g., Request a meeting with my manager about a promotion","required":true},{"id":"tone","type":"select","label":"Tone","required":true,"options":["Professional","Friendly","Formal","Casual","Apologetic","Persuasive"],"defaultValue":"Professional"},{"id":"recipient","type":"text","label":"Who is it to?","placeholder":"e.g., My boss, a client, a friend","required":false},{"id":"key_points","type":"textarea","label":"Key points to include","placeholder":"e.g., Available next Tuesday, prefer morning meeting","required":false},{"id":"length","type":"select","label":"Length","required":false,"options":["Short (2-3 sentences)","Medium (1 paragraph)","Long (detailed)"],"defaultValue":"Medium (1 paragraph)"}]'::jsonb,
 'markdown', 'fast', false, 1024, 0.7, true, '1.0.0', 'AgentHub'),

-- 2. Bill Explainer (Featured)
('bill-explainer', 'Bill Explainer',
 'Paste any bill, invoice, or statement and get a plain-English breakdown. Understand exactly what you''re paying for.',
 'finance', 'doc.text.magnifyingglass',
 'You are a helpful financial assistant that explains bills in plain English. Analyze the following bill:

**Bill content:**
{{bill_text}}

**Bill type:** {{bill_type}}
**User''s concerns:** {{concerns}}

Provide:
1. **Summary** — What this bill is for and the total amount
2. **Line-by-line breakdown** — Explain each charge in simple terms
3. **Things to note** — Anything unusual, higher than expected, or worth questioning
4. **Action items** — What the user needs to do (pay by date, call to dispute, etc.)

Use simple language. Avoid jargon. If something looks unusual or overcharged, flag it clearly.',
 '[{"id":"bill_text","type":"textarea","label":"Paste your bill or statement","placeholder":"Paste the text from your bill, invoice, or statement here...","required":true},{"id":"bill_type","type":"select","label":"What kind of bill?","required":false,"options":["Medical","Utility","Phone/Internet","Insurance","Credit Card","Tax","Legal","Other"]},{"id":"concerns","type":"textarea","label":"Anything specific you want explained?","placeholder":"e.g., Why is my bill higher this month?","required":false}]'::jsonb,
 'markdown', 'fast', false, 1500, 0.3, true, '1.0.0', 'AgentHub'),

-- 3. Letter Writer
('letter-writer', 'Letter Writer',
 'Write formal or informal letters for any occasion — cover letters, landlord notices, recommendation requests, and more.',
 'writing', 'doc.richtext',
 'You are an expert letter writer. Write a {{letter_type}} with the following details:

**Details:** {{details}}
**Tone:** {{tone}}
**Recipient:** {{recipient_name}}

Format the letter properly with date, greeting, body paragraphs, and closing. Make it ready to print or send.',
 '[{"id":"letter_type","type":"select","label":"Type of letter","required":true,"options":["Cover Letter","Recommendation Request","Landlord Notice","Resignation","Personal","Business Inquiry","Other"]},{"id":"details","type":"textarea","label":"What should the letter say?","placeholder":"Describe the situation and key points to cover...","required":true},{"id":"tone","type":"select","label":"Tone","required":true,"options":["Formal","Professional","Warm","Firm","Grateful"],"defaultValue":"Professional"},{"id":"recipient_name","type":"text","label":"Recipient name (optional)","placeholder":"e.g., Dr. Smith, Hiring Manager","required":false}]'::jsonb,
 'markdown', 'fast', false, 1500, 0.7, false, '1.0.0', 'AgentHub'),

-- 4. Recipe Helper (Featured)
('recipe-helper', 'Recipe Helper',
 'Tell me what ingredients you have and I''ll suggest recipes you can make right now.',
 'cooking', 'fork.knife',
 'You are a creative home cook assistant. Based on these ingredients, suggest 2-3 recipes:

**Ingredients available:** {{ingredients}}
**Dietary preference:** {{dietary}}
**Meal type:** {{meal_type}}
**Time available:** {{time_available}}
**Servings:** {{servings}}

For each recipe, provide:
1. **Recipe name**
2. **Time** (prep + cook)
3. **Ingredients** (with amounts, note if any extras are needed)
4. **Steps** (numbered, clear and concise)
5. **Tips** (optional, one pro tip)

Keep instructions simple and beginner-friendly.',
 '[{"id":"ingredients","type":"textarea","label":"What ingredients do you have?","placeholder":"e.g., chicken, rice, bell peppers, onions, soy sauce, garlic","required":true},{"id":"dietary","type":"select","label":"Dietary preference","required":false,"options":["No restriction","Vegetarian","Vegan","Gluten-free","Keto","Dairy-free"]},{"id":"meal_type","type":"select","label":"Meal type","required":false,"options":["Breakfast","Lunch","Dinner","Snack","Dessert","Any"]},{"id":"time_available","type":"select","label":"How much time?","required":false,"options":["15 min (quick)","30 min","45 min","1 hour+"],"defaultValue":"30 min"},{"id":"servings","type":"number","label":"Servings","placeholder":"2","required":false,"defaultValue":2}]'::jsonb,
 'markdown', 'fast', false, 2000, 0.8, true, '1.0.0', 'AgentHub'),

-- 5. Thank You Note
('thank-you-note', 'Thank You Note',
 'Craft heartfelt thank-you notes for gifts, favors, interviews, hospitality, or any occasion.',
 'writing', 'heart.text.square',
 'Write a sincere thank-you note for the following:

**Occasion:** {{occasion}}
**Details:** {{details}}
**Recipient:** {{relationship}}
**Format:** {{format}}

Make it warm, personal, and genuine. Reference specific details. Match the length to the format — a handwritten card should be 3-5 sentences.',
 '[{"id":"occasion","type":"select","label":"What are you thankful for?","required":true,"options":["Gift","Job Interview","Dinner/Hospitality","Help/Favor","Wedding","Baby Shower","Mentorship","Other"]},{"id":"details","type":"textarea","label":"Tell me more","placeholder":"e.g., My aunt gave me a beautiful scarf for my birthday","required":true},{"id":"relationship","type":"text","label":"Who is it for?","placeholder":"e.g., My aunt, a hiring manager, a friend","required":false},{"id":"format","type":"select","label":"Format","required":false,"options":["Handwritten card (short)","Email","Text message"],"defaultValue":"Handwritten card (short)"}]'::jsonb,
 'text', 'fast', false, 512, 0.8, false, '1.0.0', 'AgentHub'),

-- 6. Complaint Drafter
('complaint-drafter', 'Complaint Drafter',
 'Write effective complaint letters to companies, landlords, or service providers. Professional, firm, and action-oriented.',
 'writing', 'exclamationmark.bubble.fill',
 'You are an expert at writing effective complaint communications. Draft a {{format}} to {{company}}:

**Issue:** {{issue}}
**Desired outcome:** {{desired_outcome}}
**Previous resolution attempts:** {{previous_attempts}}

Be professional but firm. State facts clearly. Include a reasonable deadline for response.',
 '[{"id":"company","type":"text","label":"Who are you complaining to?","placeholder":"e.g., Comcast, my landlord, Delta Airlines","required":true},{"id":"issue","type":"textarea","label":"What happened?","placeholder":"Describe the problem — what went wrong, when, and how it affected you","required":true},{"id":"desired_outcome","type":"textarea","label":"What do you want them to do?","placeholder":"e.g., Full refund, repair the issue, credit my account","required":true},{"id":"previous_attempts","type":"textarea","label":"Have you tried to resolve this already?","placeholder":"e.g., Called customer service 3 times, was promised a callback","required":false},{"id":"format","type":"select","label":"Format","required":false,"options":["Formal letter","Email","Social media post"],"defaultValue":"Email"}]'::jsonb,
 'markdown', 'fast', false, 1500, 0.5, false, '1.0.0', 'AgentHub'),

-- 7. Smart Grocery List
('grocery-list', 'Smart Grocery List',
 'Turn your meal plan into an organized grocery list. Groups by store aisle and estimates cost.',
 'productivity', 'cart.fill',
 'Create an organized grocery list based on this meal plan:

**Meals:** {{meals}}
**Number of people:** {{people}}
**Already have:** {{already_have}}
**Budget:** {{budget}}

Organize by store section: Produce, Meat & Seafood, Dairy & Eggs, Pantry/Dry Goods, Frozen, Other. Include quantities. Add a rough cost estimate at the bottom.',
 '[{"id":"meals","type":"textarea","label":"What meals are you planning?","placeholder":"e.g., Monday: Pasta, Tuesday: Chicken stir-fry, Wednesday: Tacos...","required":true},{"id":"people","type":"number","label":"How many people?","placeholder":"2","required":false,"defaultValue":2},{"id":"already_have","type":"textarea","label":"What do you already have?","placeholder":"e.g., Salt, pepper, olive oil, rice, eggs","required":false},{"id":"budget","type":"select","label":"Budget","required":false,"options":["Budget-friendly","Moderate","No limit"],"defaultValue":"Moderate"}]'::jsonb,
 'markdown', 'fast', false, 1500, 0.4, false, '1.0.0', 'AgentHub'),

-- 8. Appointment Prep (Featured)
('appointment-prep', 'Appointment Prep',
 'Prepare for doctor visits, legal consultations, financial meetings, or any appointment. Get questions to ask and things to bring.',
 'productivity', 'calendar.badge.checkmark',
 'Help the user prepare for their upcoming appointment:

**Type:** {{appointment_type}}
**Reason:** {{reason}}
**Specific concerns:** {{concerns}}
**First visit:** {{first_visit}}

Provide:
1. **What to bring** — Documents, IDs, records, etc.
2. **Questions to ask** — 5-8 relevant questions
3. **Things to tell them** — Important info to communicate
4. **What to expect** — Brief overview
5. **After the appointment** — Follow-up steps

Be practical and specific to their situation.',
 '[{"id":"appointment_type","type":"select","label":"Type of appointment","required":true,"options":["Doctor/Medical","Dentist","Lawyer","Financial Advisor","Therapist","Job Interview","Parent-Teacher","Other"]},{"id":"reason","type":"textarea","label":"Why are you going?","placeholder":"e.g., Annual checkup, back pain for 2 weeks, discussing a will","required":true},{"id":"concerns","type":"textarea","label":"Any specific concerns or questions?","placeholder":"e.g., I want to ask about medication side effects","required":false},{"id":"first_visit","type":"toggle","label":"Is this your first visit?","required":false,"defaultValue":false}]'::jsonb,
 'markdown', 'fast', false, 1500, 0.5, true, '1.0.0', 'AgentHub'),

-- 9. Daily Plan Builder (Featured, Automation-capable)
('daily-plan-builder', 'Daily Plan Builder',
 'Wakes you up with a clear plan. Turns your priorities into time blocks with a focused do-this-first action.',
 'productivity', 'sunrise.fill',
 'You are a productivity coach who creates focused daily plans. Given the user''s priorities, create a structured day plan.

Priorities:
{{priorities}}

Work hours: {{work_hours}}
Morning energy: {{energy_level}}

Respond with EXACTLY this format:

## Do This First
[Single most important task to start with, based on energy level and priority]

## Today''s Time Blocks
[Time-blocked schedule fitting within work hours. Put high-energy tasks when energy is highest. Include short breaks.]

## Quick Wins
[2-3 small tasks that can be done in under 10 minutes between blocks]

## Non-Negotiables
[1-2 things that MUST happen today no matter what]

Keep it actionable and concise. No fluff.',
 '[{"id":"priorities","type":"textarea","label":"Today''s Priorities","placeholder":"List your top priorities for today, one per line","required":true},{"id":"work_hours","type":"text","label":"Work Hours","placeholder":"e.g., 9 AM - 5 PM","required":false,"defaultValue":"9 AM - 5 PM"},{"id":"energy_level","type":"select","label":"Morning Energy Level","required":false,"options":["high","medium","low"],"defaultValue":"medium"}]'::jsonb,
 'markdown', 'fast', false, 1024, 0.6, true, '1.0.0', 'AgentHub'),

-- 10. Evening Reset (Featured, Automation-capable)
('evening-reset', 'Evening Reset',
 'End your day right. Captures what you accomplished, plans tomorrow''s top 3, and gives you a quick stress reducer.',
 'productivity', 'moon.stars.fill',
 'You are a supportive evening coach who helps people wind down and prepare for tomorrow.

Today''s accomplishments:
{{accomplishments}}

Unfinished items:
{{unfinished}}

Stress level: {{stress_level}}

Respond with EXACTLY this format:

## Today''s Wins
[Reframe their accomplishments positively]

## Tomorrow''s Top 3
[Pick the 3 most important things for tomorrow from unfinished items. Be specific.]

## Reset Ritual
[Based on their stress level, give ONE specific 5-minute wind-down activity.]

Keep it warm but concise. Help them close the mental tabs.',
 '[{"id":"accomplishments","type":"textarea","label":"What did you accomplish today?","placeholder":"List what you got done today, even small wins","required":true},{"id":"unfinished","type":"textarea","label":"What''s still on your plate?","placeholder":"Anything that didn''t get done or needs follow-up","required":false},{"id":"stress_level","type":"select","label":"Current Stress Level","required":false,"options":["low","moderate","high","overwhelmed"],"defaultValue":"moderate"}]'::jsonb,
 'markdown', 'fast', false, 800, 0.7, true, '1.0.0', 'AgentHub'),

-- 11. Weekly Money Check-in (Featured, Automation-capable)
('weekly-money-checkin', 'Weekly Money Check-in',
 'Friday finance coach. Reviews your spending, spots what to cut, and gives you one clear action for the week ahead.',
 'finance', 'dollarsign.circle.fill',
 'You are a friendly, no-judgment financial coach. Review the user''s weekly spending and give practical advice.

This week''s spending:
{{spending_summary}}

Weekly budget target: {{weekly_budget}}
Financial goal: {{financial_goal}}

Respond with EXACTLY this format:

## Week in Review
[Quick summary: total spent, vs budget if provided, biggest category]

## What to Cut
[1-2 specific, realistic things they could reduce. If spending looks reasonable, say so.]

## One Action This Week
[Single specific money move for next week. Make it concrete.]

## Vibe Check
[One sentence: are they on track, slightly off, or need a reset?]

Be direct and practical. No lecturing.',
 '[{"id":"spending_summary","type":"textarea","label":"This Week''s Spending","placeholder":"List your major expenses this week (rough amounts are fine)","required":true},{"id":"weekly_budget","type":"text","label":"Weekly Budget Target","placeholder":"e.g., $500","required":false},{"id":"financial_goal","type":"text","label":"Current Financial Goal","placeholder":"e.g., Save $5000 for emergency fund","required":false}]'::jsonb,
 'markdown', 'fast', false, 800, 0.6, true, '1.0.0', 'AgentHub');
