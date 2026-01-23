# CLAUDE.md - Sports Betting Tracker

**AI Assistant Guide for Sports Betting Tracker Development**

Last Updated: 2026-01-23

## Project Overview

**Sports Betting Tracker** is a comprehensive application for tracking, analyzing, and managing sports betting activities. This document provides AI assistants with essential context about the codebase structure, development workflows, and key conventions.

## Current Repository State

**Status**: Fresh initialization - empty repository
**Branch**: claude/claude-md-mkq9qp3m10w77miw-5o54z
**Remote**: grantbrorby-netizen/Sports-Betting-Tracker

This repository is currently empty and ready for initial development. The sections below outline the recommended structure and conventions for building this project.

---

## Recommended Technology Stack

Based on typical sports betting tracker requirements, the following stack is recommended:

### Frontend
- **Framework**: React or Next.js for modern UI
- **State Management**: Redux Toolkit or Zustand
- **Styling**: Tailwind CSS or Material-UI
- **Charts/Visualization**: Chart.js or Recharts for betting analytics
- **Forms**: React Hook Form with Zod validation
- **API Client**: Axios or React Query

### Backend
- **Runtime**: Node.js with Express or Python with FastAPI
- **Database**: PostgreSQL for relational data
- **ORM**: Prisma (Node.js) or SQLAlchemy (Python)
- **Authentication**: JWT with secure token storage
- **Validation**: Zod (TS) or Pydantic (Python)

### DevOps & Tooling
- **Version Control**: Git with conventional commits
- **Testing**: Jest/Vitest (frontend), pytest (backend)
- **Linting**: ESLint + Prettier (JS/TS) or Black + Ruff (Python)
- **CI/CD**: GitHub Actions
- **Container**: Docker with docker-compose

---

## Recommended Directory Structure

```
Sports-Betting-Tracker/
├── frontend/                    # Frontend application
│   ├── src/
│   │   ├── components/         # Reusable UI components
│   │   │   ├── common/        # Generic components (Button, Input, etc.)
│   │   │   ├── bets/          # Bet-related components
│   │   │   ├── analytics/     # Charts and statistics
│   │   │   └── layout/        # Layout components (Header, Sidebar)
│   │   ├── pages/             # Page components/routes
│   │   ├── hooks/             # Custom React hooks
│   │   ├── services/          # API service layer
│   │   ├── store/             # State management
│   │   ├── utils/             # Utility functions
│   │   ├── types/             # TypeScript type definitions
│   │   └── App.tsx            # Main app component
│   ├── public/                # Static assets
│   ├── tests/                 # Frontend tests
│   └── package.json
│
├── backend/                    # Backend API
│   ├── src/
│   │   ├── routes/            # API route handlers
│   │   ├── models/            # Database models
│   │   ├── services/          # Business logic layer
│   │   ├── middleware/        # Express/API middleware
│   │   ├── utils/             # Helper functions
│   │   ├── validators/        # Input validation schemas
│   │   └── app.ts             # Main application file
│   ├── tests/                 # Backend tests
│   ├── migrations/            # Database migrations
│   └── package.json
│
├── shared/                     # Shared code between frontend/backend
│   └── types/                 # Shared TypeScript types
│
├── database/                   # Database related files
│   ├── schema.sql             # Database schema
│   ├── seeds/                 # Seed data for development
│   └── migrations/            # SQL migrations
│
├── docs/                       # Documentation
│   ├── api/                   # API documentation
│   ├── architecture/          # Architecture diagrams
│   └── setup/                 # Setup guides
│
├── scripts/                    # Utility scripts
│   ├── setup.sh              # Initial setup script
│   └── deploy.sh             # Deployment script
│
├── .github/                    # GitHub specific files
│   └── workflows/             # GitHub Actions workflows
│
├── docker-compose.yml         # Local development environment
├── .gitignore
├── .env.example               # Environment variables template
├── README.md                  # Project documentation
└── CLAUDE.md                  # This file
```

---

## Core Features to Implement

### 1. Bet Management
- **Create Bets**: Record new bets with details (sport, teams, odds, stake, type)
- **Edit Bets**: Modify pending bets
- **Track Results**: Update bets with outcomes (win/loss/push)
- **Bet Types**: Support various bet types (moneyline, spread, over/under, parlays, teasers)

### 2. Analytics & Reporting
- **Win Rate**: Calculate overall and sport-specific win rates
- **ROI Tracking**: Return on investment calculations
- **Profit/Loss**: Track financial performance over time
- **Sport/League Breakdown**: Performance by sport, league, or team
- **Trend Analysis**: Visual charts showing betting patterns

