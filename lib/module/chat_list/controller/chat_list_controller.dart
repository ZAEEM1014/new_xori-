import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/contact_model.dart';
import '../../../services/message_service.dart';

class ChatController extends GetxController {
  final MessageService _messageService = MessageService();
  
  var searchQuery = ''.obs;
  var isLoading = false.obs;
  var contacts = <ContactModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadChatList();
  }

  void loadChatList() {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      isLoading.value = true;
      
      // Listen to real-time chat list updates
      _messageService.getChatListStream(currentUser.uid).listen(
        (contactList) {
          try {
            contacts.value = contactList;
            isLoading.value = false;
          } catch (e) {
            print('[DEBUG] ChatController: Error updating contacts: $e');
            isLoading.value = false;
          }
        },
        onError: (error) {
          print('[DEBUG] ChatController: Error in chat list stream: $error');
          isLoading.value = false;
        },
      );
    } catch (e) {
      print('[DEBUG] ChatController: Error loading chat list: $e');
      isLoading.value = false;
    }
  }

  List<ContactModel> get filteredContacts {
    try {
      if (searchQuery.isEmpty) return contacts;
      return contacts
          .where((contact) => 
              contact.name.toLowerCase().contains(searchQuery.value.toLowerCase()))
          .toList();
    } catch (e) {
      print('[DEBUG] ChatController: Error filtering contacts: $e');
      return [];
    }
  }

  String getTimeAgo(DateTime? dateTime) {
    try {
      if (dateTime == null) return '';
      
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      print('[DEBUG] ChatController: Error formatting time: $e');
      return '';
    }
  }
}
