import { TmdbController } from './tmdb.controller';
import type { Response } from 'express';

type MockResponse = {
  status: jest.Mock;
  json: jest.Mock;
  setHeader: jest.Mock;
  send: jest.Mock;
};

describe('TmdbController image proxy', () => {
  const service = { image: jest.fn() };
  const controller = new TmdbController(service as never);

  afterEach(() => jest.clearAllMocks());

  const response = (): MockResponse => {
    const result = {
      status: jest.fn(),
      json: jest.fn(),
      setHeader: jest.fn(),
      send: jest.fn(),
    } satisfies MockResponse;
    result.status.mockReturnValue(result);
    result.setHeader.mockReturnValue(result);
    return result;
  };

  it('rejects unsafe path values before calling TMDB', async () => {
    const res = response();
    await controller.image('original', '../secret', res as unknown as Response);
    expect(res.status).toHaveBeenCalledWith(400);
    expect(service.image).not.toHaveBeenCalled();
  });

  it('returns cached image bytes with the upstream content type', async () => {
    const res = response();
    service.image.mockResolvedValue({
      data: Buffer.from('image'),
      contentType: 'image/jpeg',
    });
    await controller.image('w500', 'poster.jpg', res as unknown as Response);
    expect(service.image).toHaveBeenCalledWith('w500', 'poster.jpg');
    expect(res.setHeader).toHaveBeenCalledWith('Content-Type', 'image/jpeg');
    expect(res.setHeader).toHaveBeenCalledWith(
      'Cache-Control',
      'public, max-age=86400, stale-while-revalidate=604800',
    );
    expect(res.send).toHaveBeenCalledWith(Buffer.from('image'));
  });
});
