import { Injectable } from '@nestjs/common';
import { RedisService } from '../redis/redis.service';

export interface CardBalance {
  uid: string;
  balance: number;
}

export interface Transaction {
  uid: string;
  item: string;
  price: number;
  timestamp: string;
}

/**
 * redis: ( spaendende haha)
 * - "cards"            -> Set med kort ids
 * - "card:<uid>"        -> Hash { balance: number }
 * - "transactions"      -> Liste over alle udgivelser
 *                          
 */
@Injectable()
export class CardsService {
  constructor(private readonly redis: RedisService) {}

  private cardKey(uid: string): string {
    return `card:${uid}`;
  }

  async getBalance(uid: string): Promise<number> {
    const balance = await this.redis.hget(this.cardKey(uid), 'balance');
    return balance ? parseInt(balance, 10) : 0;
  }

  /**
   * sikrer at kortet eksisterer
   */
  async ensureCard(uid: string): Promise<number> {
    const isKnown = await this.redis.sismember('cards', uid);
    if (!isKnown) {
      await this.redis.sadd('cards', uid);
      await this.redis.hset(this.cardKey(uid), 'balance', '0');
      return 0;
    }
    return this.getBalance(uid);
  }

  /**
   * Vi tager saldo og tilfoejer det som lige blev koebt
   */
  async addTransaction(uid: string, item: string, price: number): Promise<number> {
    await this.ensureCard(uid);

    const newBalance = await this.redis.hincrby(this.cardKey(uid), 'balance', price);

    const transaction: Transaction = {
      uid,
      item,
      price,
      timestamp: new Date().toISOString(),
    };
    await this.redis.lpush('transactions', JSON.stringify(transaction));

    return newBalance;
  }

  /**
   * betaling poc
   */
  async payBalance(uid: string): Promise<number> {
    await this.ensureCard(uid);
    await this.redis.hset(this.cardKey(uid), 'balance', '0');
    return 0;
  }

  /**
   * Set saldo manuelt
   */
  async setBalance(uid: string, balance: number): Promise<number> {
    await this.ensureCard(uid);
    await this.redis.hset(this.cardKey(uid), 'balance', balance.toString());
    return balance;
  }

  async getAllCards(): Promise<CardBalance[]> {
    const uids = await this.redis.smembers('cards');
    const cards: CardBalance[] = [];
    for (const uid of uids) {
      cards.push({ uid, balance: await this.getBalance(uid) });
    }
    return cards;
  }

  async getAllTransactions(limit = 200): Promise<Transaction[]> {
    const raw = await this.redis.lrange('transactions', 0, limit - 1);
    return raw.map((entry) => JSON.parse(entry) as Transaction);
  }
}
