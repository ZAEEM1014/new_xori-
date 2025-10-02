import 'package:get/get.dart';

class Chat {
  final String name;
  final String message;
  final String time;
  final String? avatar;
  final bool hasUnread;
  final bool isImage;
  final bool isGroup;

  Chat({
    required this.name,
    required this.message,
    required this.time,
    this.avatar,
    this.hasUnread = false,
    this.isImage = false,
    this.isGroup = false,
  });
}

class ChatController extends GetxController {
  var searchQuery = ''.obs;

  var chats = <Chat>[
    Chat(
      name: 'Aliah Lane',
      message: 'Hey! Are we still on for tonight?',
      time: '2 min ago',
      hasUnread: true,
      avatar: 'https://i.pravatar.cc/150?img=3',
    ),
    Chat(
      name: 'John Doe',
      message: 'Image',
      time: '1 hour ago',
      isImage: true,
      avatar: 'https://i.pravatar.cc/150?img=2',
    ),
    Chat(
      name: 'Design Team',
      message: "Ben: Here's the new prototype video.",
      time: 'Yesterday',
      isGroup: true,
      avatar: null,
    ),
    Chat(
      name: 'Aliah Lane',
      message: 'Hey! Are we still on for tonight?',
      time: '2 min ago',
      hasUnread: true,
      avatar: 'https://i.pravatar.cc/150?img=4',
    ),
    Chat(
      name: 'John Doe',
      message: 'Image',
      time: '1 hour ago',
      isImage: true,
      avatar: 'https://i.pravatar.cc/150?img=1',
    ),
    Chat(
      name: 'Aliah Lane',
      message: 'Hey! Are we still on for tonight?',
      time: '2 min ago',
      hasUnread: true,
      avatar: 'https://i.pravatar.cc/150?img=5',
    ),
  ].obs;

  List<Chat> get filteredChats {
    if (searchQuery.isEmpty) return chats;
    return chats
        .where(
          (c) => c.name.toLowerCase().contains(searchQuery.value.toLowerCase()),
        )
        .toList();
  }
}
