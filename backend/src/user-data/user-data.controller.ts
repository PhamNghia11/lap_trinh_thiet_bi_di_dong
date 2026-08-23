import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Patch,
  Post,
  Put,
  UseGuards,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthUser } from '../auth/current-user.decorator';
import { PrismaService } from '../prisma/prisma.service';
import { TmdbService } from '../tmdb/tmdb.service';
import { HistoryDto, ReviewDto, UpdateProfileDto } from './user-data.dto';
import { MediaStorageService } from './media-storage.service';

@Controller()
export class UserDataController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly tmdb: TmdbService,
    private readonly mediaStorage: MediaStorageService,
  ) {}

  @UseGuards(AuthGuard('jwt'))
  @Get('me')
  profile(@CurrentUser() user: AuthUser) {
    return this.prisma.user.findUnique({
      where: { id: user.id },
      select: {
        id: true,
        email: true,
        fullName: true,
        avatarUrl: true,
        coverUrl: true,
        createdAt: true,
        _count: { select: { favorites: true, history: true, reviews: true } },
      },
    });
  }

  @UseGuards(AuthGuard('jwt'))
  @Patch('me')
  async updateProfile(
    @CurrentUser() user: AuthUser,
    @Body() dto: UpdateProfileDto,
  ) {
    const [avatarUrl, coverUrl] = await Promise.all([
      this.mediaStorage.persist(dto.avatarUrl, user.id, 'avatar'),
      this.mediaStorage.persist(dto.coverUrl, user.id, 'cover'),
    ]);
    return this.prisma.user.update({
      where: { id: user.id },
      data: {
        ...(dto.fullName !== undefined && { fullName: dto.fullName.trim() }),
        ...(avatarUrl !== undefined && { avatarUrl }),
        ...(dto.avatarUrl !== undefined && { avatarCustomized: true }),
        ...(coverUrl !== undefined && { coverUrl }),
      },
      select: {
        id: true,
        email: true,
        fullName: true,
        avatarUrl: true,
        coverUrl: true,
        createdAt: true,
        _count: { select: { favorites: true, history: true, reviews: true } },
      },
    });
  }

  @Get('movies/:movieId/reviews')
  reviews(@Param('movieId', ParseIntPipe) movieId: number) {
    return this.prisma.review.findMany({
      where: { tmdbMovieId: movieId },
      include: {
        user: { select: { id: true, fullName: true, avatarUrl: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  @UseGuards(AuthGuard('jwt'))
  @Get('me/favorites')
  async favorites(@CurrentUser() user: AuthUser) {
    const favorites = await this.prisma.favorite.findMany({
      where: { userId: user.id },
      orderBy: { createdAt: 'desc' },
    });
    const movies = new Map(
      await Promise.all(
        [...new Set(favorites.map(({ tmdbMovieId }) => tmdbMovieId))].map(
          async (movieId) =>
            [movieId, await this.tmdb.detail(movieId)] as const,
        ),
      ),
    );
    return favorites.map((favorite) => ({
      ...favorite,
      movie: movies.get(favorite.tmdbMovieId),
    }));
  }

  @UseGuards(AuthGuard('jwt'))
  @Get('me/favorites/:movieId/status')
  async favoriteStatus(
    @CurrentUser() user: AuthUser,
    @Param('movieId', ParseIntPipe) movieId: number,
  ) {
    const favorite = await this.prisma.favorite.findUnique({
      where: { userId_tmdbMovieId: { userId: user.id, tmdbMovieId: movieId } },
      select: { userId: true },
    });
    return { isFavorite: favorite !== null };
  }

  @UseGuards(AuthGuard('jwt'))
  @Post('me/favorites/:movieId')
  addFavorite(
    @CurrentUser() user: AuthUser,
    @Param('movieId', ParseIntPipe) movieId: number,
  ) {
    return this.prisma.favorite.upsert({
      where: { userId_tmdbMovieId: { userId: user.id, tmdbMovieId: movieId } },
      create: { userId: user.id, tmdbMovieId: movieId },
      update: {},
    });
  }

  @UseGuards(AuthGuard('jwt'))
  @Delete('me')
  async deleteAccount(@CurrentUser() user: AuthUser) {
    await this.prisma.user.delete({ where: { id: user.id } });
    await this.mediaStorage.removeOwnerMedia(user.id);
    return { deleted: true };
  }

  @UseGuards(AuthGuard('jwt'))
  @Delete('me/favorites/:movieId')
  removeFavorite(
    @CurrentUser() user: AuthUser,
    @Param('movieId', ParseIntPipe) movieId: number,
  ) {
    return this.prisma.favorite.deleteMany({
      where: { userId: user.id, tmdbMovieId: movieId },
    });
  }

  @UseGuards(AuthGuard('jwt'))
  @Get('me/history')
  async history(@CurrentUser() user: AuthUser) {
    const history = await this.prisma.watchHistory.findMany({
      where: { userId: user.id },
      orderBy: { lastWatchedAt: 'desc' },
    });
    const movies = new Map(
      await Promise.all(
        [...new Set(history.map(({ tmdbMovieId }) => tmdbMovieId))].map(
          async (movieId) => {
            try {
              return [movieId, await this.tmdb.detail(movieId)] as const;
            } catch {
              return [movieId, null] as const;
            }
          },
        ),
      ),
    );
    return history.map((item) => ({
      ...item,
      movie: movies.get(item.tmdbMovieId),
    }));
  }

  @UseGuards(AuthGuard('jwt'))
  @Get('me/reviews')
  async myReviews(@CurrentUser() user: AuthUser) {
    const reviews = await this.prisma.review.findMany({
      where: { userId: user.id },
      orderBy: { updatedAt: 'desc' },
    });
    const movies = new Map(
      await Promise.all(
        [...new Set(reviews.map(({ tmdbMovieId }) => tmdbMovieId))].map(
          async (movieId) =>
            [movieId, await this.tmdb.detail(movieId)] as const,
        ),
      ),
    );
    return reviews.map((review) => ({
      ...review,
      movie: movies.get(review.tmdbMovieId),
    }));
  }

  @UseGuards(AuthGuard('jwt'))
  @Put('me/history/:movieId')
  saveHistory(
    @CurrentUser() user: AuthUser,
    @Param('movieId', ParseIntPipe) movieId: number,
    @Body() dto: HistoryDto,
  ) {
    return this.prisma.watchHistory.upsert({
      where: { userId_tmdbMovieId: { userId: user.id, tmdbMovieId: movieId } },
      create: { userId: user.id, tmdbMovieId: movieId, ...dto },
      update: { ...dto, lastWatchedAt: new Date() },
    });
  }

  @UseGuards(AuthGuard('jwt'))
  @Delete('me/history')
  clearHistory(@CurrentUser() user: AuthUser) {
    return this.prisma.watchHistory.deleteMany({ where: { userId: user.id } });
  }

  @UseGuards(AuthGuard('jwt'))
  @Delete('me/history/:movieId')
  removeHistory(
    @CurrentUser() user: AuthUser,
    @Param('movieId', ParseIntPipe) movieId: number,
  ) {
    return this.prisma.watchHistory.deleteMany({
      where: { userId: user.id, tmdbMovieId: movieId },
    });
  }

  @UseGuards(AuthGuard('jwt'))
  @Post('movies/:movieId/reviews')
  async saveReview(
    @CurrentUser() user: AuthUser,
    @Param('movieId', ParseIntPipe) movieId: number,
    @Body() dto: ReviewDto,
  ) {
    const imageUrl = await this.mediaStorage.persist(
      dto.imageUrl,
      user.id,
      'review',
    );
    const data = { ...dto, ...(imageUrl !== undefined && { imageUrl }) };
    return this.prisma.review.upsert({
      where: { userId_tmdbMovieId: { userId: user.id, tmdbMovieId: movieId } },
      create: { userId: user.id, tmdbMovieId: movieId, ...data },
      update: data,
    });
  }

  @UseGuards(AuthGuard('jwt'))
  @Delete('reviews/:id')
  deleteReview(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.prisma.review.deleteMany({ where: { id, userId: user.id } });
  }
}
