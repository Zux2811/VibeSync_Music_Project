import 'package:flutter/material.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/artist_model.dart';
import '../../data/sources/artist_service.dart';

class ArtistVerificationPage extends StatefulWidget {
  const ArtistVerificationPage({super.key});

  @override
  State<ArtistVerificationPage> createState() => _ArtistVerificationPageState();
}

class _ArtistVerificationPageState extends State<ArtistVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _stageNameController = TextEditingController();
  final _realNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _facebookController = TextEditingController();
  final _youtubeController = TextEditingController();
  final _spotifyController = TextEditingController();
  final _instagramController = TextEditingController();
  final _websiteController = TextEditingController();
  final _songLinksController = TextEditingController();

  List<ArtistVerificationRequest> _existingRequests = [];
  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadExistingRequests();
  }

  Future<void> _loadExistingRequests() async {
    setState(() => _isLoading = true);
    try {
      final requests = await ArtistService.getMyVerificationRequests();
      if (mounted) {
        setState(() {
          _existingRequests = requests;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final songLinks =
          _songLinksController.text
              .split('\n')
              .where((s) => s.trim().isNotEmpty)
              .toList();

      final data = {
        'stageName': _stageNameController.text.trim(),
        'realName': _realNameController.text.trim(),
        'bio': _bioController.text.trim(),
        'contactEmail': _contactEmailController.text.trim(),
        'contactPhone': _contactPhoneController.text.trim(),
        'facebookUrl': _facebookController.text.trim(),
        'youtubeUrl': _youtubeController.text.trim(),
        'spotifyUrl': _spotifyController.text.trim(),
        'instagramUrl': _instagramController.text.trim(),
        'websiteUrl': _websiteController.text.trim(),
        'releasedSongLinks': songLinks,
      };

      final success = await ArtistService.submitVerificationRequest(data);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification request submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadExistingRequests();
          _clearForm();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to submit request. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _clearForm() {
    _stageNameController.clear();
    _realNameController.clear();
    _bioController.clear();
    _contactEmailController.clear();
    _contactPhoneController.clear();
    _facebookController.clear();
    _youtubeController.clear();
    _spotifyController.clear();
    _instagramController.clear();
    _websiteController.clear();
    _songLinksController.clear();
  }

  @override
  void dispose() {
    _stageNameController.dispose();
    _realNameController.dispose();
    _bioController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _facebookController.dispose();
    _youtubeController.dispose();
    _spotifyController.dispose();
    _instagramController.dispose();
    _websiteController.dispose();
    _songLinksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Artist Verification')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: EdgeInsets.all(responsive.horizontalPadding),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: responsive.maxContentWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Info banner
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: primaryColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: primaryColor),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Become a verified artist to upload your music, create albums, and reach your fans!',
                                  style: TextStyle(color: primaryColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Existing requests
                        if (_existingRequests.isNotEmpty) ...[
                          Text(
                            'Your Verification Requests',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          ..._existingRequests.map(
                            (r) => _RequestCard(request: r),
                          ),
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 24),
                        ],

                        // Check if can submit new request
                        if (_existingRequests.any((r) => r.isPending))
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.hourglass_empty,
                                  color: Colors.orange,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'You have a pending request. Please wait for admin review.',
                                    style: TextStyle(color: Colors.orange),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else ...[
                          // Application form
                          Text(
                            'Apply for Artist Verification',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Basic info section
                                _SectionTitle(title: 'Basic Information'),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _stageNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Stage Name *',
                                    hintText: 'Your artist/stage name',
                                    prefixIcon: Icon(Icons.person),
                                  ),
                                  validator:
                                      (v) =>
                                          v?.isEmpty == true
                                              ? 'Stage name is required'
                                              : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _realNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Real Name',
                                    hintText:
                                        'Your legal name (for verification)',
                                    prefixIcon: Icon(Icons.badge),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _bioController,
                                  decoration: const InputDecoration(
                                    labelText: 'Bio',
                                    hintText:
                                        'Tell us about yourself and your music',
                                    prefixIcon: Icon(Icons.description),
                                  ),
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 24),

                                // Contact info section
                                _SectionTitle(title: 'Contact Information'),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _contactEmailController,
                                  decoration: const InputDecoration(
                                    labelText: 'Contact Email *',
                                    hintText: 'Email for business inquiries',
                                    prefixIcon: Icon(Icons.email),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    if (v?.isEmpty == true)
                                      return 'Email is required';
                                    if (!v!.contains('@'))
                                      return 'Invalid email';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _contactPhoneController,
                                  decoration: const InputDecoration(
                                    labelText: 'Phone Number',
                                    hintText: 'Your contact number',
                                    prefixIcon: Icon(Icons.phone),
                                  ),
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 24),

                                // Social links section
                                _SectionTitle(
                                  title: 'Social Media & Portfolio',
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _facebookController,
                                  decoration: const InputDecoration(
                                    labelText: 'Facebook',
                                    hintText: 'https://facebook.com/yourpage',
                                    prefixIcon: Icon(Icons.facebook),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _youtubeController,
                                  decoration: const InputDecoration(
                                    labelText: 'YouTube',
                                    hintText:
                                        'https://youtube.com/@yourchannel',
                                    prefixIcon: Icon(Icons.play_circle),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _spotifyController,
                                  decoration: const InputDecoration(
                                    labelText: 'Spotify',
                                    hintText:
                                        'https://open.spotify.com/artist/...',
                                    prefixIcon: Icon(Icons.music_note),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _instagramController,
                                  decoration: const InputDecoration(
                                    labelText: 'Instagram',
                                    hintText:
                                        'https://instagram.com/yourhandle',
                                    prefixIcon: Icon(Icons.camera_alt),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _websiteController,
                                  decoration: const InputDecoration(
                                    labelText: 'Website',
                                    hintText: 'https://yourwebsite.com',
                                    prefixIcon: Icon(Icons.language),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Released songs section
                                _SectionTitle(title: 'Released Music'),
                                const SizedBox(height: 8),
                                Text(
                                  'Provide links to your music on streaming platforms (one per line)',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _songLinksController,
                                  decoration: const InputDecoration(
                                    labelText: 'Song Links',
                                    hintText:
                                        'https://open.spotify.com/track/...\nhttps://music.apple.com/...',
                                    prefixIcon: Icon(Icons.link),
                                  ),
                                  maxLines: 4,
                                ),
                                const SizedBox(height: 32),

                                // Submit button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed:
                                        _isSubmitting ? null : _submitRequest,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child:
                                        _isSubmitting
                                            ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                            : const Text(
                                              'Submit Verification Request',
                                              style: TextStyle(fontSize: 16),
                                            ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Note: Your request will be reviewed by our team. You will receive an email notification once it\'s processed.',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final ArtistVerificationRequest request;

  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (request.status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Approved';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Rejected';
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        statusText = 'Pending';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor),
                const SizedBox(width: 8),
                Text(
                  request.stageName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (request.createdAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Submitted: ${_formatDate(request.createdAt!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (request.isRejected && request.rejectionReason != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reason: ${request.rejectionReason}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