### 3. Bankroll Management
- **Balance Tracking**: Monitor current bankroll
- **Stake Sizing**: Recommend bet sizes based on bankroll
- **Unit System**: Track bets in units for consistency
- **Deposit/Withdrawal**: Record bankroll changes

### 4. User Authentication
- **Registration/Login**: Secure user accounts
- **Profile Management**: User preferences and settings
- **Multi-User Support**: Separate data per user

### 5. Data Visualization
- **Charts**: Line charts for profit trends, pie charts for bet distribution
- **Statistics Cards**: Quick stats overview (total bets, win rate, profit)
- **Filters**: Date ranges, sport filters, outcome filters

---

## Database Schema (Recommended)

### Users Table
```sql
users (
  id: UUID PRIMARY KEY,
  email: VARCHAR UNIQUE NOT NULL,
  password_hash: VARCHAR NOT NULL,
  username: VARCHAR UNIQUE,
  created_at: TIMESTAMP,
  updated_at: TIMESTAMP
)
```

### Bets Table
```sql
bets (
  id: UUID PRIMARY KEY,
  user_id: UUID FOREIGN KEY,
  sport: VARCHAR NOT NULL,
  league: VARCHAR,
  event_date: TIMESTAMP,
  bet_type: ENUM('moneyline', 'spread', 'over_under', 'parlay', 'teaser'),
  description: TEXT,
  odds: DECIMAL(6,2),
  stake: DECIMAL(10,2),
  potential_return: DECIMAL(10,2),
  result: ENUM('pending', 'win', 'loss', 'push', 'void'),
  actual_return: DECIMAL(10,2),
  placed_at: TIMESTAMP,
  settled_at: TIMESTAMP,
  notes: TEXT,
  created_at: TIMESTAMP,
  updated_at: TIMESTAMP
)
```

### Bankroll Table
```sql
bankroll_transactions (
  id: UUID PRIMARY KEY,
  user_id: UUID FOREIGN KEY,
  type: ENUM('deposit', 'withdrawal', 'bet_win', 'bet_loss'),
  amount: DECIMAL(10,2),
  balance_after: DECIMAL(10,2),
  description: TEXT,
  created_at: TIMESTAMP
)
```

---

## Development Workflows

### Branch Strategy

**Main Branches:**
- `main` - Production-ready code
- `develop` - Integration branch for features
- `claude/*` - AI assistant working branches (e.g., `claude/claude-md-mkq9qp3m10w77miw-5o54z`)

**Feature Branches:**
- `feature/bet-creation` - New features
- `fix/bug-name` - Bug fixes
- `refactor/component-name` - Code refactoring

### Commit Conventions

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**
```
feat(bets): add parlay bet support
fix(analytics): correct ROI calculation for parlays
docs(api): update bet creation endpoint documentation
refactor(components): extract BetCard to separate component
```

### Git Workflow for AI Assistants

1. **Always work on Claude branches** starting with `claude/`
2. **Commit frequently** with descriptive messages
3. **Push to origin** using: `git push -u origin <branch-name>`
4. **Retry on network errors** up to 4 times with exponential backoff
5. **Never force push** to main/develop without explicit permission

### Pull Request Guidelines

**PR Title Format:**
```
[Type] Brief description of changes
```

**PR Description Template:**
```markdown
## Summary
Brief description of what this PR does

## Changes
- Bullet point list of specific changes
- Include file paths where relevant

## Testing
- How to test these changes
- Any new test cases added

## Related Issues
Closes #123

https://claude.ai/code/session_[SESSION_ID]
```

---

## Code Conventions

### TypeScript/JavaScript

**Style Guide:**
- Use TypeScript for type safety
- 2 spaces for indentation
- Use `const` by default, `let` when needed, avoid `var`
- Prefer arrow functions for callbacks
- Use async/await over promises
- Destructure objects and arrays where appropriate

**Naming Conventions:**
- `PascalCase` for components, classes, types, interfaces
- `camelCase` for variables, functions, methods
- `UPPER_SNAKE_CASE` for constants
- Prefix interfaces with `I` if needed for clarity
- Suffix types with `Type` for clarity (e.g., `BetType`)

**Example Component:**
```typescript
import React, { useState } from 'react';
import { Bet, BetType } from '../types/bet';

interface BetCardProps {
  bet: Bet;
  onUpdate: (id: string, updates: Partial<Bet>) => void;
}

export const BetCard: React.FC<BetCardProps> = ({ bet, onUpdate }) => {
  const [isEditing, setIsEditing] = useState(false);

  const handleUpdate = async () => {
    // Implementation
  };

  return (
    <div className="bet-card">
      {/* Component JSX */}
    </div>
  );
};
```

