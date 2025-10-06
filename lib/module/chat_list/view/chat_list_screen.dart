import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xori/module/chat_list/controller/chat_list_controller.dart';
import 'package:xori/routes/app_routes.dart';

class ChatListScreen extends StatelessWidget {
  ChatListScreen({super.key});

  final ChatListController controller = Get.put(ChatListController());

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
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                final contacts = controller.filteredContacts;

                if (contacts.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No chats yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start a conversation with someone!',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: contact.profileImageUrl != null
                            ? NetworkImage(contact.profileImageUrl!)
                            : null,
                        child: contact.profileImageUrl == null
                            ? Text(
                                contact.name.isNotEmpty
                                    ? contact.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              )
                            : null,
                      ),
                      title: Text(
                        contact.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Row(
                        children: [
                          if (contact.lastMessage == 'Image')
                            const Icon(
                              Icons.image,
                              size: 16,
                              color: Colors.grey,
                            ),
                          if (contact.lastMessage == 'Image')
                            const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              contact.lastMessage ?? 'No messages yet',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: Text(
                        controller.getTimeAgo(
                          contact.lastMessageTime?.toDate(),
                        ),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                      onTap: () => Get.toNamed(
                        AppRoutes.chat,
                        arguments: {
                          'contactId': contact.id,
                          'name': contact.name,
                          'avatar': contact.profileImageUrl,
                          'isOnline': true,
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
