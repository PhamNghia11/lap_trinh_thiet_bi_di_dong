import { TmdbService } from './tmdb.service';

describe('TmdbService', () => {
  const originalApiKey = process.env.TMDB_API_KEY;

  afterEach(() => {
    process.env.TMDB_API_KEY = originalApiKey;
    jest.restoreAllMocks();
  });

  it('dùng video tiếng Anh khi bản chi tiết tiếng Việt không có trailer', async () => {
    process.env.TMDB_API_KEY = 'test-key';
    const service = new TmdbService();
    const client = (
      service as unknown as {
        client: { get: jest.Mock };
      }
    ).client;
    client.get = jest
      .fn()
      .mockResolvedValueOnce({
        data: {
          id: 1,
          videos: { results: [] },
          reviews: { results: [{ id: 'vi-review' }] },
        },
      })
      .mockResolvedValueOnce({
        data: {
          results: [{ site: 'YouTube', type: 'Trailer', key: 'trailer-key' }],
        },
      });

    const result = await service.detail(1);

    expect(client.get).toHaveBeenCalledTimes(2);
    expect(client.get).toHaveBeenLastCalledWith('/movie/1/videos', {
      params: { api_key: 'test-key', language: 'en-US' },
    });
    expect(
      (result.videos as { results: Array<{ key: string }> }).results[0].key,
    ).toBe('trailer-key');
  });

  it('giữ video tiếng Việt khi TMDB đã trả dữ liệu', async () => {
    process.env.TMDB_API_KEY = 'test-key';
    const service = new TmdbService();
    const client = (
      service as unknown as {
        client: { get: jest.Mock };
      }
    ).client;
    client.get = jest.fn().mockResolvedValue({
      data: {
        id: 1,
        videos: {
          results: [{ site: 'YouTube', type: 'Trailer', key: 'vi-key' }],
        },
        reviews: { results: [{ id: 'vi-review' }] },
      },
    });

    const result = await service.detail(1);

    expect(client.get).toHaveBeenCalledTimes(1);
    expect(client.get).toHaveBeenCalledWith('/movie/1', {
      params: {
        append_to_response:
          'credits,videos,keywords,reviews,release_dates,watch/providers',
        api_key: 'test-key',
        language: 'vi-VN',
      },
    });
    expect(
      (result.videos as { results: Array<{ key: string }> }).results[0].key,
    ).toBe('vi-key');
  });

  it('dùng review mặc định của TMDB khi bản tiếng Việt không có bình luận', async () => {
    process.env.TMDB_API_KEY = 'test-key';
    const service = new TmdbService();
    const client = (
      service as unknown as {
        client: { get: jest.Mock };
      }
    ).client;
    client.get = jest
      .fn()
      .mockResolvedValueOnce({
        data: {
          id: 1,
          videos: { results: [{ key: 'vi-key' }] },
          reviews: { page: 1, results: [], total_results: 0 },
        },
      })
      .mockResolvedValueOnce({
        data: {
          page: 1,
          results: [{ author: 'TMDB user', content: 'Real review' }],
          total_results: 1,
        },
      });

    const result = await service.detail(1);

    expect(client.get).toHaveBeenCalledTimes(2);
    expect(client.get).toHaveBeenLastCalledWith('/movie/1/reviews', {
      params: { api_key: 'test-key' },
    });
    expect(
      (result.reviews as { results: Array<{ author: string }> }).results[0]
        .author,
    ).toBe('TMDB user');
  });
});
