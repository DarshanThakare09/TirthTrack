import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/state_widgets.dart';
import 'police_providers.dart';

class PoliceIdViewerScreen extends ConsumerWidget {
  const PoliceIdViewerScreen({
    super.key,
    required this.storagePath,
    required this.officerName,
  });

  final String storagePath;
  final String officerName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(policeRepositoryProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Police ID Document',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              officerName,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<String?>(
        future: repo.getSignedIdCardUrl(storagePath),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(message: 'Generating secure access URL...');
          }

          if (snapshot.hasError || snapshot.data == null) {
            return const ErrorStateWidget(
              title: 'Unable to Load ID Document',
              message:
                  'The uploaded ID document could not be retrieved from private storage.',
            );
          }

          final signedUrl = snapshot.data!;
          final isPdf = storagePath.toLowerCase().endsWith('.pdf');

          if (isPdf) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.picture_as_pdf_rounded,
                      size: 64,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'PDF Document Attached',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      storagePath,
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.8,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: signedUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) =>
                    const LoadingWidget(message: 'Loading image preview...'),
                errorWidget: (context, url, error) => const ErrorStateWidget(
                  title: 'Image Load Error',
                  message: 'Failed to display image file from storage.',
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
