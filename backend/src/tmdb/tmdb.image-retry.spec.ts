import axios from 'axios';
import { TmdbService } from './tmdb.service';

describe('TmdbService image reliability', () => {
  afterEach(() => jest.restoreAllMocks());

  it('retries one transient image failure', async () => {
    const request = jest
      .spyOn(axios, 'get')
      .mockRejectedValueOnce(new Error('temporary upstream failure'))
      .mockResolvedValueOnce({
        data: Buffer.from('image'),
        headers: { 'content-type': 'image/jpeg' },
      });

    await expect(
      new TmdbService().image('w500', 'poster.jpg'),
    ).resolves.toEqual({
      data: Buffer.from('image'),
      contentType: 'image/jpeg',
    });
    expect(request).toHaveBeenCalledTimes(2);
  });

  it('stops after the second upstream failure', async () => {
    const request = jest
      .spyOn(axios, 'get')
      .mockRejectedValue(new Error('upstream unavailable'));

    await expect(new TmdbService().image('w500', 'poster.jpg')).rejects.toThrow(
      'upstream unavailable',
    );
    expect(request).toHaveBeenCalledTimes(2);
  });

  it('does not retry a permanent upstream response', async () => {
    const error = Object.assign(new Error('not found'), {
      isAxiosError: true,
      response: { status: 404 },
    });
    const request = jest.spyOn(axios, 'get').mockRejectedValue(error);

    await expect(
      new TmdbService().image('w500', 'missing.jpg'),
    ).rejects.toThrow('not found');
    expect(request).toHaveBeenCalledTimes(1);
  });
});
