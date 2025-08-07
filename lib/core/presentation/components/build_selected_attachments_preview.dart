import 'dart:io';
import 'package:flutter/material.dart';
import 'package:oboa_chat_app/domain/model/selected_attachment.dart';
import 'package:oboa_chat_app/presentation/chat/chat_action.dart';

class SelectedAttachmentsPreview extends StatelessWidget {
  final List<SelectedAttachment> attachments;
  final Function(ChatAction) onAction;

  const SelectedAttachmentsPreview({
    super.key,
    required this.attachments,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      color: Colors.grey[100],
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: attachments.length,
        itemBuilder: (context, index) {
          final attachment = attachments[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[300],
                  ),
                  child: attachment.type == 'image' && attachment.previewUrl != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(File(attachment.previewUrl!), fit: BoxFit.cover),
                  )
                      : Icon(
                    attachment.type == 'video' ? Icons.video_library : Icons.insert_drive_file,
                    size: 40,
                    color: Colors.grey[600],
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => onAction(ChatAction.removeSelectedAttachment(attachment.id)),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}