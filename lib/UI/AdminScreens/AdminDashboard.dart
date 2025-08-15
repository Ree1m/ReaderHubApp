import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reader_hub_app/Modules/CustomSnackBar.dart';
import 'package:reader_hub_app/UI/AdminScreens/AdminAddPlace.dart';
import 'package:reader_hub_app/UI/ProfileScreen.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminDashboard extends StatefulWidget {
  final DocumentSnapshot<Map<String, dynamic>> userData;
  AdminDashboard({super.key, required this.userData});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: const Color(0xff197e62),
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.merriweather(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen(userData: widget.userData)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminAddPlace()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
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
            itemBuilder: (context, index) {
              var place = snapshot.data!.docs[index];
              List<dynamic> imageUrls = place['imageUrls'] ?? [];
              String? phoneNumber = place['phoneNumber'];
              return GestureDetector(
                onTap: () => _showPlaceDetails(context, place),
                onLongPress: () => _showPlaceOptions(context, place),
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
    );
  }

  void _showPlaceOptions(BuildContext context, DocumentSnapshot place) {
    /**
   * تعرض هذه الدالة قائمة خيارات أسفل الشاشة
   * لتعديل أو حذف المكان المحدد.
   */

    // Show bottom sheet with options
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit Place'),
                onTap: () {
                  // Close the bottom sheet and navigate to the edit screen
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AdminAddPlace(place: place)),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.delete),
                title: Text('Delete Place'),
                onTap: () {
                  // Close the bottom sheet and call delete function
                  Navigator.pop(context);
                  _deletePlace(place);
                },
              ),
            ],
          ),
    );
  }

  Future<void> _deletePlace(DocumentSnapshot place) async {
    /**
   * تقوم هذه الدالة بعرض تأكيد للمستخدم لحذف المكان،
   * ثم تحذف المكان من قاعدة البيانات إذا تم التأكيد.
   */

    // Ask the user for confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete Place'),
            content: Text('Are you sure you want to delete ${place['name']}?'),
            actions: [
              // Cancel button
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
              // Confirm delete button
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    // If confirmed, delete the place
    if (confirmed ?? false) {
      try {
        await FirebaseFirestore.instance.collection('Places').doc(place.id).delete();
        showCustomSnackBar(context, 'Place deleted successfully', Colors.green, 2);
      } catch (e) {
        // Handle any errors during deletion
        showCustomSnackBar(context, 'Error deleting place', Colors.red, 2);
      }
    }
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
}
