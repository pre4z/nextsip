import { IsString } from 'class-validator';
// DTO til Login
export class LoginDto {
  @IsString()
  username: string;

  @IsString()
  password: string;
}