### Python (if used)

**Style Guide:**
- Follow PEP 8
- Use type hints
- 4 spaces for indentation
- Maximum line length: 88 characters (Black default)
- Use snake_case for functions and variables
- Use PascalCase for classes

**Example Model:**
```python
from datetime import datetime
from typing import Optional
from pydantic import BaseModel

class BetCreate(BaseModel):
    sport: str
    league: Optional[str] = None
    bet_type: str
    odds: float
    stake: float
    description: str
    event_date: datetime

class Bet(BetCreate):
    id: str
    user_id: str
    result: Optional[str] = "pending"
    created_at: datetime
    updated_at: datetime
```

### SQL

- Use lowercase for SQL keywords
- Use snake_case for table and column names
- Always specify column names in INSERT statements
- Use meaningful aliases in JOINs
- Add indexes for foreign keys and frequently queried columns

---

## Testing Guidelines

### Frontend Testing

**Unit Tests:**
- Test individual components in isolation
- Use React Testing Library
- Test user interactions, not implementation details
- Aim for 80%+ code coverage

**Example:**
```typescript
import { render, screen, fireEvent } from '@testing-library/react';
import { BetCard } from './BetCard';

describe('BetCard', () => {
  it('should display bet details', () => {
    const mockBet = {
      id: '1',
      sport: 'NFL',
      odds: -110,
      stake: 100,
    };

    render(<BetCard bet={mockBet} onUpdate={jest.fn()} />);

    expect(screen.getByText('NFL')).toBeInTheDocument();
    expect(screen.getByText('-110')).toBeInTheDocument();
  });
});
```

### Backend Testing

**Integration Tests:**
- Test API endpoints with real database
- Use test database or transactions
- Test authentication and authorization
- Test error handling

**Example:**
```typescript
describe('POST /api/bets', () => {
  it('should create a new bet', async () => {
    const response = await request(app)
      .post('/api/bets')
      .set('Authorization', `Bearer ${token}`)
      .send({
        sport: 'NFL',
        odds: -110,
        stake: 100,
      });

    expect(response.status).toBe(201);
    expect(response.body).toHaveProperty('id');
  });
});
```

---

## API Design Principles

### RESTful Conventions

**Endpoints:**
```
GET    /api/bets           - List all bets (with filters)
POST   /api/bets           - Create new bet
GET    /api/bets/:id       - Get specific bet
PUT    /api/bets/:id       - Update bet
DELETE /api/bets/:id       - Delete bet
PATCH  /api/bets/:id       - Partial update

GET    /api/analytics      - Get analytics data
GET    /api/bankroll       - Get bankroll info
POST   /api/bankroll       - Add transaction
```

**Request/Response Format:**
- Always use JSON
- Include proper HTTP status codes
- Provide meaningful error messages
- Use pagination for lists

**Example Response:**
```json
{
  "data": {
    "id": "123",
    "sport": "NFL",
    "odds": -110,
    "stake": 100
  },
  "meta": {
    "timestamp": "2026-01-23T12:00:00Z"
  }
}
```

**Error Response:**
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid bet type",
    "details": {
      "field": "bet_type",
      "received": "invalid_type"
    }
  }
}
```

---

## Security Best Practices

### Authentication & Authorization
- Use JWT tokens with short expiration (15min access, 7d refresh)
- Hash passwords with bcrypt (minimum 12 rounds)
- Implement rate limiting on auth endpoints
- Use HTTPS only in production
- Store sensitive data in environment variables

### Input Validation
- Validate all user input on backend
- Sanitize input to prevent SQL injection
- Use parameterized queries or ORM
- Validate data types, ranges, and formats
- Never trust client-side validation alone

### Data Protection
- Don't expose user data across accounts
- Use UUIDs instead of sequential IDs
- Implement proper CORS policies
- Log security events
- Never commit .env files or secrets

---

## Environment Variables

**Required Variables (.env.example):**
```bash
# Application
NODE_ENV=development
PORT=3000
APP_URL=http://localhost:3000

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/sports_betting
DATABASE_POOL_SIZE=10

# Authentication
JWT_SECRET=your-secret-key-change-in-production
JWT_EXPIRY=15m
REFRESH_TOKEN_EXPIRY=7d

# External APIs (if needed)
ODDS_API_KEY=your-odds-api-key

