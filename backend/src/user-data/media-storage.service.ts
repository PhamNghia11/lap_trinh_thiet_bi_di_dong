import {
  BadRequestException,
  Injectable,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';
import { randomUUID } from 'crypto';

type MediaKind = 'avatar' | 'cover' | 'review';

@Injectable()
export class MediaStorageService {
  constructor(private readonly config: ConfigService) {}

  async persist(value: string | undefined, ownerId: string, kind: MediaKind) {
    if (value === undefined) return undefined;
    const trimmed = value.trim();
    if (!trimmed.startsWith('data:image/')) return trimmed;

    const parsed = this.parseDataUri(trimmed, kind);
    const storage = this.storageConfig();
    if (!storage) {
      if (this.config.get<string>('NODE_ENV') === 'production') {
        throw new ServiceUnavailableException(
          'Object storage chưa được cấu hình trên máy chủ',
        );
      }
      return trimmed;
    }

    const extension = parsed.contentType.split('/')[1].replace('jpeg', 'jpg');
    const objectPath = `${ownerId}/${kind}/${randomUUID()}.${extension}`;
    await axios.put(
      `${storage.url}/storage/v1/object/${storage.bucket}/${objectPath}`,
      parsed.bytes,
      {
        timeout: 15_000,
        headers: {
          apikey: storage.serviceRoleKey,
          Authorization: `Bearer ${storage.serviceRoleKey}`,
          'Content-Type': parsed.contentType,
          'x-upsert': 'false',
        },
      },
    );
    return `${storage.url}/storage/v1/object/public/${storage.bucket}/${objectPath}`;
  }

  async removeOwnerMedia(ownerId: string) {
    const storage = this.storageConfig();
    if (!storage) return;
    try {
      const groups = await Promise.all(
        (['avatar', 'cover', 'review'] as const).map(async (kind) => {
          const response = await axios.post<Array<{ name?: string }>>(
            `${storage.url}/storage/v1/object/list/${storage.bucket}`,
            { prefix: `${ownerId}/${kind}`, limit: 1000 },
            { timeout: 15_000, headers: this.storageHeaders(storage) },
          );
          return response.data
            .map((object) => object.name)
            .filter((name): name is string => Boolean(name))
            .map((name) => `${ownerId}/${kind}/${name}`);
        }),
      );
      const objectNames = groups.flat();
      if (objectNames.length === 0) return;
      await axios.delete(`${storage.url}/storage/v1/object/${storage.bucket}`, {
        timeout: 15_000,
        headers: this.storageHeaders(storage),
        data: { prefixes: objectNames },
      });
    } catch (error: unknown) {
      console.error('Không thể xóa media của tài khoản', {
        ownerId,
        error: error instanceof Error ? error.message : String(error),
      });
    }
  }

  private storageHeaders(storage: { serviceRoleKey: string }) {
    return {
      apikey: storage.serviceRoleKey,
      Authorization: `Bearer ${storage.serviceRoleKey}`,
      'Content-Type': 'application/json',
    };
  }

  private parseDataUri(value: string, kind: MediaKind) {
    const match =
      /^data:(image\/(?:jpeg|png|webp));base64,([A-Za-z0-9+/=]+)$/.exec(value);
    if (!match) throw new BadRequestException('Dữ liệu ảnh không hợp lệ');
    const bytes = Buffer.from(match[2], 'base64');
    const maxBytes = kind === 'cover' ? 2_000_000 : 1_500_000;
    if (bytes.length === 0 || bytes.length > maxBytes) {
      throw new BadRequestException('Ảnh vượt quá dung lượng cho phép');
    }
    return { contentType: match[1], bytes };
  }

  private storageConfig() {
    const url = this.config
      .get<string>('SUPABASE_URL')
      ?.trim()
      .replace(/\/$/, '');
    const serviceRoleKey = this.config
      .get<string>('SUPABASE_SERVICE_ROLE_KEY')
      ?.trim();
    const bucket = this.config
      .get<string>('SUPABASE_STORAGE_BUCKET', 'flix-media')
      .trim();
    if (!url || !serviceRoleKey || !bucket) return null;
    return { url, serviceRoleKey, bucket };
  }
}
