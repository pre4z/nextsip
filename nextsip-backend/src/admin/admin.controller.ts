import { Body, Controller, Get, Param, Patch, UseGuards } from '@nestjs/common';
import { CardsService } from '../cards/cards.service';
import { UpdateBalanceDto } from '../cards/dto/update-balance.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@UseGuards(JwtAuthGuard)
@Controller('admin')
export class AdminController {
  constructor(private readonly cardsService: CardsService) {}

  /** Liste over alle kort med saldo */
  @Get('cards')
  getCards() {
    return this.cardsService.getAllCards();
  }

  /** ordre oversigt */
  @Get('transactions')
  getTransactions() {
    return this.cardsService.getAllTransactions();
  }

  /** saet saldo paa en kort man kan vaelge */
  @Patch('cards/:uid')
  async setBalance(@Param('uid') uid: string, @Body() dto: UpdateBalanceDto) {
    const balance = await this.cardsService.setBalance(uid, dto.balance);
    return { uid, balance };
  }
}