# Email (if implementing notifications)
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USER=your-email
SMTP_PASS=your-password
```

---

## AI Assistant Guidelines

### When Working on This Project

1. **Read Before Writing**
   - Always read existing files before modifying
   - Understand the context and patterns
   - Maintain consistency with existing code

2. **Use Todo Lists**
   - Use TodoWrite tool for multi-step tasks
   - Mark tasks as completed immediately after finishing
   - Keep only ONE task in_progress at a time

3. **Avoid Over-Engineering**
   - Only implement what's requested
   - Don't add unnecessary features
   - Keep solutions simple and focused
   - Don't add comments/docs to unchanged code

4. **Security First**
   - Never introduce vulnerabilities (XSS, SQL injection, etc.)
   - Validate all inputs
   - Use parameterized queries
   - Follow security best practices

5. **Testing**
   - Write tests for new features
   - Run existing tests before committing
   - Fix any broken tests

6. **Git Practices**
   - Work on claude/* branches
   - Commit with clear messages
   - Push with retry logic on network errors
   - Never force push to main/develop

7. **File Operations**
   - Use Read tool to read files
   - Use Edit tool to modify files
   - Use Write only for new files
   - Prefer editing over creating new files

8. **Communication**
   - Output text directly to communicate
   - Don't use bash echo or comments to talk to users
   - Include file paths with line numbers when referencing code
   - Example: `src/components/BetCard.tsx:45`

---

## Common Tasks & Patterns

### Adding a New Feature

1. Create todo list for the feature
2. Read relevant existing code
3. Implement following existing patterns
4. Write tests
5. Update documentation if needed
6. Commit with conventional commit message
7. Push to claude/* branch

### Fixing a Bug

1. Reproduce the bug
2. Read the buggy code
3. Write a failing test (if possible)
4. Fix the bug
5. Verify test passes
6. Commit with fix: prefix
7. Push changes

### Refactoring Code

1. Ensure tests exist and pass
2. Make refactoring changes
3. Verify tests still pass
4. Commit with refactor: prefix
5. Push changes

---

## Performance Considerations

### Frontend
- Lazy load routes and heavy components
- Memoize expensive calculations
- Use React.memo for frequently re-rendered components
- Optimize images and assets
- Implement virtual scrolling for large lists

### Backend
- Index database columns used in WHERE clauses
- Use connection pooling
- Implement caching for frequently accessed data
- Paginate large result sets
- Use database transactions appropriately

### Database
- Use appropriate data types
- Normalize data to reduce redundancy
- Create indexes on foreign keys
- Use database constraints for data integrity
- Regular vacuum/analyze for PostgreSQL

---

## Deployment Notes

### Pre-Deployment Checklist
- [ ] All tests passing
- [ ] Environment variables configured
- [ ] Database migrations ready
- [ ] Security headers configured
- [ ] CORS policies set
- [ ] Rate limiting enabled
- [ ] Error logging configured
- [ ] Backup strategy in place

### Production Environment
- Use production database with backups
- Enable HTTPS/SSL
- Set secure cookie flags
- Configure proper CORS
- Enable rate limiting
- Set up monitoring/alerting
- Use process manager (PM2, systemd)
- Configure reverse proxy (nginx)

---

## Useful Resources

### Documentation Links
- [React Docs](https://react.dev)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)
- [Express Guide](https://expressjs.com/en/guide/routing.html)
- [PostgreSQL Docs](https://www.postgresql.org/docs/)
- [Prisma Docs](https://www.prisma.io/docs)

### Sports Betting Concepts
- Understanding odds formats (American, Decimal, Fractional)
- Bet types: Moneyline, Spread, Totals (Over/Under)
- Advanced bets: Parlays, Teasers, Round Robins
- Bankroll management: Kelly Criterion, Unit sizing
- Expected Value (EV) calculations

---

## Troubleshooting

### Common Issues

**Database Connection Errors:**
- Check DATABASE_URL in .env
- Verify database is running
- Check network/firewall settings
- Verify credentials

**Authentication Issues:**
- Check JWT_SECRET is set
- Verify token expiration settings
- Check Authorization header format
- Verify user exists in database

**Build Failures:**
- Clear node_modules and reinstall
- Check for TypeScript errors
- Verify all dependencies are installed
- Check for syntax errors

---

## Changelog

### 2026-01-23 - Initial Creation
- Created comprehensive CLAUDE.md guide
- Defined recommended tech stack
- Outlined directory structure
- Established coding conventions
- Documented workflows and best practices

---

## Contact & Contribution

This is an AI-assisted project. When making changes:
- Follow the conventions in this document
- Update this file if conventions change
- Keep documentation in sync with code
- Ask for clarification if guidelines are unclear

---

**Note to AI Assistants**: This document should be your primary reference when working on this project. Always refer to it before making architectural decisions or establishing new patterns. Keep it updated as the project evolves.
