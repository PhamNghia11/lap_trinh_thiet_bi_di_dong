import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { TmdbModule } from '../tmdb/tmdb.module';
import { UserDataController } from './user-data.controller';
import { MediaStorageService } from './media-storage.service';

@Module({
  imports: [AuthModule, TmdbModule],
  controllers: [UserDataController],
  providers: [MediaStorageService],
})
export class UserDataModule {}
