import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { Optional } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import axios, { AxiosInstance } from 'axios';

@Injectable()
export class TmdbService {
  constructor(@Optional() private readonly prisma?: PrismaService) {}

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
    if (this.prisma) {
      try {
        const cached = await this.prisma.movieCache.findUnique({
          where: { tmdbId: id },
        });
        if (cached && cached.expiresAt > new Date())
          return cached.payload as Record<string, unknown>;
      } catch {
        // Cache is an optimization; TMDB remains the source of truth.
      }
    }
    const data = await this.get<Record<string, unknown>>(`/movie/${id}`, {
      append_to_response:
        'credits,videos,keywords,release_dates,watch/providers',
    });
    const currentVideos = (data.videos as { results?: unknown[] } | undefined)
      ?.results;
    const result = currentVideos?.length
      ? data
      : await this.withEnglishVideos(id, data);
    if (this.prisma) {
      try {
        await this.prisma.movieCache.upsert({
          where: { tmdbId: id },
          create: {
            tmdbId: id,
            payload: result as Prisma.InputJsonValue,
            expiresAt: new Date(Date.now() + 30 * 60_000),
          },
          update: {
            payload: result as Prisma.InputJsonValue,
            cachedAt: new Date(),
            expiresAt: new Date(Date.now() + 30 * 60_000),
          },
        });
      } catch {
        // Cache is an optimization; do not fail a movie request because it is unavailable.
      }
    }
    return result;
  }

  private async withEnglishVideos(id: number, data: Record<string, unknown>) {
    const apiKey = process.env.TMDB_API_KEY;
    if (!apiKey) return data;
    try {
      const response = await this.client.get<{ results?: unknown[] }>(
        `/movie/${id}/videos`,
        { params: { api_key: apiKey, language: 'en-US' } },
      );
      return { ...data, videos: response.data };
    } catch {
      return data;
    }
  }
}
