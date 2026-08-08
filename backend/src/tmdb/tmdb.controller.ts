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
      throw new BadRequestException('Số trang phải nằm trong khoảng từ 1 đến 500');
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
  ) {
    const normalizedQuery = query?.trim();
    if (!normalizedQuery) {
      throw new BadRequestException('Từ khóa tìm kiếm không được để trống');
    }
    return this.tmdb.search(normalizedQuery, this.page(page));
  }
  @Get(':id') detail(@Param('id', ParseIntPipe) id: number) {
    return this.tmdb.detail(id);
  }
}
