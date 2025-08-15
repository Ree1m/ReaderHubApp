import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:reader_hub_app/Modules/CustomSnackBar.dart';
import 'package:reader_hub_app/UI/ProfileScreen.dart';
import 'package:url_launcher/url_launcher.dart';

class Dashboard extends StatefulWidget {
  final DocumentSnapshot<Map<String, dynamic>> userData;
  const Dashboard({super.key, required this.userData});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xfffef7ff),
        foregroundColor: Color(0xff197e62),
        title: Text(
          'Welcome ${widget.userData.data()!['firstName']}!',
          style: GoogleFonts.merriweather(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Color(0xff197e62), size: 30),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen(userData: widget.userData)),
              );
            },
          ),
        ],
      ),
      body: ListView(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          Divider(color: Color(0xff197e62).withOpacity(0.1), thickness: 1),
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 15),
            child: Text(
              '🔥 Places',
              style: GoogleFonts.merriweather(
                fontSize: 23,
                color: Color(0xff197e62),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('Places')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              return ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: snapshot.data!.docs.length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  var place = snapshot.data!.docs[index];
                  List<dynamic> imageUrls = place['imageUrls'] ?? [];
                  String? phoneNumber = place['phoneNumber'];
                  return GestureDetector(
                    onTap: () => _showPlaceDetails(context, place),
                    child: Card(
                      elevation: 7,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
                        child: Stack(
                          children: [
                            // Image slider
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: PageView.builder(
                                itemCount: imageUrls.length,
                                itemBuilder: (context, imageIndex) {
                                  return Image.network(
                                    imageUrls[imageIndex],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  );
                                },
                              ),
                            ),
                            // Overlay with name, rating, and phone number
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Place name and rating
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          place['name'],
                                          style: GoogleFonts.merriweather(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Row(
                                          children: List.generate(
                                            5,
                                            (starIndex) => Icon(
                                              Icons.star,
                                              color:
                                                  starIndex < (place['rating'] ?? 0).floor()
                                                      ? Colors.amber
                                                      : Colors.grey,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Phone number (if exists)
                                    if (phoneNumber != null && phoneNumber.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          phoneNumber,
                                          style: TextStyle(color: Colors.white70, fontSize: 14),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _showPlaceDetails(BuildContext context, DocumentSnapshot place) {
    final List<dynamic> imageUrls = place['imageUrls'] ?? [];
    final String? phoneNumber = place['phoneNumber'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.9,
            builder:
                (_, controller) => SingleChildScrollView(
                  controller: controller,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 200,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: PageView.builder(
                              itemCount: imageUrls.length,
                              itemBuilder: (context, idx) {
                                return Image.network(
                                  imageUrls[idx],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          place['name'],
                          style: GoogleFonts.merriweather(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (phoneNumber != null && phoneNumber.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.phone, size: 20, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                phoneNumber,
                                style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 10),
                        _buildDetailRow(Icons.location_on, place['address']),
                        const SizedBox(height: 10),
                        Text(
                          'Map:',
                          style: GoogleFonts.merriweather(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => _launchUrl(place['mapLink']),
                          child: Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: NetworkImage(
                                  'https://www.gps-coordinates.net/images/gps-og-image.jpg',
                                ),
                                fit: BoxFit.fitWidth,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildDetailRow(Icons.access_time, place['openingHours']),
                        const SizedBox(height: 15),
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              Icons.star,
                              color:
                                  i < (place['rating'] ?? 0).floor() ? Colors.amber : Colors.grey,
                              size: 30,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Features:',
                          style: GoogleFonts.merriweather(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          children:
                              (place['features'] as Map<String, dynamic>).entries
                                  .map(
                                    (entry) => Chip(
                                      backgroundColor:
                                          entry.value ? Colors.green[100] : Colors.red[100],
                                      label: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            entry.value ? Icons.check : Icons.close,
                                            color: entry.value ? Colors.green : Colors.red,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(entry.key),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff197e62),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: () => _showReviewDialog(context, place.id),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Write your review',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Reviews:',
                          style: GoogleFonts.merriweather(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        StreamBuilder<QuerySnapshot>(
                          stream:
                              FirebaseFirestore.instance
                                  .collection('Reviews')
                                  .where('placeID', isEqualTo: place.id)
                                  .orderBy('timestamp', descending: true)
                                  .snapshots(),
                          builder: (context, reviewSnapshot) {
                            if (reviewSnapshot.hasError) return const Text('Error loading reviews');
                            if (reviewSnapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            return Column(
                              children:
                                  reviewSnapshot.data!.docs.map((reviewDoc) {
                                    final review = reviewDoc.data() as Map<String, dynamic>;
                                    return _buildReviewCard(review);
                                  }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text, {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xff197e62)),
          const SizedBox(width: 10),
          Expanded(
            child:
                isLink
                    ? InkWell(
                      onTap: () => _launchUrl(text),
                      child: Text(
                        text,
                        style: const TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    )
                    : Text(text),
          ),
        ],
      ),
    );
  }

  // Add this new method for URL launching
  Future<void> _launchUrl(String url) async {
    final Uri parsedUrl = Uri.parse(url);
    if (!await launchUrl(parsedUrl)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not launch $url')));
    }
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              review['userName'].toString(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 5),
            Row(
              children: List.generate(
                5,
                (index) => Icon(
                  Icons.star,
                  color: index < (review['rating'] as num).floor() ? Colors.amber : Colors.grey,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(review['comment']),
            const SizedBox(height: 8),
            Text(
              _formatTimestamp(review['timestamp'] ?? Timestamp.now()).toString(),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    return DateFormat('MMM dd, yyyy  HH:mm').format(timestamp.toDate());
  }

  void _showReviewDialog(BuildContext context, String placeId) {
    int selectedRating = 0;
    TextEditingController commentController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Center(
                child: Text(
                  'Your Review',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Rate this place'),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedRating = index + 1;
                            });
                          },
                          child: Icon(
                            Icons.star,
                            color: index < selectedRating ? Colors.amber : Colors.grey,
                            size: 40,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: commentController,
                      decoration: const InputDecoration(
                        labelText: 'Your comment',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a comment';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff197e62)),
                  onPressed: () async {
                    if (selectedRating == 0 || commentController.text.isEmpty) {
                      if (mounted) {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      }
                      showCustomSnackBar(
                        context,
                        'Please select a rating and write a comment',
                        Colors.red,
                        3,
                      );
                      return;
                    }
                    await FirebaseFirestore.instance
                        .collection('Reviews')
                        .where('userID', isEqualTo: widget.userData.id)
                        .where('placeID', isEqualTo: placeId)
                        .get()
                        .then((lastReview) async {
                          if (lastReview.docs.isNotEmpty) {
                            if (mounted) {
                              Navigator.pop(context);
                              Navigator.pop(context);
                            }
                            showCustomSnackBar(
                              context,
                              'You have already reviewed this place',
                              Colors.red,
                              3,
                            );
                            return;
                          } else {
                            try {
                              await FirebaseFirestore.instance.collection('Reviews').add({
                                'placeID': placeId,
                                'userID': widget.userData.id,
                                'userName':
                                    '${widget.userData['firstName']} ${widget.userData['lastName']}',
                                'rating': selectedRating,
                                'comment': commentController.text,
                                'timestamp': FieldValue.serverTimestamp(),
                              });
                              await _updatePlaceRating(placeId);

                              if (mounted) {
                                Navigator.pop(context);
                                Navigator.pop(context);
                                showCustomSnackBar(
                                  context,
                                  'Review submitted successfully!',
                                  Colors.green,
                                  3,
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                Navigator.pop(context);
                                Navigator.pop(context);
                                showCustomSnackBar(
                                  context,
                                  'Error submitting review: ${e.toString()}',
                                  Colors.red,
                                  3,
                                );
                              }
                            }
                          }
                        });
                  },
                  child: const Text('Submit', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updatePlaceRating(String placeId) async {
    /**
   * تقوم هذه الدالة بحساب متوسط تقييمات المكان 
   * وتحديث القيمة الجديدة في قاعدة بيانات الأماكن.
   */

    // Fetch all reviews for the given place
    final reviewsSnapshot =
        await FirebaseFirestore.instance
            .collection('Reviews')
            .where('placeID', isEqualTo: placeId)
            .get();

    // If no reviews found, exit the function
    if (reviewsSnapshot.docs.isEmpty) return;

    // Calculate the total rating
    double totalRating = 0;
    for (var doc in reviewsSnapshot.docs) {
      totalRating += (doc['rating'] as num).toDouble();
    }

    // Calculate average rating
    final averageRating = totalRating / reviewsSnapshot.docs.length;

    // Update the place document with the new average rating
    await FirebaseFirestore.instance.collection('Places').doc(placeId).update({
      'rating': averageRating,
    });
  }
}
