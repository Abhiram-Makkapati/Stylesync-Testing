import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // for image_picker --> camera or gallery

// widget that allows user to import a photo from their device
class PhotoImport extends StatefulWidget {
  // callback function that sends selected image (as file) back to parent widget
  final Function(File) onImageSelected;
  
  // constructor requres callback function
  const PhotoImport({Key? key, required this.onImageSelected})
    : super(key: key);

  @override
  _PhotoImportState createState() => _PhotoImportState();
}

// state class to handle image picking and UI updates
class _PhotoImportState extends State<PhotoImport> {
  File? _image; // stores selected image file (nullable until chosen)

  // pick image from the requested source (gallery or camera)
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      // if user picked an image
      File imageFile = File(pickedFile.path); // convert XFile to File
      setState(() => _image = imageFile); // update local state so UI shows image
      widget.onImageSelected(imageFile);
      // send image file back to parent widget though callback
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // sho selected image if available, otherwise show text
        _image != null
            ? Image.file(_image!, height: 150) // display chosen image
            : const Text("No image selected"), // placeholder if no image chosen
        // buttons to trigger gallery or camera picker
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _pickImage(ImageSource.gallery),
              child: const Text("Import from Gallery"),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _pickImage(ImageSource.camera),
              child: const Text("Take Photo"),
            ),
          ],
        ),
      ],
    );
  }
}