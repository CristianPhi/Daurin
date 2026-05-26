import { IsEmail, IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class SendChatMessageDto {
  @IsOptional()
  @IsString()
  threadId?: string;

  @IsString()
  @IsNotEmpty()
  itemId!: string;

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

  @IsString()
  @IsNotEmpty()
  senderName!: string;

  @IsEmail()
  senderEmail!: string;

  @IsString()
  @IsNotEmpty()
  text!: string;

  @IsOptional()
  @IsString()
  itemName?: string;
}
