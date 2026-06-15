import { Module } from '@nestjs/common';
import { AdminController } from './admin.controller';
import { CardsModule } from '../cards/cards.module';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [CardsModule, AuthModule],
  controllers: [AdminController],
})
export class AdminModule {}
