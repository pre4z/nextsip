import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { CardsService } from './cards.service';
import { AddTransactionDto } from './dto/add-transaction.dto';

@Controller('cards')
export class CardsController {
  constructor(private readonly cardsService: CardsService) {}

  /**
   * spoerg efter saldo
   */
  @Get(':uid')
  async getBalance(@Param('uid') uid: string) {
    const balance = await this.cardsService.ensureCard(uid);
    return { uid, balance };
  }

  /**
   * registrer udgivning
   */
  @Post(':uid/transactions')
  async addTransaction(@Param('uid') uid: string, @Body() dto: AddTransactionDto) {
    const balance = await this.cardsService.addTransaction(uid, dto.item, dto.price);
    return { uid, balance };
  }

  /**
   * proof of concept til betaling
   */
  @Post(':uid/pay')
  async pay(@Param('uid') uid: string) {
    const balance = await this.cardsService.payBalance(uid);
    return { uid, balance };
  }
}
