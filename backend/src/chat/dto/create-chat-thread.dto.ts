import { IsEmail, IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class CreateChatThreadDto {
  @IsString()
  @IsNotEmpty()
  itemId!: string;

  @IsOptional()
  @IsString()
  itemName?: string;

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
  threadId?: string;

  @IsOptional()
  @IsString()
  initialMessage?: string;
}
