import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { Optional } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import axios, { AxiosInstance } from 'axios';

const REVIEW_FALLBACK_CACHE_VERSION = 1;
const REVIEW_FALLBACK_CACHE_KEY = '_flixReviewFallbackVersion';

@Injectable()
export class TmdbService {
  constructor(@Optional() private readonly prisma?: PrismaService) {}

  private readonly client: AxiosInstance = axios.create({
    baseURL: process.env.TMDB_BASE_URL ?? 'https://api.themoviedb.org/3',
    timeout: 8000,
  });

  async image(size: string, file: string) {
    const response = await axios.get<Buffer>(
      `https://image.tmdb.org/t/p/${size}/${file}`,
      { responseType: 'arraybuffer', timeout: 8000 },
    );
    const contentType = response.headers['content-type'];
    if (typeof contentType !== 'string' || !contentType.startsWith('image/')) {
      throw new ServiceUnavailableException(
        'TMDB không trả về dữ liệu ảnh hợp lệ',
      );
    }
    return { data: Buffer.from(response.data), contentType };
  }

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
        const payload = cached?.payload as Record<string, unknown> | undefined;
        const hasCurrentReviewFallback =
          payload?.[REVIEW_FALLBACK_CACHE_KEY] ===
          REVIEW_FALLBACK_CACHE_VERSION;
        if (
          cached &&
          cached.expiresAt > new Date() &&
          hasCurrentReviewFallback
        ) {
          const publicPayload = { ...payload };
          delete publicPayload[REVIEW_FALLBACK_CACHE_KEY];
          return publicPayload;
        }
      } catch {
        // Cache is an optimization; TMDB remains the source of truth.
      }
    }
    const data = await this.get<Record<string, unknown>>(`/movie/${id}`, {
      append_to_response:
        'credits,videos,keywords,reviews,release_dates,watch/providers',
    });
    const currentVideos = (data.videos as { results?: unknown[] } | undefined)
      ?.results;
    const dataWithVideos = currentVideos?.length
      ? data
      : await this.withEnglishVideos(id, data);
    const result = await this.withDefaultReviews(id, dataWithVideos);
    if (this.prisma) {
      try {
        const cachePayload = {
          ...result,
          [REVIEW_FALLBACK_CACHE_KEY]: REVIEW_FALLBACK_CACHE_VERSION,
        };
        await this.prisma.movieCache.upsert({
          where: { tmdbId: id },
          create: {
            tmdbId: id,
            payload: cachePayload,
            expiresAt: new Date(Date.now() + 30 * 60_000),
          },
          update: {
            payload: cachePayload,
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

  private async withDefaultReviews(id: number, data: Record<string, unknown>) {
    const currentReviews = (data.reviews as { results?: unknown[] } | undefined)
      ?.results;
    if (currentReviews?.length) return data;

    const apiKey = process.env.TMDB_API_KEY;
    if (!apiKey) return data;
    try {
      const response = await this.client.get<{ results?: unknown[] }>(
        `/movie/${id}/reviews`,
        { params: { api_key: apiKey } },
      );
      return { ...data, reviews: response.data };
    } catch {
      return data;
    }
  }
}
