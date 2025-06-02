
# HealthTrackMe

HealthTrackMe is a comprehensive health-tracking platform that enables users to monitor their fitness metrics, connect with friends, and share progress. The repository includes:

- **Core Application**: The existing backend/API for data storage and processing.
- **Social Extensions**: Modules that allow adding friends and sharing health data.
- **React Frontend**: A separate UI client showing user statistics and social interactions.

---

## Features

### Core Application
- Record and store daily health metrics (e.g., steps, calories, sleep).
- RESTful API endpoints for data access and management.
- Secure user authentication and authorization.

### Social Extensions
- Add and manage friends list.
- Share selected metrics with friends.
- View friends' public progress summaries.

### React Frontend
- Dashboard displaying health statistics in charts and tables.
- Social feed showing friends’ shared updates.
- Responsive design for desktop and mobile.

---

## Getting Started

### Prerequisites
- Node.js (v14+)
- npm 
- MongoDB / SQL (or your preferred DB)

### Clone the Repository

```bash
git clone https://github.com/SpaceJS82/HealthTrackMe.git
cd HealthTrackMe
```

### Environment Setup

Copy `.env.example` to `.env` in both `backend` and `frontend` (if available) and update variables:

```dotenv
# Example .env
DB_URI=mongodb://localhost:27017/healthtrackme
JWT_SECRET=your_jwt_secret
FRONTEND_URL=http://localhost:3000
PORT=4000
```

---

## Installation & Running

### 1. Install Backend
```bash
cd backend
npm install
npm run migrate   # (if using migrations)
npm start
```

### 2. Install React Frontend
```bash
cd frontend
npm install
npm start
```
The frontend runs on `http://localhost:3000` and consumes the API.

---

## Usage

1. Register a new user via the frontend or API.
2. Log in and add your daily health metrics.
3. Use the "Friends" tab to search and add friends.
4. Share specific metrics on your social feed.
5. View and compare your progress on the dashboard.

---

## Contributing

1. Fork the repository.
2. Create a feature branch: `git checkout -b feature/YourFeature`.
3. Commit your changes: `git commit -m "Add YourFeature description"`.
4. Push to the branch: `git push origin feature/YourFeature`.
5. Open a Pull Request.

Please adhere to the existing code style and include tests where appropriate.

---

## License

This project is licensed under the WHAT THE FITNESS License. See [LICENSE](./LICENSE) for details.

---

## Contact

For questions or feedback, open an issue or reach out to the maintainer at [SpaceJS82](https://github.com/SpaceJS82).
