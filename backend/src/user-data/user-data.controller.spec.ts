import { PrismaService } from '../prisma/prisma.service';
import { TmdbService } from '../tmdb/tmdb.service';
import { UserDataController } from './user-data.controller';

describe('UserDataController favorites', () => {
  const findUnique = jest.fn();
  const findMany = jest.fn();
  const upsertReview = jest.fn();
  const movieDetail = jest.fn();
  const prisma = {
    favorite: { findUnique, findMany },
    review: { upsert: upsertReview },
  } as unknown as PrismaService;
  const tmdb = { detail: movieDetail } as unknown as TmdbService;
  const controller = new UserDataController(prisma, tmdb);
  const user = { id: 'user-id', email: 'user@example.com' };

  beforeEach(() => jest.clearAllMocks());

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
  });
});
