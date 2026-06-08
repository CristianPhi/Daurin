import { IsEmail, IsNotEmpty, IsString } from 'class-validator';
import { CreateChatThreadDto } from './create-chat-thread.dto';

export class SendChatMessageDto extends CreateChatThreadDto {
  @IsEmail()
  senderEmail!: string;

  @IsString()
  @IsNotEmpty()
  senderName!: string;

  @IsString()
  @IsNotEmpty()
  text!: string;
}
