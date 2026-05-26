import { IsEmail, IsOptional, IsString } from 'class-validator';

export class GoogleLoginDto {
  @IsEmail()
  email!: string;

  @IsOptional()
  @IsString()
  displayName?: string;

  @IsOptional()
  @IsString()
  idToken?: string;
}
