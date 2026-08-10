import {
  BadRequestException,
  Controller,
  Get,
  Param,
  ParseIntPipe,
  Query,
} from '@nestjs/common';
import { TmdbService } from './tmdb.service';

@Controller('movies')
export class TmdbController {
  constructor(private readonly tmdb: TmdbService) {}

  private page(value?: string) {
    const page = Number(value ?? 1);
    if (!Number.isInteger(page) || page < 1 || page > 500) {
      throw new BadRequestException(
        'Số trang phải nằm trong khoảng từ 1 đến 500',
      );
    }
    return page;
  }

  @Get('popular') popular(@Query('page') page?: string) {
    return this.tmdb.popular(this.page(page));
  }
  @Get('now-playing') nowPlaying(@Query('page') page?: string) {
    return this.tmdb.nowPlaying(this.page(page));
  }
  @Get('trending') trending() {
    return this.tmdb.trending();
  }
  @Get('search') search(
    @Query('query') query: string,
    @Query('page') page?: string,
    @Query('year') year?: string,
  ) {
    const normalizedQuery = query?.trim();
    if (!normalizedQuery) {
      throw new BadRequestException('Từ khóa tìm kiếm không được để trống');
    }
    const parsedYear = year ? Number(year) : undefined;
    if (
      parsedYear !== undefined &&
      (!Number.isInteger(parsedYear) || parsedYear < 1900 || parsedYear > 2100)
    ) {
      throw new BadRequestException('Năm phát hành không hợp lệ');
    }
    return this.tmdb.search(normalizedQuery, this.page(page), parsedYear);
  }
  @Get('discover') discover(
    @Query('page') page?: string,
    @Query('genreId') genreId?: string,
    @Query('year') year?: string,
    @Query('sortBy') sortBy?: string,
    @Query('minRating') minRating?: string,
  ) {
    const allowedSorts = [
      'popularity.desc',
      'vote_average.desc',
      'primary_release_date.desc',
    ];
    if (sortBy && !allowedSorts.includes(sortBy)) {
      throw new BadRequestException('Kiểu sắp xếp không hợp lệ');
    }
    const parsedGenre = genreId ? Number(genreId) : undefined;
    const parsedYear = year ? Number(year) : undefined;
    const parsedRating = minRating ? Number(minRating) : undefined;
    if (
      parsedGenre !== undefined &&
      (!Number.isInteger(parsedGenre) || parsedGenre < 1)
    ) {
      throw new BadRequestException('Thể loại không hợp lệ');
    }
    if (
      parsedYear !== undefined &&
      (!Number.isInteger(parsedYear) || parsedYear < 1900 || parsedYear > 2100)
    ) {
      throw new BadRequestException('Năm phát hành không hợp lệ');
    }
    if (parsedRating !== undefined && (parsedRating < 0 || parsedRating > 10)) {
      throw new BadRequestException('Điểm đánh giá phải từ 0 đến 10');
    }
    return this.tmdb.discover({
      page: this.page(page),
      genreId: parsedGenre,
      year: parsedYear,
      sortBy,
      minRating: parsedRating,
    });
  }
  @Get(':id') detail(@Param('id', ParseIntPipe) id: number) {
    return this.tmdb.detail(id);
  }
}
