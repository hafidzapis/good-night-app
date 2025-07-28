# Good Night App

A Rails API for tracking sleep and viewing sleep summaries with social features.

## Features

- **Sleep Tracking**: Clock in/out sleep sessions
- **Sleep Analytics**: Daily summaries with statistics
- **Social Features**: Follow users and view their sleep reports
- **Pagination**: Efficient data handling for large datasets

## Quick Start

### Using Docker (Recommended)
```bash
docker-compose up --build
```

### Using Rails Directly
```bash
bundle install
rails db:create db:migrate
rails server
```

## API Overview

### Authentication
All endpoints require authentication via the `Authorization` header with the user's name.

### Core Endpoints

- `POST /api/v1/users` - Create user
- `POST /api/v1/sleep_records/clock_in` - Start sleep session
- `PATCH /api/v1/sleep_records/:id/clock_out` - End sleep session
- `GET /api/v1/sleep_summaries` - View personal sleep summary
- `GET /api/v1/following_sleep_summaries` - View friends' sleep reports
- `POST /api/v1/users/:id/follow` - Follow a user
- `DELETE /api/v1/users/:id/unfollow` - Unfollow a user

## Data Models

- **User**: Basic user information
- **Sleep**: Individual sleep sessions
- **DailySleepSummary**: Aggregated daily statistics
- **Follow**: User following relationships

## Testing

```bash
bundle exec rspec
```

## Technologies

- Rails 7 API
- PostgreSQL
- RSpec
- Docker

## License

MIT License
