import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { UserDataController } from './user-data.controller';

@Module({ imports: [AuthModule], controllers: [UserDataController] })
export class UserDataModule {}
