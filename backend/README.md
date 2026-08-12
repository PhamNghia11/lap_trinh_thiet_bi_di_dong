# FLIX Backend

Backend NestJS cho ứng dụng tra cứu phim FLIX.

## Công nghệ

- NestJS REST API
- Prisma ORM
- PostgreSQL trên Supabase
- TMDB API
- JWT authentication và Google/Facebook OAuth
- Swagger, validation, rate limiting và health check

## Cài đặt

```bash
npm install
copy .env.example .env
npm run db:generate
npm run db:deploy
npm run start:dev
```

Swagger local: `http://localhost:3000/api/docs`. Ở production Swagger mặc định
tắt; chỉ đặt `ENABLE_SWAGGER=true` khi thực sự cần mở tài liệu API.

Health check: `http://localhost:3000/api/v1/health`

## Biến môi trường

Sao chép `.env.example` thành `.env`, sau đó điền:

- `DATABASE_URL`: connection string PostgreSQL từ Supabase.
- `JWT_SECRET`: chuỗi bí mật dài và ngẫu nhiên.
- `TMDB_API_KEY`: API key của TMDB.
- `WEB_ORIGIN`: origin Flutter Web nếu sử dụng.
- `PUBLIC_API_URL`: URL public của backend, không gồm `/api/v1`.
- `OAUTH_RETURN_URL`: route Flutter Web nhận kết quả đăng nhập social.
- `ENABLE_SWAGGER`: bật Swagger; production mặc định tắt nếu không đặt `true`.
- `SUPABASE_URL`: URL project Supabase dùng cho Storage.
- `SUPABASE_SERVICE_ROLE_KEY`: service role key, chỉ lưu ở backend/Render.
- `SUPABASE_STORAGE_BUCKET`: bucket public chứa media, mặc định `flix-media`.
- `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`: OAuth Web credentials từ Google.
- `FACEBOOK_APP_ID`, `FACEBOOK_APP_SECRET`: thông tin Facebook Login app.
- `FACEBOOK_GRAPH_VERSION`: phiên bản Graph API đang bật cho Facebook app.
- `BREVO_API_KEY`: API key gửi email khôi phục mật khẩu qua Brevo.
- `BREVO_SENDER_EMAIL`: địa chỉ người gửi đã xác minh trên Brevo.
- `BREVO_SENDER_NAME`: tên người gửi hiển thị, mặc định là `FLIX`.

Callback URL cần đăng ký với provider:

- Google: `<PUBLIC_API_URL>/api/v1/auth/oauth/google/callback`
- Facebook: `<PUBLIC_API_URL>/api/v1/auth/oauth/facebook/callback`. Meta tự
  cho phép `http://localhost` khi app ở Development mode, nên không thêm URL
  localhost vào `Valid OAuth Redirect URIs`; chỉ thêm callback HTTPS khi app
  được triển khai lên domain thật.

Không commit file `.env`.

## API hiện có

- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `POST /api/v1/auth/password/forgot`
- `POST /api/v1/auth/password/reset`
- `GET /api/v1/auth/oauth/providers`
- `GET /api/v1/auth/oauth/:provider/url`
- `GET /api/v1/auth/oauth/:provider/callback`
- `GET/PATCH /api/v1/me` (họ tên, avatar và ảnh bìa)
- `DELETE /api/v1/me` (xóa tài khoản và dữ liệu liên quan)
- `GET /api/v1/me/reviews`
- `GET /api/v1/movies/popular`
- `GET /api/v1/movies/now-playing`
- `GET /api/v1/movies/trending`
- `GET /api/v1/movies/search`
- `GET /api/v1/movies/:id`
- `GET/POST /api/v1/movies/:movieId/reviews`
- `GET/POST/DELETE /api/v1/me/favorites`
- `GET/PUT/DELETE /api/v1/me/history`

Các API `/me/*` yêu cầu Bearer JWT.

Ảnh hồ sơ được Flutter crop và nén trước khi gửi. Backend chấp nhận JSON tối đa
3 MB cho luồng này; không tăng giới hạn nếu chưa có kiểm tra kích thước tương
ứng ở client và DTO.
