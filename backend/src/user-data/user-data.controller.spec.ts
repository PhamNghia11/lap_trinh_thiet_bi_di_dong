import { PrismaService } from '../prisma/prisma.service';
import { TmdbService } from '../tmdb/tmdb.service';
import { UserDataController } from './user-data.controller';
import { MediaStorageService } from './media-storage.service';

describe('UserDataController favorites', () => {
  const findUnique = jest.fn();
  const findMany = jest.fn();
  const upsertReview = jest.fn();
  const findManyHistory = jest.fn();
  const deleteUser = jest.fn();
  const movieDetail = jest.fn();
  const prisma = {
    favorite: { findUnique, findMany },
    review: { upsert: upsertReview },
    watchHistory: { findMany: findManyHistory },
    user: { delete: deleteUser },
  } as unknown as PrismaService;
  const tmdb = { detail: movieDetail } as unknown as TmdbService;
  const persistMedia = jest.fn((value?: string) => Promise.resolve(value));
  const removeOwnerMedia = jest.fn(() => Promise.resolve());
  const mediaStorage = {
    persist: persistMedia,
    removeOwnerMedia,
  } as unknown as MediaStorageService;
  const controller = new UserDataController(prisma, tmdb, mediaStorage);
  const user = { id: 'user-id', email: 'user@example.com' };

  beforeEach(() => {
    jest.clearAllMocks();
    persistMedia.mockImplementation((value?: string) => Promise.resolve(value));
  });

  it('returns the persisted favorite state for a movie', async () => {
    findUnique.mockResolvedValueOnce({ userId: user.id });

    await expect(controller.favoriteStatus(user, 42)).resolves.toEqual({
      isFavorite: true,
    });
    expect(findUnique).toHaveBeenCalledWith({
      where: {
        userId_tmdbMovieId: { userId: user.id, tmdbMovieId: 42 },
      },
      select: { userId: true },
    });
  });

  it('returns false when the movie is not saved', async () => {
    findUnique.mockResolvedValueOnce(null);

    await expect(controller.favoriteStatus(user, 42)).resolves.toEqual({
      isFavorite: false,
    });
  });

  it('returns favorite rows with movie metadata', async () => {
    findMany.mockResolvedValueOnce([{ userId: user.id, tmdbMovieId: 42 }]);
    movieDetail.mockResolvedValueOnce({ id: 42, title: 'Dune' });

    await expect(controller.favorites(user)).resolves.toEqual([
      {
        userId: user.id,
        tmdbMovieId: 42,
        movie: { id: 42, title: 'Dune' },
      },
    ]);
  });

  it('returns watch history rows with movie metadata', async () => {
    findManyHistory.mockResolvedValueOnce([{ userId: user.id, tmdbMovieId: 42, watchedSeconds: 120 }]);
    movieDetail.mockResolvedValueOnce({ id: 42, title: 'Dune' });

    await expect(controller.history(user)).resolves.toEqual([
      {
        userId: user.id,
        tmdbMovieId: 42,
        watchedSeconds: 120,
        movie: { id: 42, title: 'Dune' },
      },
    ]);
  });

  it('persists an optional review image', async () => {
    const dto = {
      rating: 5,
      comment: 'Great',
      imageUrl: 'data:image/jpeg;base64,abc',
    };
    upsertReview.mockResolvedValueOnce({ id: 'review-id', ...dto });

    await controller.saveReview(user, 42, dto);

    expect(upsertReview).toHaveBeenCalledWith({
      where: { userId_tmdbMovieId: { userId: user.id, tmdbMovieId: 42 } },
      create: { userId: user.id, tmdbMovieId: 42, ...dto },
      update: dto,
    });
    expect(persistMedia).toHaveBeenCalledWith(dto.imageUrl, user.id, 'review');
  });

  it('xóa tài khoản trước rồi dọn media của người dùng', async () => {
    deleteUser.mockResolvedValue({ id: user.id });

    await expect(controller.deleteAccount(user)).resolves.toEqual({
      deleted: true,
    });
    expect(deleteUser).toHaveBeenCalledWith({ where: { id: user.id } });
    expect(removeOwnerMedia).toHaveBeenCalledWith(user.id);
  });
});
