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
      .mockResolvedValueOnce({ data: { id: 1, videos: { results: [] } } })
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
      },
    });

    const result = await service.detail(1);

    expect(client.get).toHaveBeenCalledTimes(1);
    expect(
      (result.videos as { results: Array<{ key: string }> }).results[0].key,
    ).toBe('vi-key');
  });
});
