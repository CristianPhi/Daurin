import {
  ConnectedSocket,
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { ChatService } from './chat.service';
import { CreateChatThreadDto } from './dto/create-chat-thread.dto';
import { SendChatMessageDto } from './dto/send-chat-message.dto';

@WebSocketGateway({ cors: { origin: true } })
export class ChatGateway {
  @WebSocketServer()
  server!: Server;

  constructor(private readonly chatService: ChatService) {}

  @SubscribeMessage('join_thread')
  async joinThread(
    @MessageBody() dto: CreateChatThreadDto,
    @ConnectedSocket() client: Socket,
  ) {
    const thread = await this.chatService.upsertThread(dto);
    const messages = await this.chatService.findMessages(thread.threadId);

    client.join(thread.threadId);
    client.emit('thread_snapshot', {
      thread,
      messages,
    });

    return { threadId: thread.threadId };
  }

  @SubscribeMessage('send_message')
  async sendMessage(@MessageBody() dto: SendChatMessageDto) {
    const result = await this.chatService.sendMessage(dto);

    this.server.to(result.thread.threadId).emit('message_received', {
      thread: result.thread,
      message: result.message,
    });

    return result;
  }
}
