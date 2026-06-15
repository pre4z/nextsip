import { IsNumber, IsString, Min } from 'class-validator';

export class AddTransactionDto {
  @IsString()
  item: string;

  @IsNumber()
  @Min(0)
  price: number;
}
