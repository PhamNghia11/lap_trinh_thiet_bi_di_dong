# FLIX Backend

Backend NestJS cho ứng dụng tra cứu phim FLIX.

## Công nghệ

- NestJS REST API
- Prisma ORM
- PostgreSQL trên Supabase
- TMDB API
- JWT authentication
- Swagger, validation, rate limiting và health check

## Cài đặt

```bash
npm install
copy .env.example .env
npm run db:generate
npm run db:deploy
npm run start:dev
```

Swagger: `http://localhost:3000/api/docs`

Health check: `http://localhost:3000/api/v1/health`

## Biến môi trường

Sao chép `.env.example` thành `.env`, sau đó điền:

- `DATABASE_URL`: connection string PostgreSQL từ Supabase.
- `JWT_SECRET`: chuỗi bí mật dài và ngẫu nhiên.
- `TMDB_API_KEY`: API key của TMDB.
- `WEB_ORIGIN`: origin Flutter Web nếu sử dụng.

Không commit file `.env`.

## API hiện có

- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `GET/PATCH /api/v1/me`
- `GET /api/v1/movies/popular`
- `GET /api/v1/movies/now-playing`
- `GET /api/v1/movies/trending`
- `GET /api/v1/movies/search`
- `GET /api/v1/movies/:id`
- `GET/POST /api/v1/movies/:movieId/reviews`
- `GET/POST/DELETE /api/v1/me/favorites`
- `GET/PUT/DELETE /api/v1/me/history`

Các API `/me/*` yêu cầu Bearer JWT.
