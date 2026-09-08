import 'package:flutter/material.dart';
import 'package:prokat/features/chat/widgets/chat_list_view.dart';

class ClientChatListScreen extends StatelessWidget {
  const ClientChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ChatListView(isOwner: false);
  }
}
