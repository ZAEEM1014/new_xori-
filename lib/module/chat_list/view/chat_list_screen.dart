import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xori/module/chat_list/controller/chat_list_controller.dart';
import 'package:xori/routes/app_routes.dart';
import 'package:xori/routes/app_routes.dart';

class ChatListScreen extends StatelessWidget {
  ChatListScreen({super.key});

  final ChatController controller = Get.put(ChatController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 🔍 Search bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onChanged: (val) => controller.searchQuery.value = val,
                decoration: InputDecoration(
                  hintText: 'Search message or chat',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            // 💬 Chat list
            Expanded(
              child: Obx(() {
                final chats = controller.filteredChats;
                return ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: chat.isGroup
                            ? Colors.purple.shade100
                            : Colors.grey.shade200,
                        backgroundImage: chat.avatar != null
                            ? NetworkImage(chat.avatar!)
                            : null,
                        child: chat.isGroup && chat.avatar == null
                            ? const Icon(Icons.group, color: Colors.purple)
                            : null,
                      ),
                      title: Text(
                        chat.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Row(
                        children: [
                          if (chat.isImage)
                            const Icon(
                              Icons.image,
                              size: 16,
                              color: Colors.grey,
                            ),
                          if (chat.isImage) const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              chat.message,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            chat.time,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 11,
                            ),
                          ),
                          if (chat.hasUnread)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              height: 18,
                              width: 18,
                              decoration: const BoxDecoration(
                                color: Colors.amber,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text(
                                  '2',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      onTap: () => Get.toNamed(
                        AppRoutes.chat,
                        arguments: {
                          'name': chat.name,
                          'avatar': chat.avatar,
                          'isOnline':
                              true, // You can modify this based on your data model
                        },
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
