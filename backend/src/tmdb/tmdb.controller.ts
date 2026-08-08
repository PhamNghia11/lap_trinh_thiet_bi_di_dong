import { Controller, Get, Param, ParseIntPipe, Query } from '@nestjs/common';
import { TmdbService } from './tmdb.service';

@Controller('movies')
export class TmdbController {
  constructor(private readonly tmdb: TmdbService) {}

  @Get('popular') popular(@Query('page') page?: string) {
    return this.tmdb.popular(Number(page ?? 1));
  }
  @Get('now-playing') nowPlaying(@Query('page') page?: string) {
    return this.tmdb.nowPlaying(Number(page ?? 1));
  }
  @Get('trending') trending() {
    return this.tmdb.trending();
  }
  @Get('search') search(
    @Query('query') query: string,
    @Query('page') page?: string,
  ) {
    return this.tmdb.search(query, Number(page ?? 1));
  }
  @Get(':id') detail(@Param('id', ParseIntPipe) id: number) {
    return this.tmdb.detail(id);
  }
}
