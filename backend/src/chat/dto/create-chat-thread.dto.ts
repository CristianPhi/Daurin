import { IsEmail, IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class CreateChatThreadDto {
  @IsOptional()
  @IsString()
  threadId?: string;

  @IsString()
  @IsNotEmpty()
  sellerId!: string;

  @IsString()
  @IsNotEmpty()
  sellerUsername!: string;

  @IsString()
  @IsNotEmpty()
  sellerName!: string;

  @IsEmail()
  sellerEmail!: string;

  @IsString()
  @IsNotEmpty()
  buyerName!: string;

  @IsEmail()
  buyerEmail!: string;

  @IsOptional()
  @IsString()
  initialMessage?: string;
}
