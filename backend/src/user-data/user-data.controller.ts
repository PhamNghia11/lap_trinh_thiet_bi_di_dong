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
import { HistoryDto, ReviewDto, UpdateProfileDto } from './user-data.dto';

@Controller()
export class UserDataController {
  constructor(private readonly prisma: PrismaService) {}

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
  updateProfile(@CurrentUser() user: AuthUser, @Body() dto: UpdateProfileDto) {
    return this.prisma.user.update({
      where: { id: user.id },
      data: {
        ...(dto.fullName !== undefined && { fullName: dto.fullName.trim() }),
        ...(dto.avatarUrl !== undefined && { avatarUrl: dto.avatarUrl.trim() }),
        ...(dto.avatarUrl !== undefined && { avatarCustomized: true }),
        ...(dto.coverUrl !== undefined && { coverUrl: dto.coverUrl.trim() }),
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
  favorites(@CurrentUser() user: AuthUser) {
    return this.prisma.favorite.findMany({
      where: { userId: user.id },
      orderBy: { createdAt: 'desc' },
    });
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
  history(@CurrentUser() user: AuthUser) {
    return this.prisma.watchHistory.findMany({
      where: { userId: user.id },
      orderBy: { lastWatchedAt: 'desc' },
    });
  }

  @UseGuards(AuthGuard('jwt'))
  @Get('me/reviews')
  myReviews(@CurrentUser() user: AuthUser) {
    return this.prisma.review.findMany({
      where: { userId: user.id },
      orderBy: { updatedAt: 'desc' },
    });
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
  saveReview(
    @CurrentUser() user: AuthUser,
    @Param('movieId', ParseIntPipe) movieId: number,
    @Body() dto: ReviewDto,
  ) {
    return this.prisma.review.upsert({
      where: { userId_tmdbMovieId: { userId: user.id, tmdbMovieId: movieId } },
      create: { userId: user.id, tmdbMovieId: movieId, ...dto },
      update: dto,
    });
  }

  @UseGuards(AuthGuard('jwt'))
  @Delete('reviews/:id')
  deleteReview(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.prisma.review.deleteMany({ where: { id, userId: user.id } });
  }
}
