import {
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';

@WebSocketGateway({
  cors: {
    origin: '*', // Cho phép mọi nguồn kết nối (tuỳ chỉnh theo môi trường)
  },
})
export class WebsocketGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer() server: Server;
  private chatHistory: Record<string, { senderId: string; message: string }[]> = {};

  handleConnection(client: Socket) {
    console.log(`Client connected: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    console.log(`Client disconnected: ${client.id}`);
  }

  @SubscribeMessage('private-message')
  handleMessage(client: Socket, payload: { receiverId: string; message: string }): void {
    const { receiverId, message } = payload;

    // Lưu lịch sử tin nhắn
    const chatKey = this.getChatKey(client.id, receiverId);
    if (!this.chatHistory[chatKey]) {
      this.chatHistory[chatKey] = [];
    }
    this.chatHistory[chatKey].push({ senderId: client.id, message });

    // Gửi tin nhắn đến người nhận
    this.server.to(receiverId).emit('private-message', { senderId: client.id, message });

    // Gửi tin nhắn đến người gửi để xác nhận
    client.emit('private-message', { senderId: client.id, message });
  }

  @SubscribeMessage('get-chat-history')
  handleChatHistory(client: Socket, receiverId: string): void {
    const chatKey = this.getChatKey(client.id, receiverId);
    const history = this.chatHistory[chatKey] || [];
    client.emit('chat-history', history);
  }

  private getChatKey(client1: string, client2: string): string {
    // Sắp xếp ID để tạo key duy nhất cho từng cặp client
    return [client1, client2].sort().join('-');
  }
}