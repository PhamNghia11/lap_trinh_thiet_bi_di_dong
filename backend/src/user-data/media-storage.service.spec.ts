import { ConfigService } from '@nestjs/config';
import axios from 'axios';
import { MediaStorageService } from './media-storage.service';

describe('MediaStorageService', () => {
  afterEach(() => jest.restoreAllMocks());

  it('giữ URL thông thường mà không upload lại', async () => {
    const service = new MediaStorageService(new ConfigService());
    await expect(
      service.persist(' https://example.com/avatar.jpg ', 'user-id', 'avatar'),
    ).resolves.toBe('https://example.com/avatar.jpg');
  });

  it('upload data URI lên Supabase Storage và trả URL public', async () => {
    const service = new MediaStorageService(
      new ConfigService({
        SUPABASE_URL: 'https://project.supabase.co/',
        SUPABASE_SERVICE_ROLE_KEY: 'service-key',
        SUPABASE_STORAGE_BUCKET: 'flix-media',
      }),
    );
    const upload = jest.spyOn(axios, 'put').mockResolvedValue({});
    const result = await service.persist(
      `data:image/jpeg;base64,${Buffer.from('image').toString('base64')}`,
      'user-id',
      'avatar',
    );
    const [uploadUrl, uploadBody, uploadOptions] = upload.mock.calls[0] as [
      string,
      Buffer,
      { headers: Record<string, string> },
    ];
    expect(uploadUrl).toMatch(
      /^https:\/\/project\.supabase\.co\/storage\/v1\/object\/flix-media\/user-id\/avatar\/.+\.jpg$/,
    );
    expect(uploadBody).toEqual(Buffer.from('image'));
    expect(uploadOptions.headers).toMatchObject({
      Authorization: 'Bearer service-key',
      'Content-Type': 'image/jpeg',
    });
    expect(result).toMatch(
      /^https:\/\/project\.supabase\.co\/storage\/v1\/object\/public\/flix-media\/user-id\/avatar\/.+\.jpg$/,
    );
  });

  it('production từ chối lưu base64 khi storage chưa cấu hình', async () => {
    const service = new MediaStorageService(
      new ConfigService({ NODE_ENV: 'production' }),
    );
    await expect(
      service.persist('data:image/jpeg;base64,YWJj', 'user-id', 'review'),
    ).rejects.toThrow('Object storage');
  });

  it('dọn toàn bộ object theo prefix của tài khoản', async () => {
    const service = new MediaStorageService(
      new ConfigService({
        SUPABASE_URL: 'https://project.supabase.co',
        SUPABASE_SERVICE_ROLE_KEY: 'service-key',
        SUPABASE_STORAGE_BUCKET: 'flix-media',
      }),
    );
    jest.spyOn(axios, 'post').mockImplementation((_url, body) => {
      const prefix = (body as { prefix?: string } | undefined)?.prefix;
      if (prefix?.endsWith('/avatar')) {
        return Promise.resolve({ data: [{ name: 'a.jpg' }] });
      }
      if (prefix?.endsWith('/cover')) {
        return Promise.resolve({ data: [{ name: 'c.jpg' }] });
      }
      return Promise.resolve({ data: [{ name: 'r.jpg' }] });
    });
    const remove = jest.spyOn(axios, 'delete').mockResolvedValue({});
    await service.removeOwnerMedia('user-id');
    expect(remove).toHaveBeenCalledWith(
      'https://project.supabase.co/storage/v1/object/flix-media',
      expect.objectContaining({
        data: {
          prefixes: [
            'user-id/avatar/a.jpg',
            'user-id/cover/c.jpg',
            'user-id/review/r.jpg',
          ],
        },
      }),
    );
  });
});
