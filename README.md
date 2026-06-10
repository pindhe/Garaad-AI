# MacallinAI – Autonomous AI Teacher System

A production-ready, full-stack AI-powered education platform with three components:

| Component | Stack | Purpose |
|-----------|-------|---------|
| **Backend API** | Node.js, Express, MySQL | REST API, JWT auth, OpenAI integration |
| **Admin Dashboard** | Next.js, Tailwind CSS | Course/student management, AI control, analytics |
| **Student App** | Flutter (Android + iOS) | Learning, AI chat, quizzes, certificates |

## Architecture

```
┌─────────────────┐     ┌─────────────────┐
│  Flutter App    │     │  Next.js Admin  │
│  (Students)     │     │  (Admins)       │
└────────┬────────┘     └────────┬────────┘
         │                       │
         └───────────┬───────────┘
                     │ REST API (JWT)
              ┌──────▼──────┐
              │  Express.js │
              │  + OpenAI   │
              └──────┬──────┘
                     │
              ┌──────▼──────┐
              │    MySQL    │
              └─────────────┘
```

## Quick Start

### Prerequisites

- Node.js 18+
- MySQL 8+
- Flutter 3.10+
- OpenAI API key

### 1. Backend

```bash
cd backend
cp .env.example .env
# Edit .env with your MySQL credentials and OPENAI_API_KEY

npm install
npm run db:init          # Create database & tables
node scripts/seed-admin.js   # Creates admin@macallinai.com / admin123

npm run dev              # http://localhost:5000
```

### 2. Admin Dashboard

```bash
cd admin
cp .env.local.example .env.local

npm install
npm run dev              # http://localhost:3000
```

Login with the seeded admin credentials.

### 3. Flutter Mobile App

```bash
cd mobile
flutter pub get
flutter run              # Use 10.0.2.2:5000 for Android emulator
```

For a physical device, set the API URL:

```bash
flutter run --dart-define=API_URL=http://YOUR_IP:5000
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/register` | Register student |
| POST | `/auth/login` | Login (returns JWT) |
| GET | `/auth/me` | Current user profile |
| GET | `/courses` | List courses |
| POST | `/courses/:id/enroll` | Enroll in course |
| GET | `/lessons/:id` | Get lesson content |
| POST | `/ai/chat` | AI teacher chat |
| POST | `/ai/generate-course` | AI course generation |
| POST | `/ai/generate-quiz` | AI quiz generation |
| POST | `/ai/grade` | AI auto-grading |
| GET | `/analytics/dashboard` | Admin dashboard stats |

## User Roles

- **Admin** – Full control via web dashboard (students, courses, AI toggle, analytics)
- **Student** – Mobile app (learn, chat with AI, take quizzes/exams)
- **AI Teacher** – Autonomous system powered by OpenAI (teaching, content generation, grading)

## Database Tables

`users`, `students`, `admins`, `courses`, `subjects`, `lessons`, `quizzes`, `quiz_results`, `assignments`, `submissions`, `exams`, `exam_results`, `certificates`, `ai_chats`, `ai_logs`, `notifications`, `subscriptions`, `payments`, `analytics`, `system_settings`

## Deployment

| Component | Platform |
|-----------|----------|
| Admin Dashboard | Vercel |
| Backend API | VPS (Ubuntu 22/24) + PM2 |
| Database | MySQL |
| Mobile App | Google Play / App Store |

## Security

- JWT authentication with bcrypt password hashing
- Role-based access control (admin / student)
- Rate limiting on auth and AI endpoints
- Input validation via express-validator
- Secure file upload with type/size restrictions

## License

MIT
