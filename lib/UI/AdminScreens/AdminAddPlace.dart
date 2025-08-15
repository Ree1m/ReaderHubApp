import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

import 'package:reader_hub_app/Modules/CustomSnackBar.dart';

class AdminAddPlace extends StatefulWidget {
  final DocumentSnapshot? place;

  const AdminAddPlace({super.key, this.place});

  @override
  State<AdminAddPlace> createState() => _AdminAddPlaceState();
}

class _AdminAddPlaceState extends State<AdminAddPlace> {
  final _formKey = GlobalKey<FormState>();
  final List<String> _hours = List.generate(
    24,
    (index) => '${index.toString().padLeft(2, '0')}:00',
  );
  final ImagePicker _picker = ImagePicker();
  List<File> _images = [];
  List<String> _imageUrls = [];

  // Form fields
  String _name = '';
  String _address = '';
  String _mapLink = '';
  String _phoneNumber = '';
  String? _openingHour;
  String? _closingHour;
  Map<String, bool> _features = {
    'Cold drinks': false,
    'Hot drinks': false,
    'Power outlets': false,
    'WiFi': false,
    'Private desk': false,
    'Free library': false,
    'Cozy music': false,
    'Free place': false,
  };
  int _selectedRating = 5;
  String? _placeId;

  @override
  void initState() {
    super.initState();
    if (widget.place != null) {
      _initializeForm();
    }
  }

  void _initializeForm() {
    /** 
   * تقوم هذه الدالة بتهيئة نموذج المكان باستخدام البيانات الموجودة.
   * يتم تحميل بيانات الاسم، العنوان، الرابط، الهاتف، ساعات العمل، الميزات والتقييم.
   */

    final place = widget.place!;
    _placeId = place.id;
    _imageUrls = List<String>.from(place['imageUrls'] ?? []);
    _name = place['name'];
    _address = place['address'];
    _mapLink = place['mapLink'];
    _phoneNumber = place['phoneNumber'] ?? '';

    // Parse opening hours into opening and closing times
    final hours = place['openingHours'].split(' - ');
    _openingHour = hours[0];
    _closingHour = hours[1];

    // Load features (like available amenities)
    _features = Map<String, bool>.from(place['features']);

    // Load the rating and round it down
    _selectedRating = place['rating'].floor();
  }

  Future<void> _pickImages() async {
    /** 
   * تقوم هذه الدالة بفتح مستعرض الصور للسماح للمستخدم باختيار عدة صور وتحميلها إلى التطبيق.
   */

    final List<XFile> pickedImages = await _picker.pickMultiImage();
    if (pickedImages.isNotEmpty) {
      setState(() {
        _images.addAll(pickedImages.map((xFile) => File(xFile.path)));
      });
    }
  }

  Future<List<String>> _uploadImages() async {
    /** 
   * تقوم هذه الدالة برفع الصور المختارة إلى Firebase Storage
   * وتعيد قائمة بروابط الصور بعد رفعها.
   */

    List<String> urls = [];

    for (var image in _images) {
      // Generate a unique file name
      String fileName = DateTime.now().millisecondsSinceEpoch.toString() + '_${image.hashCode}';

      // Create a reference to Firebase Storage
      Reference storageRef = FirebaseStorage.instance.ref().child('places/$fileName');

      // Upload the file
      UploadTask uploadTask = storageRef.putFile(image);

      // Wait for upload to complete and get download URL
      TaskSnapshot snapshot = await uploadTask;
      String url = await snapshot.ref.getDownloadURL();

      urls.add(url);
    }

    return urls;
  }

