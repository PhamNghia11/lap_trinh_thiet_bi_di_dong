import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import axios, { AxiosInstance } from 'axios';

@Injectable()
export class TmdbService {
  private readonly client: AxiosInstance = axios.create({
    baseURL: process.env.TMDB_BASE_URL ?? 'https://api.themoviedb.org/3',
    timeout: 8000,
  });

  private async get<T>(path: string, params: Record<string, unknown> = {}) {
    const apiKey = process.env.TMDB_API_KEY;
    if (!apiKey)
      throw new ServiceUnavailableException('TMDB_API_KEY chưa được cấu hình');
    try {
      const response = await this.client.get<T>(path, {
        params: { ...params, api_key: apiKey, language: 'vi-VN' },
      });
      return response.data;
    } catch {
      throw new ServiceUnavailableException(
        'Không thể kết nối dịch vụ dữ liệu phim',
      );
    }
  }

  popular(page = 1) {
    return this.get('/movie/popular', { page });
  }
  nowPlaying(page = 1) {
    return this.get('/movie/now_playing', { page });
  }
  trending() {
    return this.get('/trending/movie/week');
  }
  search(query: string, page = 1) {
    return this.get('/search/movie', { query, page, include_adult: false });
  }
  detail(id: number) {
    return this.get(`/movie/${id}`, { append_to_response: 'credits,videos' });
  }
}
