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
  search(query: string, page = 1, year?: number) {
    return this.get('/search/movie', {
      query,
      page,
      include_adult: false,
      ...(year && { primary_release_year: year }),
    });
  }
  discover(options: {
    page?: number;
    genreId?: number;
    year?: number;
    sortBy?: string;
    minRating?: number;
  }) {
    return this.get('/discover/movie', {
      page: options.page ?? 1,
      include_adult: false,
      include_video: false,
      sort_by: options.sortBy ?? 'popularity.desc',
      ...(options.genreId && { with_genres: options.genreId }),
      ...(options.year && { primary_release_year: options.year }),
      ...(options.minRating && { 'vote_average.gte': options.minRating }),
      'vote_count.gte': 50,
    });
  }
  async detail(id: number) {
    const data = await this.get<Record<string, unknown>>(`/movie/${id}`, {
      append_to_response:
        'credits,videos,keywords,release_dates,watch/providers',
    });
    const currentVideos = (data.videos as { results?: unknown[] } | undefined)
      ?.results;
    if (currentVideos?.length) return data;

    const apiKey = process.env.TMDB_API_KEY;
    if (!apiKey) return data;
    try {
      const response = await this.client.get(`/movie/${id}/videos`, {
        params: { api_key: apiKey, language: 'en-US' },
      });
      return { ...data, videos: response.data };
    } catch {
      return data;
    }
  }
}