  Future<void> _submitForm() async {
    /** 
   * تقوم هذه الدالة بالتحقق من صحة النموذج ثم تقوم إما بإضافة مكان جديد
   * أو تحديث مكان موجود في قاعدة بيانات Firestore، مع تحميل الصور المرتبطة إذا وُجدت.
   */

    // Validate the form inputs
    if (!_formKey.currentState!.validate()) return;

    // Show a loading snackbar
    final loadingSnackBar = SnackBar(
      backgroundColor: Color(0xff197e62),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(width: 20),
          Text(
            '${_placeId == null ? 'Adding' : 'Updating'} Place ...',
            style: GoogleFonts.merriweather(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
      duration: Duration(seconds: 30),
    );
    ScaffoldMessenger.of(context).showSnackBar(loadingSnackBar);

    // Upload new images and combine with existing ones
    List<String> newImageUrls = await _uploadImages();
    List<String> allImageUrls = [..._imageUrls, ...newImageUrls];

    // Prepare the data to be sent to Firestore
    final placeData = {
      'name': _name,
      'address': _address,
      'mapLink': _mapLink,
      'phoneNumber': _phoneNumber,
      'openingHours': '${_openingHour} - ${_closingHour}',
      'features': _features,
      'rating': _selectedRating.toDouble(),
      'imageUrls': allImageUrls,
      'createdAt': DateTime.now(),
    };

    if (_placeId == null) {
      // Add a new place
      await FirebaseFirestore.instance.collection('Places').add(placeData);
    } else {
      // Update an existing place
      await FirebaseFirestore.instance.collection('Places').doc(_placeId).update(placeData);
    }

    if (mounted) {
      // Hide the loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Show success message
      showCustomSnackBar(
        context,
        _placeId == null ? 'Place Added Successfully' : 'Place Updated Successfully',
        Colors.green,
        3,
      );

      // Go back to previous screen
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        centerTitle: false,
        backgroundColor: const Color(0xff197e62),
        title: Text(
          widget.place == null ? 'Add Place' : 'Edit Place',
          style: GoogleFonts.merriweather(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Image Picker
            GestureDetector(
              onTap: _pickImages,
              child: Card(
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
                  child:
                      _images.isEmpty && _imageUrls.isEmpty
                          ? Center(child: Text('Tap to add place photos'))
                          : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _images.length + _imageUrls.length,
                            itemBuilder: (context, index) {
                              if (index < _imageUrls.length) {
                                return Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Image.network(
                                    _imageUrls[index],
                                    width: 200,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  ),
                                );
                              } else {
                                int fileIndex = index - _imageUrls.length;
                                return Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Image.file(
                                    _images[fileIndex],
                                    width: 200,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  ),
                                );
                              }
                            },
                          ),
                ),
              ),
            ),
            SizedBox(height: 20),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Place Name',
                prefixIcon: Icon(Icons.place),
              ),
              initialValue: _name,
              validator: (value) => value!.isEmpty ? 'Required' : null,
              onChanged: (value) => _name = value,
            ),
            SizedBox(height: 15),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Address',
                prefixIcon: Icon(Icons.location_on),
              ),
              initialValue: _address,
              validator: (value) => value!.isEmpty ? 'Required' : null,
              onChanged: (value) => _address = value,
            ),
            SizedBox(height: 15),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
              ),
              initialValue: _phoneNumber,
              validator: (value) => value!.isEmpty ? 'Required' : null,
              onChanged: (value) => _phoneNumber = value,
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 15),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Google Map Link',
                prefixIcon: Icon(Icons.link),
              ),
              initialValue: _mapLink,
              validator: (value) => value!.isEmpty ? 'Required' : null,
              onChanged: (value) => _mapLink = value,
            ),
            SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Opening Time'),
                    value: _openingHour,
                    items:
                        _hours
                            .map((hour) => DropdownMenuItem(value: hour, child: Text(hour)))
                            .toList(),
                    onChanged: (value) => setState(() => _openingHour = value),
                    validator: (value) => value == null ? 'Required' : null,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Closing Time'),
                    value: _closingHour,
                    items:
                        _hours
                            .map((hour) => DropdownMenuItem(value: hour, child: Text(hour)))
                            .toList(),
                    onChanged: (value) => setState(() => _closingHour = value),
                    validator: (value) => value == null ? 'Required' : null,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text('Features:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ..._features.keys
                .map(
                  (feature) => CheckboxListTile(
                    title: Text(feature),
                    value: _features[feature],
                    onChanged: (value) => setState(() => _features[feature] = value!),
                  ),
                )
                .toList(),
            SizedBox(height: 20),
            Text('Rating:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRating = index + 1;
                    });
                  },
                  child: Icon(
                    Icons.star,
                    color: index < _selectedRating ? Colors.amber : Colors.grey,
                    size: 30,
                  ),
                );
              }),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff197e62),
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _submitForm,
              child: Text('Add Place', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
