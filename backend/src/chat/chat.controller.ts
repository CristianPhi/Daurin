import { Body, Controller, Get, Param, Post, Query } from '@nestjs/common';
import { ChatService } from './chat.service';
import { CreateChatThreadDto } from './dto/create-chat-thread.dto';
import { SendChatMessageDto } from './dto/send-chat-message.dto';

@Controller('chat')
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @Post('threads')
  createOrUpdateThread(@Body() dto: CreateChatThreadDto) {
    return this.chatService.upsertThread(dto);
  }

  @Get('threads')
  findThreads(@Query('userEmail') userEmail?: string) {
    return this.chatService.findThreadsForUser(userEmail ?? '');
  }

  @Get('threads/:threadId/messages')
  findMessages(@Param('threadId') threadId: string) {
    return this.chatService.findMessages(threadId);
  }

  @Post('messages')
  sendMessage(@Body() dto: SendChatMessageDto) {
    return this.chatService.sendMessage(dto);
  }
}
