import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { TmdbModule } from '../tmdb/tmdb.module';
import { UserDataController } from './user-data.controller';

@Module({
  imports: [AuthModule, TmdbModule],
  controllers: [UserDataController],
})
export class UserDataModule {}
